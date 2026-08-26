"""TC2 회원가입 (UI-02~07). 시트: UI 케이스 탭.

진입 관문이고 판정이 명확하다. 비밀번호 규칙은 서버 DTO 실측(8자 이상 256자 이하,
복잡도 요구 없음)을 기준으로 한다.
기법: 시나리오, 경계값, 에러 기대
"""
import pytest

from pages.auth_page import AuthPage
from support import server_api, texts as T

pytestmark = pytest.mark.server


@pytest.fixture(autouse=True)
def _server_up():
    assert server_api.health_ok(), "서버가 떠 있지 않다. docker compose up -d 와 npm run start:dev 필요"


def test_ui_02_signup_success(kg_server):
    """UI-02 고유 이메일과 유효 비밀번호로 가입하면 메인으로 가고 인사말에 이름이 보인다."""
    auth = kg_server.page(AuthPage)
    email, name = server_api.new_email(), "가입한니터"

    auth.ensure_logged_out()
    auth.signup(email, server_api.PASSWORD, name)

    auth.go_tab("홈")
    assert auth.has_text(name, timeout=10), "홈 인사말에 가입 시 입력한 이름이 없음"


def test_ui_03_duplicate_email_rejected(kg_server):
    """UI-03 이미 가입된 이메일로 다시 가입하면 에러 메시지가 뜨고 메인으로 넘어가지 않는다."""
    account = server_api.register()
    auth = kg_server.page(AuthPage)

    auth.ensure_logged_out()
    auth.signup(account["email"], account["password"], "중복가입")

    assert auth.error_shown(T.DUPLICATE_EMAIL), "중복 이메일 에러 메시지가 없음"
    assert not auth.logged_in(), "중복 가입인데 로그인 상태가 됨"


@pytest.mark.parametrize("email,password,label", [
    ("test", server_api.PASSWORD, "형식 오류 이메일"),          # UI-04
    ("test@test.com", "", "비밀번호 미입력"),                    # UI-05
    ("test@test.com", "1234567", "비밀번호 7자"),                # UI-06
])
def test_ui_04_05_06_submit_disabled_on_invalid_input(kg_server, email, password, label):
    """UI-04~06 형식 오류 이메일과 규칙 미달 비밀번호는 회원가입 버튼이 비활성이다.

    8자가 하한이므로 7자는 경계 바로 아래다.
    """
    auth = kg_server.page(AuthPage)
    auth.ensure_logged_out()
    auth.select_mode(T.SIGNUP)
    auth.fill(email, password, "tester")

    assert not auth.submit_enabled(), f"{label}인데 회원가입 버튼이 활성"


def test_ui_07_password_too_long_rejected(kg_server):
    """UI-07 257자 비밀번호는 상한(256자)을 넘어 서버가 거부한다. 경계 바로 위."""
    auth = kg_server.page(AuthPage)
    auth.ensure_logged_out()
    auth.signup(server_api.new_email(), "a" * 257, "tester")

    assert not auth.logged_in(), "257자 비밀번호로 가입이 되어버림"
