"""
⑤ 트랜잭션 원자성 — 부분 커밋 없음 (v2.3 §A-3 저장소 계층, $transaction).

검증 의도: updateProject는 $transaction 안에서 부모 update → saveProjectChildren를
순차 실행한다. 자식 저장 단계에서 실패가 나면 이미 적용된 부모 변경까지
롤백돼야 한다(원자성). 실패 주입: workSession 두 건을 **동일 id(중복 PK)** 로
전송 → saveProjectChildren의 `workSession.createMany`가 PK 충돌로 던짐.
이는 부모 이름 변경(트랜잭션 내 선행 update) 이후에 발생하므로, 롤백되면
프로젝트 이름은 원본으로 남아야 한다.

근거: projects.service.ts updateProject($transaction) → saveProjectChildren
      (workSession.createMany, skipDuplicates 없음).
"""
from helpers import project_payload, work_session


def test_child_failure_rolls_back_parent_update(account_a, db):
    payload = project_payload(name="원자성-원본")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201

    # 실패 주입: 이름을 바꾸면서 중복 id workSession 2건 첨부
    dup_id = work_session(pid)["id"]
    bad = project_payload(pid, name="원자성-깨진변경")
    bad["workSessions"] = [
        work_session(pid, session_id=dup_id),
        work_session(pid, session_id=dup_id),  # 동일 PK → createMany 실패
    ]
    r = account_a.api.patch(f"/projects/{pid}", json=bad)

    # 200이면 안 됨(자식 저장 실패가 삼켜졌다는 뜻). 4xx/5xx 기대.
    assert r.status_code >= 400, f"중복 PK인데 성공 응답({r.status_code}) — 원자성 의심"

    # 핵심: 부모 이름이 롤백돼 원본이어야 함(부분 커밋 없음)
    with db.cursor() as cur:
        cur.execute('SELECT name FROM "Project" WHERE id=%s;', (pid,))
        (name,) = cur.fetchone()
    assert name == "원자성-원본", (
        f"부분 커밋 발생 — 부모 이름이 '{name}'으로 남음(롤백 실패)"
    )
