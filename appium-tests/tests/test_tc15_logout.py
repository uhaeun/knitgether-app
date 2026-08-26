"""TC15 로그아웃 (UI-77). 시트: UI 케이스 탭.

AUTH-06 게이트 동작 확인이자 계정 격리(치명도 3위) 계열이다.
DEF-05, DEF-06(계정 간 노출)이 부분 수정으로 남아 있어 게이트가 노출을 막는지가 핵심이다.
기법: 상태 전이
"""
import pytest

from pages.auth_page import AuthPage
from pages.home_page import HomePage
from pages.my_knitting_page import MyKnittingPage
from support import server_api, texts as T

pytestmark = pytest.mark.server


@pytest.fixture(autouse=True)
def _server_up():
    assert server_api.health_ok(), "서버가 떠 있지 않다"


def test_ui_77_logout_shows_gate_and_hides_account_data(kg_server):
    """UI-77 로그인 중에는 내 데이터만 보이고, 로그아웃하면 게이트가 뜨며 데이터가 사라진다.

    로그아웃 이후만 보면 서버의 소유자 필터가 없어져도 통과한다(음성 대조에서 실측).
    그래서 다른 계정의 프로젝트가 섞여 보이지 않는지를 로그인 중에 먼저 확인한다.
    DEF-05, DEF-06, DEF-07(계정 간 노출) 계열.
    """
    other = server_api.register(display_name="남의계정")
    server_api.create_project(other["token"], "남의프로젝트")
    account = server_api.register(display_name="로그아웃계정")
    auth, home, lst = (kg_server.page(AuthPage), kg_server.page(HomePage),
                       kg_server.page(MyKnittingPage))

    auth.open().login(account["email"], account["password"])
    assert home.open().has_text(account["displayName"], timeout=10), "로그인 상태가 아님"
    assert "남의프로젝트" not in lst.open().project_names(), \
        "로그인 중에 다른 계정의 프로젝트가 보인다"

    auth.open().logout()

    assert not auth.logged_in(), "로그아웃했는데 여전히 로그인 상태"
    assert not home.open().has_text(account["displayName"], timeout=3), \
        "로그아웃 후에도 이전 계정 이름이 남아 있음"
    assert lst.open().count_label() in (None, 0), "로그아웃 후에도 이전 계정 프로젝트가 보임"

    kg_server.relaunch()
    assert not kg_server.page(AuthPage).open().logged_in(), "재실행 후 로그인 상태가 되살아남"
