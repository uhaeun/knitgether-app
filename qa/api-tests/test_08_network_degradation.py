"""07 네트워크 열화. 회선이 나빠질 때 서버 계약과 데이터 정합성이 버티는가.

Charles 대신 `qa/appium/support/netgate.py` TCP 프록시를 쓴다. GUI 도구는
증거가 스크린샷으로만 남고 CI에 넣을 수 없는데, 여기 조건은 코드로 기록되고
그대로 다시 돌아간다.

앱이 아니라 API를 직접 상대한다. 화면 없이 계약만 시험하는 층이라 07에 속한다.
UI 쪽 오프라인 복구는 UI-78이 담당한다.

측정 원칙: 열화를 걸었다는 사실이 아니라 열화가 실제로 걸렸다는 것을 먼저
증명한다. 조건을 걸어도 응답 시간이 그대로면 그 뒤 판정은 전부 무의미하다.
"""
import sys
import time
from pathlib import Path

import pytest
import requests

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "qa/appium"))
from support.netgate import NetGate  # noqa: E402

from helpers import Api, project_payload  # noqa: E402


@pytest.fixture
def gate():
    g = NetGate(port=3999).open()
    yield g
    g.close()


def _api(gate, account):
    """게이트를 거쳐 나가는 클라이언트. 토큰은 정상 계정 것을 그대로 쓴다."""
    return Api(gate.base_url, account.token)


def _elapsed(fn):
    t0 = time.monotonic()
    fn()
    return time.monotonic() - t0


def test_gate_is_transparent_when_healthy(gate, account_a):
    """기준선. 조건을 안 걸면 프록시를 거쳐도 결과가 같아야 한다.

    이게 깨지면 뒤의 모든 판정이 프록시 결함과 구분되지 않는다.
    """
    api = _api(gate, account_a)
    payload = project_payload(name="NET-기준선")
    assert api.create_project(payload).status_code == 201
    assert api.get(f"/projects/{payload['id']}").status_code == 200


def test_latency_actually_applies(gate, account_a):
    """지연이 실제로 걸리는가. 열화 도구 자체의 검출력 확인이다."""
    api = _api(gate, account_a)
    payload = project_payload(name="NET-지연")

    baseline = _elapsed(lambda: api.create_project(payload))

    gate.degrade(latency_ms=300)
    slowed = _elapsed(lambda: api.get(f"/projects/{payload['id']}"))
    gate.reset()

    assert slowed > baseline + 0.25, (
        f"지연을 걸었는데 응답 시간이 그대로다. 기준선 {baseline:.3f}s, "
        f"지연 후 {slowed:.3f}s. 열화가 안 걸렸으므로 이 파일의 다른 판정도 믿을 수 없다"
    )


def test_complete_outage_then_recovery(gate, account_a):
    """완전 단절 중에는 실패하고 복구하면 통하는가."""
    api = _api(gate, account_a)
    payload = project_payload(name="NET-단절복구")
    assert api.create_project(payload).status_code == 201

    gate.close()
    with pytest.raises(requests.exceptions.RequestException):
        api.get(f"/projects/{payload['id']}")

    gate.open()
    api = _api(gate, account_a)
    assert api.get(f"/projects/{payload['id']}").status_code == 200, (
        "회선이 돌아왔는데 조회가 안 된다. 복구 경로에 문제가 있다"
    )


def test_frozen_response_still_commits_on_server(gate, account_a, db):
    """응답만 막고 클라이언트가 포기하면 서버는 어떻게 되는가.

    사용자가 기다리다 이탈하는 상황이다. 요청은 서버까지 갔고 처리도 끝났는데
    응답이 못 돌아와 클라이언트만 모른다. 이때 서버가 절반만 쓰고 멈추면
    데이터가 조용히 깨진다.

    요청 방향은 열어 둔다. 양방향을 막으면 서버에 아무것도 닿지 않아
    0건과 0건을 비교하는 공허한 판정이 된다.
    """
    payload = project_payload(name="NET-응답정지")
    pid = payload["id"]

    gate.freeze("down")
    with pytest.raises(requests.exceptions.RequestException):
        requests.post(f"{gate.base_url}/projects", json=payload,
                      headers={"Authorization": f"Bearer {account_a.token}"}, timeout=3)
    gate.thaw()
    time.sleep(1.0)

    with db.cursor() as cur:
        cur.execute('SELECT COUNT(*) FROM "Project" WHERE id = %s', (pid,))
        projects = cur.fetchone()[0]
        cur.execute('SELECT COUNT(*) FROM "RowCounter" WHERE "projectId" = %s', (pid,))
        counters = cur.fetchone()[0]

    assert projects == 1, (
        "요청 방향을 열어 뒀는데 서버에 프로젝트가 없다. 열화 도구가 요청까지 "
        "막고 있다는 뜻이라 이 판정은 무효다"
    )
    assert counters == 1, (
        f"프로젝트는 {projects}건인데 카운터가 {counters}건이다. 응답이 막힌 사이 "
        "서버가 부분 커밋을 남겼다"
    )


