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
저장된다"까지다.

2026-09-15에 그 위 문단이 남긴 숙제("앱이 정지되지 않는 짧은 백그라운드")를 실행했다.
아래 `test_def23_short_background_is_excluded_from_work_time`이 그것이다. 결과를 적는다.

| 빌드 | 65초 | 8초(짧은 구간) | 대조군(백그라운드 없음) |
| --- | --- | --- | --- |
| 수정 후 (현재) | PASS | PASS | - |
| 수정 전 (1637acc) | FAIL 세션 없음 | FAIL 세션 없음 | **FAIL 세션 없음** |

대조군이 결론을 뒤집었다. 수정 전 빌드는 **백그라운드를 거치지 않아도** 세션을 저장하지
않는다. 그러면 앞의 두 FAIL은 백그라운드 때문이 아니므로 아무것도 말해주지 않는다.
원인은 특정하지 못했다. 그 빌드에는 이후 9일치 수정이 빠져 있고 테스트 코드와 페이지
객체는 현재 세대이므로, 어긋나는 축이 너무 많다.

**결론: 수정 전 빌드는 재현 수단이 될 수 없다.** 오래된 빌드에 현재 케이스를 돌리면
결함이 아니라 세대 차이를 재게 된다.

그래서 DEF-23의 원래 증상인 과다 기록은 **재현 불가로 확정한다.** 두 번 시도했고(9/3
65초, 9/15 8초) 두 번 다 다른 증상이 나왔으며, 세 번째 시도인 수정 전 빌드 대조는 실험이
성립하지 않는 것으로 판명됐다.

이 파일의 두 케이스가 보장하는 것은 현재 빌드의 동작이다. 아래 짧은 구간 케이스는
**검출력이 확인되지 않았다.** 실패하는 것을 본 적이 없으므로, 백그라운드 처리를 되돌렸을 때
이 케이스가 잡아낼지는 아직 모른다. 잡아내는지 보려면 현재 빌드에서 그 처리만 되돌린
변형이 필요하고, 그것은 뮤테이션 테스트의 영역이다(13의 뮤테이션 6종과 같은 방식).

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
# 앱이 정지되지 않을 만큼 짧은 백그라운드. 위 65초 케이스가 과다 기록 대신 세션 소멸로
# 실패한 것이 iOS의 정지 때문이었으므로, 원래 증상을 보려면 정지 전에 돌아와야 한다.
SHORT_BACKGROUND_SECONDS = 8


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


def test_def23_short_background_is_excluded_from_work_time(kg_server):
    """짧은 백그라운드 구간이 작업 시간에서 빠지는지.

    65초 케이스는 iOS가 앱을 정지시켜 세션이 통째로 사라지는 바람에 원래 증상인 과다 기록을
    보지 못했다. 이 케이스는 정지 전에 돌아와 앱이 살아 있는 상태로 판정한다. 수정 전
    코드라면 시작 시각이 메모리에 그대로 있으므로 백그라운드 구간이 세션에 포함된다.

    판정 기준을 앞 케이스와 다르게 잡는다. 앞은 "백그라운드 구간이 통째로 들어갔는가"를
    상한으로 보는데, 짧은 구간에서는 그 상한이 너무 헐거워 수정 전 코드도 통과한다.
    여기서는 복귀 후 화면에 머문 시간까지 더해 실제 작업 시간의 상한을 만든다.
    """
    account = server_api.register(display_name="짧은백그라운드")
    project_id = server_api.create_project(account["token"], "DEF23-짧은구간")

    auth, lst = kg_server.page(AuthPage), kg_server.page(MyKnittingPage)
    auth.open().login(account["email"], account["password"])

    lst.open().open_project("DEF23-짧은구간")
    time.sleep(BEFORE_BACKGROUND_SECONDS)

    kg_server.driver.background_app(SHORT_BACKGROUND_SECONDS)
    time.sleep(2)

    after_return_seconds = 3
    time.sleep(after_return_seconds)
    lst.open()
    time.sleep(3)

    sessions = []
    deadline = time.time() + 30
    while time.time() < deadline:
        sessions = [s for s in _work_sessions(account["token"], project_id) if s.get("endedAt")]
        if sessions:
            break
        time.sleep(2)

    assert sessions, "30초를 기다려도 저장된 작업 세션이 없다(길이 판정에 도달하지 못함)"

    # 백그라운드에서 세션이 끊기면 첫 세션은 진입부터 백그라운드 진입까지다.
    # 끊기지 않으면 백그라운드 구간과 복귀 후 구간이 하나로 이어져 더 길어진다.
    allowance = 6
    upper_bound = BEFORE_BACKGROUND_SECONDS + allowance
    longest = max(_duration_seconds(s) for s in sessions)

    assert longest <= upper_bound, (
        f"가장 긴 세션이 {longest:.0f}초다. 상한 {upper_bound}초를 넘었으므로 "
        f"백그라운드 {SHORT_BACKGROUND_SECONDS}초와 복귀 후 구간이 작업 시간에 "
        "포함됐다(DEF-23 원래 증상인 과다 기록)"
    )
