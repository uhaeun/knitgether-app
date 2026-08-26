"""TC3 로그인 (UI-08~12). 시트: UI 케이스 탭.

진입 관문. 테스트 계정은 API로 미리 만들어 두고 UI는 로그인만 수행한다.
기법: 시나리오, 에러 기대
"""
import pytest

from pages.auth_page import AuthPage
from pages.home_page import HomePage
from support import server_api, texts as T

pytestmark = pytest.mark.server


@pytest.fixture(autouse=True)
def _server_up():
    assert server_api.health_ok(), "서버가 떠 있지 않다"


@pytest.fixture
def account():
    return server_api.register(display_name="로그인계정")


def test_ui_08_login_success(kg_server, account):
    """UI-08 올바른 자격으로 로그인하면 메인으로 가고 인사말과 홈 카드가 정상 로드된다.

    DEF-16(로그인 직후 무관한 401이 새 세션을 삭제하던 경합, 4f7e25e 수정) 증상 감시를 겸한다.
    홈 카드가 뜨지 않으면 세션이 사라진 것이다.
    """
    auth, home = kg_server.page(AuthPage), kg_server.page(HomePage)

    auth.open().login(account["email"], account["password"])

    home.open()
    assert home.has_text(account["displayName"], timeout=10), "인사말에 계정 이름이 없음"
    assert home.stat_int(T.HOME_TOTAL) >= 0, "홈 전체 프로젝트 카드가 로드되지 않음"


def test_ui_09_login_disabled_on_empty_input(kg_server):
    """UI-09 이메일과 비밀번호를 비우면 로그인 버튼이 비활성이다."""
    auth = kg_server.page(AuthPage)
    auth.open().select_mode(T.LOGIN)

    assert not auth.submit_enabled(), "미입력인데 로그인 버튼이 활성"


def test_ui_10_login_disabled_on_malformed_email(kg_server):
    """UI-10 형식이 잘못된 이메일이면 로그인 버튼이 비활성이다."""
    auth = kg_server.page(AuthPage)
    auth.open().select_mode(T.LOGIN)
    auth.fill("not-an-email", server_api.PASSWORD)

    assert not auth.submit_enabled(), "형식 오류 이메일인데 로그인 버튼이 활성"


def test_ui_11_unknown_email_rejected(kg_server):
    """UI-11 가입된 적 없는 이메일로 로그인하면 에러 메시지가 뜬다.

    계정 존재 여부를 노출하지 않도록 잘못된 비밀번호와 같은 문구여야 한다.
    """
    auth = kg_server.page(AuthPage)
    auth.open().login(server_api.new_email(), server_api.PASSWORD)

    assert auth.error_shown(T.BAD_CREDENTIALS), "인증 실패 메시지가 없음"
    assert not auth.logged_in(), "존재하지 않는 계정인데 로그인됨"


def test_ui_12_wrong_password_rejected(kg_server, account):
    """UI-12 비밀번호가 틀리면 UI-11과 같은 문구로 거부된다."""
    auth = kg_server.page(AuthPage)
    auth.open().login(account["email"], "wrong-password-9999")

    assert auth.error_shown(T.BAD_CREDENTIALS), "인증 실패 메시지가 없음"
    assert not auth.logged_in(), "비밀번호가 틀렸는데 로그인됨"
