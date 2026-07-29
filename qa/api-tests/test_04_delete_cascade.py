"""
④ Project 삭제 cascade — 자식 테이블 정합성 (v2.3 §B 프로젝트 CRUD).

검증 의도: 프로젝트 삭제가 자식(rowCounter, workSession, rowInstruction 등)까지
정합하게 전파되는지 실 DB에서 확인한다. 서버는 hard delete가 아니라
**soft delete**: 부모와 자식 모두에 deletedAt을 수동 전파한다. 따라서
'cascade'의 실제 의미는 '자식 행이 사라짐'이 아니라 '자식 행에 deletedAt 설정'이며,
삭제 후 목록/조회에서 사라져야 한다. 두 관점(행 존재 + deletedAt)을 모두 본다.

근거: server/src/projects/projects.service.ts deleteProject
      (project + rowCounter + workSession + rowInstruction ... updateMany deletedAt).
"""
from helpers import project_payload, work_session


def test_delete_soft_cascades_to_children(account_a, db):
    pid = None
    payload = project_payload(name="삭제-cascade")
    pid = payload["id"]
    rc_id = payload["rowCounter"]["id"]
    ws = work_session(pid)
    payload["workSessions"] = [ws]

    assert account_a.api.create_project(payload).status_code == 201

    # 생성 직후: 부모/자식 deletedAt NULL
    with db.cursor() as cur:
        cur.execute('SELECT "deletedAt" FROM "Project" WHERE id=%s;', (pid,))
        assert cur.fetchone()[0] is None
        cur.execute('SELECT "deletedAt" FROM "RowCounter" WHERE id=%s;', (rc_id,))
        assert cur.fetchone()[0] is None
        cur.execute('SELECT "deletedAt" FROM "WorkSession" WHERE id=%s;', (ws["id"],))
        assert cur.fetchone()[0] is None

    # 삭제 (204)
    assert account_a.api.delete(f"/projects/{pid}").status_code == 204

    # soft delete: 행은 남되 부모+자식 모두 deletedAt 설정
    with db.cursor() as cur:
        cur.execute('SELECT "deletedAt" FROM "Project" WHERE id=%s;', (pid,))
        assert cur.fetchone()[0] is not None, "부모 deletedAt 설정돼야 함"
        cur.execute('SELECT "deletedAt" FROM "RowCounter" WHERE id=%s;', (rc_id,))
        assert cur.fetchone()[0] is not None, "rowCounter cascade 안 됨"
        cur.execute('SELECT "deletedAt" FROM "WorkSession" WHERE id=%s;', (ws["id"],))
        assert cur.fetchone()[0] is not None, "workSession cascade 안 됨"

    # 사용자 관점: 목록/조회에서 사라짐
    assert account_a.api.get(f"/projects/{pid}").status_code == 404
    assert all(p["id"] != pid for p in account_a.api.get("/projects").json())