def test_connection_reset_after_commit_leaves_no_orphan(gate, account_a, db):
    """서버가 쓴 뒤 회선이 끊어져도 고아 자식 레코드가 남지 않는가.

    앞 케이스(freeze)는 응답이 안 와서 클라이언트가 스스로 포기하는 상황이고,
    이 케이스는 연결이 끊어져 버리는 상황이다. 클라이언트가 보는 결과는 둘 다
    실패지만 서버가 겪는 일은 다르다.

    요청은 대역폭 제한 없이 온전히 보내고, 응답 방향을 세운 뒤 끊는다. 이렇게
    해야 요청이 서버에 닿은 것이 보장되어 판정이 공허해지지 않는다.
    RowCounter는 Project와 1:1이라 부모 없이 자식만 남으면 정합성이 깨진 것이다.
    """
    import threading

    payload = project_payload(name="NET-리셋")
    pid = payload["id"]

    gate.freeze("down")                       # 요청은 통과, 응답만 붙잡는다
    threading.Timer(1.5, gate.cut).start()    # 서버가 다 쓴 뒤 회선을 끊는다
    with pytest.raises(requests.exceptions.RequestException):
        requests.post(f"{gate.base_url}/projects", json=payload,
                      headers={"Authorization": f"Bearer {account_a.token}"}, timeout=8)
    gate.reset()
    time.sleep(1.0)

    with db.cursor() as cur:
        cur.execute('SELECT COUNT(*) FROM "Project" WHERE id = %s', (pid,))
        reached = cur.fetchone()[0]
        cur.execute(
            'SELECT COUNT(*) FROM "RowCounter" c '
            'LEFT JOIN "Project" p ON p.id = c."projectId" '
            'WHERE c."projectId" = %s AND p.id IS NULL', (pid,))
        orphans = cur.fetchone()[0]
        cur.execute('SELECT COUNT(*) FROM "RowCounter" WHERE "projectId" = %s', (pid,))
        counters = cur.fetchone()[0]

    assert reached == 1, (
        "응답 방향만 막았는데 서버에 프로젝트가 없다. 요청이 도달하지 않았으므로 "
        "이 판정은 공허하다"
    )
    assert orphans == 0, f"부모 없는 RowCounter {orphans}건. 절단이 고아를 남겼다"
    assert counters == 1, f"프로젝트 1건에 카운터 {counters}건. 1:1이 깨졌다"


def test_retry_after_recovery_is_idempotent(gate, account_a, db):
    """단절 후 재전송이 중복 생성을 만들지 않는가.

    offline-first 구조라 복구 시 재전송이 반드시 일어난다. 클라이언트가 UUID를
    만들어 보내므로 같은 요청은 한 건으로 수렴해야 한다.
    """
    api = _api(gate, account_a)
    payload = project_payload(name="NET-재전송")
    pid = payload["id"]

    gate.close()
    with pytest.raises(requests.exceptions.RequestException):
        api.create_project(payload)

    gate.open()
    api = _api(gate, account_a)
    first = api.create_project(payload)
    second = api.create_project(payload)
    assert first.status_code in (200, 201), first.text
    assert second.status_code in (200, 201, 409), second.text

    with db.cursor() as cur:
        cur.execute('SELECT COUNT(*) FROM "Project" WHERE id = %s', (pid,))
        rows = cur.fetchone()[0]
    assert rows == 1, f"재전송으로 프로젝트가 {rows}건 생겼다. 멱등성 위반"
