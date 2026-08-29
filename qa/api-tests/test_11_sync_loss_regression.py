"""API-18, 19, 20. RC-01 동기화 유실 회귀. 07 3절 미커버 중 P1만 골랐다.

03의 우선순위에서 RC-01은 P1이고, 이 세 건이 거는 결함 DEF-01, 02, 03, 04, 12는
10에서 전부 Critical이다. 남은 미커버 API-21~24는 P2 이하이거나 치명도 축 밖이라
이번 범위에서 뺐다.

    API-18  stale PATCH가 기존 세션을 삭제하지 않는지 (DEF-01, 02)
    API-19  서버 거부 시 보존 (DEF-03)
    API-20  수정본 거부 시 무통보 폐기 금지 (DEF-04, 12)

셋의 공통 질문은 하나다. **거부되거나 일부만 담긴 요청이 서버에 이미 있는
데이터를 훼손하는가.** 클라이언트 쪽 localOnly 보존은 화면과 로컬 저장소가
대상이라 여기서 볼 수 없고, 서버가 남긴 상태만 psql로 본다.

판정은 전부 DB 실측이다. 응답 코드만 보면 거부가 성공했다는 것까지만 알 수 있고
그 사이 무엇이 지워졌는지는 알 수 없다.
"""
from helpers import project_payload, uid, work_session

S1 = ("2026-08-01T01:00:00.000Z", "2026-08-01T01:30:00.000Z")
S2 = ("2026-08-02T01:00:00.000Z", "2026-08-02T01:30:00.000Z")


def _live_sessions(db, pid):
    with db.cursor() as cur:
        cur.execute(
            'SELECT id FROM "WorkSession" WHERE "projectId" = %s AND "deletedAt" IS NULL',
            (pid,))
        return {r[0] for r in cur.fetchall()}


def _name(db, pid):
    with db.cursor() as cur:
        cur.execute('SELECT name FROM "Project" WHERE id = %s', (pid,))
        row = cur.fetchone()
    return row[0] if row else None


def _seed_two_sessions(account, name):
    """세션 2건을 가진 프로젝트를 만든다. 이후 케이스들의 공통 전제다."""
    payload = project_payload(name=name)
    pid = payload["id"]
    a, b = uid(), uid()
    payload["workSessions"] = [
        work_session(pid, session_id=a, started_at=S1[0], ended_at=S1[1]),
        work_session(pid, session_id=b, started_at=S2[0], ended_at=S2[1]),
    ]
    assert account.api.create_project(payload).status_code == 201
    return pid, a, b


# ---------------------------------------------------------------- API-18

def test_api_18_partial_payload_does_not_delete_existing_sessions(account_a, db):
    """세션 하나만 담은 PATCH가 나머지를 지우는가. DEF-01, 02의 재현 조건이다.

    다중 기기에서는 각 기기가 자기가 아는 세션만 보낸다. 서버가 페이로드에 없는
    세션을 지우면, 다른 기기에서 쌓은 작업 기록이 조용히 사라진다. 수정
    커밋(`d0a753a`)이 증분 upsert로 바꾼 지점이 여기다.
    """
    pid, a, b = _seed_two_sessions(account_a, "API18-부분전송")
    assert _live_sessions(db, pid) == {a, b}, "전제가 안 섰다"

    partial = project_payload(pid, name="API18-부분전송")
    partial["workSessions"] = [
        work_session(pid, session_id=a, started_at=S1[0], ended_at=S1[1])
    ]
    assert account_a.api.patch(f"/projects/{pid}", json=partial).status_code == 200

    live = _live_sessions(db, pid)
    assert b in live, (
        f"페이로드에 없던 세션이 사라졌다. 남은 것 {live}. "
        "DEF-01, 02 재발이며 다른 기기의 작업 기록이 유실된다"
    )
    assert a in live


def test_api_18_resend_does_not_duplicate_or_drop(account_a, db):
    """같은 페이로드를 다시 보내도 세션이 늘거나 줄지 않는가.

    offline-first라 복구 시 재전송이 반드시 일어난다. DEF-02는 단일 기기
    재전송만으로 세션이 소멸한 결함이었다.
    """
    pid, a, b = _seed_two_sessions(account_a, "API18-재전송")
    before = _live_sessions(db, pid)

    resend = project_payload(pid, name="API18-재전송")
    resend["workSessions"] = [
        work_session(pid, session_id=a, started_at=S1[0], ended_at=S1[1]),
        work_session(pid, session_id=b, started_at=S2[0], ended_at=S2[1]),
    ]
    assert account_a.api.patch(f"/projects/{pid}", json=resend).status_code == 200

    after = _live_sessions(db, pid)
    assert after == before, f"재전송으로 세션 집합이 바뀌었다. 전 {before}, 후 {after}"


