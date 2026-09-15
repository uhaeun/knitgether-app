"""API-29. 로그인 시도 제한 (SPEC AUTH-08, OBS-4-01 승격분).

security_review B-3이 지적한 공백이다. /auth/login에 rate limit도 계정 잠금도 지연도
없어서 무제한 비밀번호 추측이 가능했다. 서버를 배포한 적이 없어 1차 사이클에서는 명세
공백으로 두고 관찰에만 기록했으나, 15의 릴리즈 판정에서 이것만이 배포를 막는 항목으로
남아 AUTH-08로 승격하고 구현했다.

정책은 연속 실패 5회, 잠금 15분이다. 사용자가 비밀번호를 잘못 기억해 몇 번 틀리는 것은
막지 않으면서 자동 대입의 속도를 떨어뜨리는 선으로 잡았다. 잠금이 풀리면 다시 5회를
쓸 수 있으므로 시간당 20회가 상한이 된다.
기법: 계약 검증
"""
import requests

from conftest import API_BASE_URL, PASSWORD


MAX_ATTEMPTS = 5


def _register(email: str) -> None:
    res = requests.post(
        f"{API_BASE_URL}/auth/register",
        json={
            "email": email,
            "password": PASSWORD,
            "displayName": "API29",
            "preferredUnits": "cm",
        },
        timeout=15,
    )
    assert res.status_code == 201, res.text


def _login(email: str, password: str):
    return requests.post(
        f"{API_BASE_URL}/auth/login",
        json={"email": email, "password": password},
        timeout=15,
    )


def test_api_29_account_locks_after_five_failures(account_a):
    """5회까지는 자격증명 오류이고 6회째부터 잠금인지.

    상한 이전과 이후를 함께 본다. 잠금만 확인하면 1회 실패로 잠그는 구현도 통과하는데,
    그러면 사용자가 비밀번호를 한 번 잘못 쳐도 15분을 기다려야 한다.
    """
    email = f"api29-lock-{account_a.user_id[:8]}@example.com"
    _register(email)

    for attempt in range(1, MAX_ATTEMPTS + 1):
        res = _login(email, "wrong-password")
        assert res.status_code == 401, res.text
        assert res.json()["code"] == "INVALID_CREDENTIALS", (
            f"{attempt}회째에 이미 잠겼다. 상한 {MAX_ATTEMPTS}회보다 이르다: {res.text}"
        )

    res = _login(email, "wrong-password")
    assert res.json()["code"] == "LOGIN_TEMPORARILY_LOCKED", (
        f"{MAX_ATTEMPTS + 1}회째에도 잠기지 않았다. 제한이 동작하지 않는다: {res.text}"
    )


def test_api_29_locked_account_rejects_the_correct_password(account_a):
    """잠긴 동안에는 맞는 비밀번호도 막히는지.

    이 조건이 핵심이다. 틀린 비밀번호만 세고 맞으면 통과시키는 구현은 앞 케이스를
    통과하면서도 대입을 전혀 막지 못한다. 공격자는 맞을 때까지 시도하기 때문이다.
    """
    email = f"api29-correct-{account_a.user_id[:8]}@example.com"
    _register(email)

    for _ in range(MAX_ATTEMPTS):
        assert _login(email, "wrong-password").status_code == 401

    res = _login(email, PASSWORD)
    assert res.status_code == 401, res.text
    assert res.json()["code"] == "LOGIN_TEMPORARILY_LOCKED", res.text


def test_api_29_success_clears_the_failure_count(account_a):
    """성공이 카운터를 지우는지.

    지우지 않으면 정상 사용자가 오래 쓸수록 실패가 누적돼 어느 날 갑자기 잠긴다.
    """
    email = f"api29-reset-{account_a.user_id[:8]}@example.com"
    _register(email)

    for _ in range(MAX_ATTEMPTS - 1):
        assert _login(email, "wrong-password").status_code == 401

    assert _login(email, PASSWORD).status_code == 200

    # 카운터가 0으로 돌아갔다면 다시 상한까지 자격증명 오류여야 한다.
    for attempt in range(1, MAX_ATTEMPTS + 1):
        res = _login(email, "wrong-password")
        assert res.json()["code"] == "INVALID_CREDENTIALS", (
            f"성공 후 {attempt}회째에 잠겼다. 카운터가 지워지지 않았다: {res.text}"
        )


def test_api_29_lock_does_not_reveal_account_existence(account_a):
    """없는 계정을 두드려도 잠금 코드가 나오지 않는지.

    잠금 여부로 계정의 존재를 알 수 있으면 열거가 가능해진다. 이 서버는 원래 존재
    여부를 숨기고 있으므로(INVALID_CREDENTIALS 단일 코드) 그 성질을 깨지 않아야 한다.
    """
    email = f"api29-nobody-{account_a.user_id[:8]}@example.com"

    for _ in range(MAX_ATTEMPTS + 1):
        res = _login(email, "wrong-password")
        assert res.json()["code"] == "INVALID_CREDENTIALS", (
            f"없는 계정에 잠금 코드가 나왔다. 계정 열거가 가능해진다: {res.text}"
        )
