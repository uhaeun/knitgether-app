"""DEF-23 회귀. 앱을 백그라운드로 보내면 진행 중인 작업 세션이 그 시점에 끝나는가.

10 대장이 적어둔 검증 방법(작업 공간 진입 → 홈 → 대기 → 복귀 → 이탈)을 그대로 자동화했다.
단위 테스트는 handleAppBackgrounded의 로직만 보고 scenePhase가 실제로 발화하는지는 보지
않으므로, 그 배선을 확인하는 것이 이 케이스의 몫이다.

판정은 화면이 아니라 서버에 저장된 세션 길이로 한다. 화면의 누적 시간은 반올림 표시라
"백그라운드 구간이 포함됐는가"를 초 단위로 가르지 못한다.

두 빌드 실측 (2026-09-03, iPhone 17 Pro Max 시뮬레이터).

| 빌드 | 결과 |
| --- | --- |
| 수정 후 (4dea734) | PASS. 백그라운드 65초가 빠진 세션 하나가 저장된다 |
| 수정 전 (efae837) | FAIL. 30초를 기다려도 세션이 하나도 저장되지 않는다 |

수정 전이 "약 80초 세션"이 아니라 "세션 없음"으로 실패한 것은 예상과 다르다. 65초
백그라운드에서 iOS가 앱을 정지시키고, 그러면 메모리에만 있던 시작 시각이 사라져 세션이
통째로 없어진다. 이것은 DEF-23이 아니라 10 대장이 별도로 분리해 둔 명세 공백(02의 4번,
강제 종료 시 세션 소멸)이다.

따라서 이 케이스가 실측으로 보인 것은 "수정 후에는 백그라운드 진입 시점에 세션이 끊겨
저장된다"까지다. 수정 전의 과다 기록(4시간 미만 방치가 그대로 기록됨)은 이 시나리오에서
재현되지 않았다. 그 증상을 보려면 앱이 정지되지 않는 짧은 백그라운드로 별도 케이스가
필요하고, 그 설계와 번호 배정은 QA(유하은) 몫이다.

이 케이스의 UI-NN 번호는 09에 아직 없다. 번호 배정과 등재는 QA(유하은) 몫으로 남긴다.
"""
import time

import pytest
import requests

from pages.auth_page import AuthPage
from pages.my_knitting_page import MyKnittingPage
from support import server_api

pytestmark = pytest.mark.server

BEFORE_BACKGROUND_SECONDS = 15
BACKGROUND_SECONDS = 65


@pytest.fixture(autouse=True)
def _server_up():
    assert server_api.health_ok(), "서버가 떠 있지 않다"


def _work_sessions(token, project_id):
    res = requests.get(f"{server_api.BASE_URL}/projects/{project_id}",
                       headers={"Authorization": f"Bearer {token}"}, timeout=15)
    res.raise_for_status()
    return res.json().get("workSessions", [])


def _duration_seconds(session):
    started = session["startedAt"].replace("Z", "+00:00")
    ended = session["endedAt"].replace("Z", "+00:00")
    from datetime import datetime
    return (datetime.fromisoformat(ended) - datetime.fromisoformat(started)).total_seconds()


def test_def23_background_ends_work_session(kg_server):
    """DEF-23. 백그라운드로 보낸 구간이 작업 시간으로 기록되지 않는다."""
    account = server_api.register(display_name="세션계정")
    project_id = server_api.create_project(account["token"], "DEF23-세션검증")

    auth, lst = kg_server.page(AuthPage), kg_server.page(MyKnittingPage)
    auth.open().login(account["email"], account["password"])

    # 작업 공간에 들어가면 앱이 세션을 자동 시작한다(ProjectWorkspaceView의 .task).
    lst.open().open_project("DEF23-세션검증")
    time.sleep(BEFORE_BACKGROUND_SECONDS)

    # 홈 버튼으로 앱을 내리고 그대로 방치한다. 이 구간이 작업 시간에 들어가면 결함이다.
    kg_server.driver.background_app(BACKGROUND_SECONDS)
    time.sleep(2)

    # 복귀 후 화면을 나가면 두 번째 세션이 끝난다(10초 미만이라 저장되지 않는다).
    lst.open()
    time.sleep(3)

    # 업로드가 늦을 수 있어 잠시 기다린다. 기다리지 않으면 "아직 안 올라왔다"와
    # "길이가 틀렸다"가 같은 실패로 뭉쳐서, 이 케이스가 무엇을 판정하는지 알 수 없게 된다.
    sessions = []
    deadline = time.time() + 30
    while time.time() < deadline:
        sessions = [s for s in _work_sessions(account["token"], project_id) if s.get("endedAt")]
        if sessions:
            break
        time.sleep(2)

    assert sessions, "30초를 기다려도 저장된 작업 세션이 없다(길이 판정에 도달하지 못함)"

    longest = max(_duration_seconds(s) for s in sessions)
    assert longest < BACKGROUND_SECONDS, (
        f"가장 긴 세션이 {longest:.0f}초다. 백그라운드 {BACKGROUND_SECONDS}초가 "
        "작업 시간에 포함됐다(DEF-23 재발)"
    )
