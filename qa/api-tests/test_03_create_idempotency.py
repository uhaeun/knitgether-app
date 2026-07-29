"""
③ 생성 요청 2회 멱등성 (v2.3 §A-3 offline-first: 클라이언트 생성 UUID 재전송).

검증 의도: 오프라인-우선 재시도에서 같은 생성 요청이 중복 전송돼도
레코드가 중복 생성되지 않아야 한다. 서버 `createProject`는 client-provided
UUID로 upsert(존재하면 update)하므로, 같은 id로 두 번 POST 해도 행은 1개여야
한다. 이 멱등성은 pending 재시도(§C-1)의 정합성 전제다.

근거: server/src/projects/projects.service.ts createProject (upsert 분기).
"""
from helpers import project_payload


def test_duplicate_create_is_idempotent(account_a, db):
    payload = project_payload(name="멱등-원본")
    pid = payload["id"]

    r1 = account_a.api.create_project(payload)
    # 같은 id로 재전송(값만 변경) — 재시도 시나리오
    r2 = account_a.api.create_project(project_payload(pid, name="멱등-재전송"))

    assert r1.status_code == 201, r1.text
    assert r2.status_code == 201, r2.text

    # DB에 동일 id 행이 정확히 1개 (중복 생성 없음)
    with db.cursor() as cur:
        cur.execute('SELECT COUNT(*) FROM "Project" WHERE id = %s;', (pid,))
        (count,) = cur.fetchone()
    assert count == 1, f"멱등성 위반 — 동일 id 행이 {count}개"

    # upsert 이므로 후행 값이 반영됐는지(update 동작)까지 특성화
    assert account_a.api.get(f"/projects/{pid}").json()["name"] == "멱등-재전송"