# ---------------------------------------------------------------- API-19

def test_api_19_rejected_request_preserves_server_state(account_a, db):
    """거부된 요청이 서버에 이미 있는 데이터를 훼손하는가. DEF-03 계열이다.

    클라이언트가 보낸 것이 거부되면 클라이언트는 자기 것을 지킬지 버릴지
    정해야 한다. 그 판단이 성립하려면 서버 쪽이 최소한 그대로여야 한다.
    거부하면서 절반을 써 버리면 어느 쪽도 진실이 아니게 된다.
    """
    pid, a, b = _seed_two_sessions(account_a, "API19-거부보존")
    before_sessions = _live_sessions(db, pid)
    assert before_sessions == {a, b}, (
        f"전제가 안 섰다. 세션이 {before_sessions}뿐이라 이 판정은 공허해진다")

    bad = project_payload(pid, name="API19-거부보존")
    bad["workSessions"] = [
        work_session(pid, session_id=a, started_at=S1[0], ended_at=S1[1]),
        work_session(pid, session_id=uid(), started_at="말이 안 되는 시각", ended_at=None),
    ]
    r = account_a.api.patch(f"/projects/{pid}", json=bad)
    assert r.status_code == 400, f"잘못된 시각이 {r.status_code}로 통과했다: {r.text}"

    assert _live_sessions(db, pid) == before_sessions, (
        "거부된 요청이 기존 세션을 바꿨다. 거부와 부분 반영이 함께 일어나면 "
        "클라이언트가 무엇을 믿어야 할지 알 수 없다"
    )


# ---------------------------------------------------------------- API-20

def test_api_20_rejected_update_does_not_discard_previous_value(account_a, db):
    """거부된 수정이 기존 값을 덮어쓰는가. DEF-04, 12 계열이다.

    수정본이 거부됐는데 서버 값까지 바뀌면, 사용자는 실패 안내를 받고도 데이터가
    변한 상태를 보게 된다. 무통보 폐기가 이 모양으로 일어난다.
    """
    payload = project_payload(name="API20-원본이름")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201
    assert _name(db, pid) == "API20-원본이름"

    bad = project_payload(pid, name="API20-바뀐이름")
    bad["startDate"] = "이건 날짜가 아니다"
    r = account_a.api.patch(f"/projects/{pid}", json=bad)
    assert r.status_code == 400, f"잘못된 날짜가 {r.status_code}로 통과했다: {r.text}"

    assert _name(db, pid) == "API20-원본이름", (
        f"거부됐는데 이름이 {_name(db, pid)}로 바뀌었다. 사용자는 실패 안내를 받고도 "
        "데이터가 변한 상태를 본다"
    )


def test_api_20_rejected_update_keeps_children_intact(account_a, db):
    """거부된 수정이 자식 레코드까지 훼손하는가.

    부모만 롤백되고 자식이 남거나 지워지면 정합성이 깨진다. 05의 트랜잭션
    원자성과 같은 축이지만, 이쪽은 거부 경로에서 본다.
    """
    pid, a, b = _seed_two_sessions(account_a, "API20-자식보존")
    before = _live_sessions(db, pid)
    assert before == {a, b}, (
        f"전제가 안 섰다. 세션이 {before}뿐이라 이 판정은 공허해진다")

    bad = project_payload(pid, name="API20-자식보존")
    bad["rowCounter"]["currentRow"] = -5          # 하한 위반으로 거부시킨다
    bad["workSessions"] = [
        work_session(pid, session_id=uid(), started_at=S1[0], ended_at=S1[1])
    ]
    r = account_a.api.patch(f"/projects/{pid}", json=bad)
    assert r.status_code == 400, f"음수 currentRow가 {r.status_code}로 통과했다: {r.text}"

    assert _live_sessions(db, pid) == before, (
        "거부된 수정이 세션 집합을 바꿨다. 부모는 롤백됐는데 자식이 따라가지 않았다"
    )
