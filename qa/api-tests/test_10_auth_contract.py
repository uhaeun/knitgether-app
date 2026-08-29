"""API-02, 03, 04, 08. 인증과 입력 계약의 서버 거부.

07 3절 대조에서 미커버로 남았던 12건 중 비용이 낮은 네 건이다. 요청을 보내고
거부 코드를 확인하면 끝나는 계약 검증이라 재현 조건을 따로 만들 필요가 없다.

계정은 conftest의 목록에 등록해 세션 종료 시 함께 정리되게 한다. 직접
requests로 만들면 추적에서 빠져 수동 QA 데이터 사이에 쓰레기 계정이 남는다.
"""
import requests

from conftest import API_BASE_URL, PASSWORD, _new_email, _registered_emails
from helpers import project_payload


def _register_raw(email, password=PASSWORD):
    """등록 요청을 그대로 보낸다. 성공하면 정리 목록에 넣는다."""
    r = requests.post(
        f"{API_BASE_URL}/auth/register",
        json={"email": email, "password": password,
              "displayName": "pytest", "preferredUnits": "cm"},
        timeout=15)
    if r.status_code in (200, 201):
        _registered_emails.append(email)
    return r


# ---------------------------------------------------------------- API-02

def test_api_02_password_length_boundaries():
    """비밀번호 길이 규칙을 서버가 거부하는가. 경계 양쪽을 다 본다.

    규칙은 DTO 데코레이터가 전부다(`auth-register.dto.ts:16-17` MinLength(8),
    MaxLength(256)). 복잡도 규칙은 없으므로 길이만 본다. 통과하는 쪽을 함께
    확인해야 거부가 길이 때문인지 다른 이유인지 갈린다.
    """
    assert _register_raw(_new_email(), "a" * 7).status_code == 400, "7자가 통과했다"
    assert _register_raw(_new_email(), "a" * 257).status_code == 400, "257자가 통과했다"

    ok_min = _register_raw(_new_email(), "a" * 8)
    assert ok_min.status_code in (200, 201), f"경계 안쪽 8자가 거부됐다: {ok_min.text}"
    ok_max = _register_raw(_new_email(), "a" * 256)
    assert ok_max.status_code in (200, 201), f"경계 안쪽 256자가 거부됐다: {ok_max.text}"


# ---------------------------------------------------------------- API-03

def test_api_03_duplicate_email_rejected():
    """같은 이메일로 두 번 가입하면 거부하는가.

    거부 코드가 400이 아니라 409여야 한다. 클라이언트가 형식 오류와 중복을
    구분해 안내해야 하기 때문이다.
    """
    email = _new_email()
    assert _register_raw(email).status_code in (200, 201)

    again = _register_raw(email)
    assert again.status_code == 409, (
        f"중복 이메일이 {again.status_code}로 처리됐다. 409여야 형식 오류와 구분된다"
    )
    assert "EMAIL_ALREADY_REGISTERED" in again.text, again.text


# ---------------------------------------------------------------- API-04

def test_api_04_login_success_and_credential_rejection():
    """올바른 자격은 통과하고 틀린 자격은 거부되는가.

    거부 사유가 비밀번호 오류인지 없는 계정인지 응답으로 구분되면 계정 존재
    여부가 새어 나간다. 두 경우가 같은 코드로 돌아오는지 함께 본다.
    """
    email = _new_email()
    assert _register_raw(email).status_code in (200, 201)

    def login(mail, pw):
        return requests.post(f"{API_BASE_URL}/auth/login",
                             json={"email": mail, "password": pw}, timeout=15)

    ok = login(email, PASSWORD)
    assert ok.status_code == 200, ok.text
    assert ok.json().get("accessToken"), "로그인 성공인데 토큰이 없다"

    wrong_pw = login(email, "wrong-password-1234")
    unknown = login(_new_email(), PASSWORD)
    assert wrong_pw.status_code == 401, wrong_pw.text
    assert unknown.status_code == 401, unknown.text
    assert wrong_pw.status_code == unknown.status_code, (
        "비밀번호 오류와 없는 계정의 응답 코드가 다르다. 계정 존재 여부가 새어 나간다"
    )


# ---------------------------------------------------------------- API-08

def test_api_08_unknown_field_is_rejected(account_a):
    """DTO에 없는 필드를 보내면 거부하는가.

    전역 ValidationPipe가 whitelist + forbidNonWhitelisted다. 이 방어가 풀리면
    오타 난 필드가 조용히 무시되어, 클라이언트는 저장했다고 믿고 서버에는
    안 들어간 상태가 된다.
    """
    payload = project_payload(name="API08-미지필드")
    payload["totallyUnknownField"] = "무시되면 안 된다"

    r = account_a.api.create_project(payload)
    assert r.status_code == 400, (
        f"미지 필드가 {r.status_code}로 통과했다. 오타 난 필드가 조용히 버려진다"
    )


def test_api_08_type_error_is_rejected(account_a):
    """타입이 틀린 값을 거부하는가. API-09의 타입 축을 함께 채운다."""
    payload = project_payload(name="API08-타입오류")
    payload["isFavorite"] = "yes"          # 불리언 자리에 문자열

    r = account_a.api.create_project(payload)
    assert r.status_code == 400, f"타입 오류가 {r.status_code}로 통과했다"
