"""
② last-write-wins 증명 — 통과하는 negative test (Issue #14, severity/high).

검증 의도: 서버가 동시(순차) 수정 충돌을 감지하지 않음을 '증명'한다.
동일 리소스에 서로 다른 PATCH 2건을 순차 전송 → 둘 다 200, 최종값은
무조건 후행 요청. 409/버전 충돌 없음. 이 테스트가 PASS 한다는 것은
결함(#14)이 그대로 존재한다는 뜻이다. 수정되면(낙관적 잠금 도입 등)
이 테스트는 FAIL 해야 하며, 그때가 곧 회귀 알림이다.

근거: server/src/projects/projects.service.ts:184 (무조건 update),
      prisma/schema.prisma (version 필드 없음), v2.3 §C-1 (conflict 미구현).
"""
from helpers import project_payload


def test_last_write_wins_no_conflict_detection(account_a):
    payload = project_payload(name="LWW-원본")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201

    # 두 클라이언트가 같은 기준에서 서로 다른 수정을 순차 전송
    r1 = account_a.api.patch(f"/projects/{pid}", json=project_payload(pid, name="LWW-변경-1"))
    r2 = account_a.api.patch(f"/projects/{pid}", json=project_payload(pid, name="LWW-변경-2"))

    # 결함 특성: 둘 다 성공, 409 없음
    assert r1.status_code == 200, r1.text
    assert r2.status_code == 200, r2.text

    # 최종값은 후행 요청 → 선행(변경-1)은 무통보 유실
    final_name = account_a.api.get(f"/projects/{pid}").json()["name"]
    assert final_name == "LWW-변경-2", (
        "last-write-wins 이므로 후행 값이 이겨야 함. "
        "이 단언이 깨지면 충돌 보호가 도입된 것 → Issue #14 재평가"
    )
