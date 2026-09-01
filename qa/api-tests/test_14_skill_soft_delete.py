"""API-22. 서버에서 삭제된 스킬이 이후 조회 결과에서 제외되는가 (DEF-09 서버 절반).

`skills.service.ts` 실측(2026-08-31): `deleteSkill`은 `deletedAt`을 찍는
소프트 삭제이고, 그 전에 `ensureEditable`이 `isSystem`이면 `ForbiddenException
SYSTEM_SKILL_READ_ONLY`로 막는다. `createSkill`(`toSkillData`)은 항상
`isSystem: false`로 만들므로 테스트 스킬은 삭제 대상이 된다. `listSkills`와
`getSkill`의 기반인 `findAccessibleSkill` 둘 다 `deletedAt: null` 필터를 건다.

DEF-09가 가리키는 "캐시 잔존"은 클라이언트 로컬 캐시 계층이라 API 테스트로 볼
수 없다. 이 파일은 서버 계약(삭제된 스킬이 서버 응답에서 실제로 빠지는가)만
FULL로 닫는다. 캐시 프루닝(앱이 재동기화 시 로컬 캐시에서 실제로 지우는가)은
08 UI 자동화 트랙의 몫으로 남긴다.
"""
from helpers import uid


def _skill_payload(name):
    return {
        "id": uid(),
        "name": name,
        "abbreviation": name[:4],
        "description": f"{name} 설명",
    }


def test_api_22_deleted_skill_is_excluded_from_list_and_single_get(account_a, db):
    payload = _skill_payload("API22-테스트스킬")

    created = account_a.api.post("/skills", json=payload)
    assert created.status_code == 201, created.text
    skill_id = created.json()["id"]
    assert created.json()["isSystem"] is False, (
        "사전조건 실패: 시스템 스킬로 생성됐다. 시스템 스킬은 삭제가 금지돼 뒤 단언이 무의미해진다"
    )

    # 사전조건: 삭제 전에는 목록과 단건 조회 모두에 존재해야 한다
    before_list = account_a.api.get("/skills")
    assert before_list.status_code == 200
    assert skill_id in {s["id"] for s in before_list.json()}, "사전조건 실패: 생성한 스킬이 목록에 없다"
    assert account_a.api.get(f"/skills/{skill_id}").status_code == 200, "사전조건 실패: 단건 조회 실패"

    deleted = account_a.api.delete(f"/skills/{skill_id}")
    assert deleted.status_code == 204, deleted.text

    with db.cursor() as cur:
        cur.execute('SELECT "deletedAt" FROM "Skill" WHERE id = %s', (skill_id,))
        row = cur.fetchone()
    assert row is not None, "삭제했는데 행 자체가 사라졌다 (하드 삭제 의심)"
    assert row[0] is not None, "DELETE 204인데 DB deletedAt이 안 찍혔다"

    after_list = account_a.api.get("/skills")
    assert after_list.status_code == 200
    assert skill_id not in {s["id"] for s in after_list.json()}, "삭제된 스킬이 목록에 계속 노출된다"

    single_after_delete = account_a.api.get(f"/skills/{skill_id}")
    assert single_after_delete.status_code == 404, (
        f"삭제된 스킬 단건 조회가 {single_after_delete.status_code}다"
    )
