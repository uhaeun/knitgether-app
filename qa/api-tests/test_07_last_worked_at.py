"""API-25 세션 저장 시 서버 lastWorkedAt 갱신 (DEF-17 서버 계약 회귀).

DEF-17은 작업 세션을 저장해도 lastWorkedAt이 갱신되지 않아 최근 작업 순 정렬이
틀어지던 결함이다. 수정은 클라이언트와 서버 양쪽에 걸쳐 있었고, UI 회귀
(UI-33, 35, 38)는 2026-08-29 Appium 실행에서 통과했다. 이 파일은 남아 있던
서버 계약 쪽 회귀를 담당한다.

서버 계약 실측 (2026-08-29 소스 확인):
- `projects.service.ts:1395` 클라이언트가 보낸 lastWorkedAt을 그대로 저장한다.
  워크세션에서 계산하지 않는다.
- `projects.service.ts:1701` 목록 정렬은 즐겨찾기 우선, 그다음
  `lastWorkedAt ?? startDate` 내림차순이다.
- `project-save.dto.ts:203` lastWorkedAt은 `@IsOptional()` 이라 생략과 null이 모두 통과한다.

응답만 보지 않고 psql로 DB 실제값까지 대조한다. 서버가 200을 돌려주는 것과
값이 실제로 저장된 것은 다른 사실이기 때문이다.
"""
from helpers import project_payload, work_session

WORKED = "2026-08-20T10:00:00.000Z"
LATER = "2026-08-25T10:00:00.000Z"


def _db_last_worked_at(db, pid):
    """DB에 실제로 들어간 값. 응답을 믿지 않고 직접 본다."""
    with db.cursor() as cur:
        cur.execute('SELECT "lastWorkedAt" FROM "Project" WHERE id = %s', (pid,))
        row = cur.fetchone()
    assert row is not None, f"프로젝트가 DB에 없음: {pid}"
    return row[0]


def test_api_25_last_worked_at_round_trip(account_a, db):
    """클라이언트가 보낸 lastWorkedAt이 저장되고 응답과 DB에 같은 값으로 남는가."""
    payload = project_payload(name="API25-라운드트립")
    pid = payload["id"]
    payload["workSessions"] = [work_session(pid)]
    payload["lastWorkedAt"] = WORKED

    assert account_a.api.create_project(payload).status_code == 201

    body = account_a.api.get(f"/projects/{pid}").json()
    assert body["lastWorkedAt"] is not None, "응답에서 lastWorkedAt이 사라짐"
    assert body["lastWorkedAt"].startswith("2026-08-20T10:00:00"), body["lastWorkedAt"]

    stored = _db_last_worked_at(db, pid)
    assert stored is not None, "응답에는 있는데 DB에는 저장되지 않음"
    assert stored.isoformat().startswith("2026-08-20T10:00:00"), stored


def test_api_25_update_moves_last_worked_at(account_a, db):
    """세션을 더 저장해 lastWorkedAt을 앞당기면 DB 값도 따라 움직이는가.

    DEF-17의 증상이 정확히 이 지점이었다. 세션은 쌓이는데 lastWorkedAt이 그대로라
    정렬이 과거에 머물렀다.
    """
    payload = project_payload(name="API25-갱신")
    pid = payload["id"]
    payload["workSessions"] = [work_session(pid)]
    payload["lastWorkedAt"] = WORKED
    assert account_a.api.create_project(payload).status_code == 201

    later = project_payload(pid, name="API25-갱신")
    later["workSessions"] = [
        work_session(pid, started_at=WORKED, ended_at=WORKED),
        work_session(pid, started_at=LATER, ended_at=LATER),
    ]
    later["lastWorkedAt"] = LATER
    assert account_a.api.patch(f"/projects/{pid}", json=later).status_code == 200

    stored = _db_last_worked_at(db, pid)
    assert stored.isoformat().startswith("2026-08-25T10:00:00"), (
        f"세션을 더 저장했는데 lastWorkedAt이 따라오지 않음: {stored}. "
        "DEF-17 재발"
    )


def test_api_25_list_sorted_by_last_worked_at(account_a):
    """목록 정렬이 lastWorkedAt 내림차순인가. 최근 작업 순의 서버 쪽 근거다."""
    old = project_payload(name="API25-정렬-과거")
    new = project_payload(name="API25-정렬-최근")
    old["lastWorkedAt"] = WORKED
    new["lastWorkedAt"] = LATER

    # 과거 것을 나중에 만들어 생성 순서와 정렬 순서를 어긋나게 둔다.
    assert account_a.api.create_project(new).status_code == 201
    assert account_a.api.create_project(old).status_code == 201

    names = [p["name"] for p in account_a.api.get("/projects").json()
             if p["name"].startswith("API25-정렬-")]
    assert names == ["API25-정렬-최근", "API25-정렬-과거"], (
        f"lastWorkedAt 내림차순이 아님: {names}"
    )


def test_api_25_server_does_not_derive_from_sessions(account_a, db):
    """계약 공백을 기록한다. 워크세션이 있어도 서버는 lastWorkedAt을 계산하지 않는다.

    이 테스트가 통과한다는 것은 서버에 방어가 없다는 뜻이다. DEF-17의 수정이
    클라이언트에만 있으므로, 다른 클라이언트가 lastWorkedAt을 비워 보내면
    정렬이 다시 틀어진다. 서버가 세션에서 파생하도록 바뀌면 이 테스트가 FAIL하고
    그때가 계약이 좁혀졌다는 신호다.
    """
    payload = project_payload(name="API25-파생없음")
    pid = payload["id"]
    payload["workSessions"] = [work_session(pid, started_at=LATER, ended_at=LATER)]
    payload["lastWorkedAt"] = None

    assert account_a.api.create_project(payload).status_code == 201

    stored = _db_last_worked_at(db, pid)
    assert stored is None, (
        f"서버가 세션에서 lastWorkedAt을 파생하기 시작했다: {stored}. "
        "계약이 바뀌었으므로 09의 API-25와 10의 DEF-17 기재를 재검토할 것"
    )
