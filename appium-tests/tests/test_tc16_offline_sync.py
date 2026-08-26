"""TC16 오프라인 생성 후 복구 동기화 (UI-78). 시트: UI 케이스 탭.

치명도 1위(데이터 유실) 계열. 06의 TC-SYNC01-01 실측 PASS 흐름을 자동화로 옮겼다.
네트워크는 앱과 서버 사이에 둔 프록시를 닫고 열어 완전 단절을 만든다.
기법: 상태 전이, 시나리오
"""
import time

import pytest

from pages.auth_page import AuthPage
from pages.my_knitting_page import MyKnittingPage
from support import server_api, texts as T

pytestmark = pytest.mark.server

LOCAL_ONLY = "이 기기에만 있음"


@pytest.fixture(autouse=True)
def _server_up():
    assert server_api.health_ok(), "서버가 떠 있지 않다"


def test_ui_78_offline_create_then_sync_on_recovery(kg_offline, netgate):
    """UI-78 단절 중 만든 프로젝트가 복구 후 같은 항목 그대로 서버에 올라가는지."""
    account = server_api.register(display_name="동기화계정")
    auth, lst = kg_offline.page(AuthPage), kg_offline.page(MyKnittingPage)

    auth.open().login(account["email"], account["password"])
    lst.open()

    netgate.close()                       # 완전 단절
    lst.create_project("오프라인생성")
    assert LOCAL_ONLY in lst.row_summary("오프라인생성"), \
        f"단절 중 생성인데 로컬 전용 표시가 아님: {lst.row_summary('오프라인생성')}"

    netgate.open()                        # 복구
    # 프록시가 실제로 다시 통하는지 먼저 확인한다. 이걸 안 보면 아래 실패가
    # 앱 문제인지 관문 문제인지 가릴 수 없다.
    assert server_api.health_ok(base_url=netgate.base_url), "복구했는데 관문이 통하지 않는다"

    for _ in range(12):
        if LOCAL_ONLY not in lst.row_summary("오프라인생성"):
            break
        lst.retry_sync()
        lst.pull_to_refresh()
        time.sleep(2)

    assert LOCAL_ONLY not in lst.row_summary("오프라인생성"), \
        "네트워크가 돌아왔는데 계속 로컬 전용으로 남아 있음"
    assert lst.project_names().count("오프라인생성") == 1, "동기화 과정에서 항목이 중복 생성됨"
