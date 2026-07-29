"""
① ownerId 격리 (v2.3 §C-1 '유저 격리': 모든 도메인 데이터는 ownerId 스코프).

검증 의도: 계정 A의 리소스에 계정 B 토큰으로 접근/수정/삭제가 차단되고
(서버는 cross-owner를 NotFound=404로 처리), 그 시도가 실 DB에 어떤 변경도
남기지 않음을 psql로 직접 확인한다. mock e2e가 볼 수 없는 실 격리를 본다.
"""
from helpers import project_payload


def test_cross_owner_access_is_blocked_and_db_unchanged(account_a, account_b, db):
    # A가 프로젝트 생성
    payload = project_payload(name="A-소유-프로젝트")
    pid = payload["id"]
    r = account_a.api.create_project(payload)
    assert r.status_code == 201, r.text

    # B 토큰으로 A의 리소스 조회/수정/삭제 → 모두 404 (소유자 스코프)
    assert account_b.api.get(f"/projects/{pid}").status_code == 404
    assert account_b.api.patch(
        f"/projects/{pid}", json=project_payload(pid, name="B-가로챔")
    ).status_code == 404
    assert account_b.api.delete(f"/projects/{pid}").status_code == 404

    # 실 DB 확인: A 소유 그대로, 이름 불변, 미삭제
    with db.cursor() as cur:
        cur.execute(
            'SELECT "ownerId", name, "deletedAt" FROM "Project" WHERE id = %s;', (pid,)
        )
        row = cur.fetchone()
    assert row is not None, "A의 프로젝트가 DB에 있어야 함"
    owner_id, name, deleted_at = row
    assert owner_id == account_a.user_id, "소유자가 A여야 함"
    assert name == "A-소유-프로젝트", "B의 수정 시도가 반영되면 안 됨"
    assert deleted_at is None, "B의 삭제 시도가 반영되면 안 됨"

    # B의 목록에는 A의 프로젝트가 없어야 함
    b_list = account_b.api.get("/projects").json()
    assert all(p["id"] != pid for p in b_list), "B 목록에 A 프로젝트가 노출되면 안 됨"
