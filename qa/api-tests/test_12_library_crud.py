"""API-17. 창고(실/바늘/도구) 재료 CRUD 기본 사이클.

TC12(등록)~TC14(삭제)가 요구하는 범위는 창고 도메인 전체다. 실 하나만 대표로
보면 바늘/도구의 필수 필드 차이(needleType+size, type)가 가려지므로 세
리소스 모두에서 사이클을 돈다.

`library.controller.ts` 실측(2026-08-31): `/library/{yarns,needles,tools}`
모두 list/create/update/delete만 있고 단건 GET 엔드포인트는 없다. 그래서
"GET으로 변경 확인" 단계는 목록에서 id로 찾는 방식으로 한다. 삭제는
`library.service.ts`의 `findActiveX`가 `deletedAt: null`로 조회해 없으면
404이므로, soft delete이고 재삭제는 404가 정답이다.
"""
import pytest

from helpers import uid

# (path, table, create_body, update_body)
RESOURCES = [
    (
        "yarns",
        "Yarn",
        lambda name: {"name": name, "quantity": 1, "brand": "APIQA사"},
        lambda name: {"name": name + "-수정", "quantity": 2, "brand": "수정사"},
    ),
    (
        "needles",
        "Needle",
        lambda name: {"name": name, "needleType": "circular", "size": "4mm"},
        lambda name: {"name": name + "-수정", "needleType": "dpn", "size": "5mm"},
    ),
    (
        "tools",
        "ToolItem",
        lambda name: {"name": name, "type": "가위"},
        lambda name: {"name": name + "-수정", "type": "마커"},
    ),
]


def _db_row(db, table, item_id):
    with db.cursor() as cur:
        cur.execute(f'SELECT "name", "deletedAt" FROM "{table}" WHERE id = %s', (item_id,))
        return cur.fetchone()


@pytest.mark.parametrize(
    "path, table, create_body, update_body", RESOURCES, ids=[r[0] for r in RESOURCES]
)
def test_api_17_library_crud_cycle(account_a, db, path, table, create_body, update_body):
    name = f"API17-{path}-{uid()[:8]}"
    create_payload = create_body(name)

    created = account_a.api.post(f"/library/{path}", json=create_payload)
    assert created.status_code == 201, created.text
    item = created.json()
    item_id = item["id"]
    assert item["name"] == create_payload["name"], "생성 응답 name이 요청과 다르다"

    # 사전조건: DB에 실제로 행이 생겼고 아직 살아있어야 뒤의 update/delete 단언이 의미 있다
    row = _db_row(db, table, item_id)
    assert row is not None, f"POST 201인데 {table} 테이블에 행이 없다"
    assert row[0] == create_payload["name"]
    assert row[1] is None, "생성 직후인데 deletedAt이 이미 찍혀 있다"

    listed = account_a.api.get(f"/library/{path}")
    assert listed.status_code == 200
    assert item_id in {i["id"] for i in listed.json()}, "생성한 항목이 목록에 없다"

    # ---- Update ----
    update_payload = update_body(name)
    updated = account_a.api.patch(f"/library/{path}/{item_id}", json=update_payload)
    assert updated.status_code == 200, updated.text
    assert updated.json()["name"] == update_payload["name"], "PATCH 응답에 수정값이 없다"

    row_after_update = _db_row(db, table, item_id)
    assert row_after_update[0] == update_payload["name"], "PATCH 200인데 DB name이 안 바뀌었다"

    # ---- GET으로 변경 확인 (단건 GET이 없어 목록에서 대조) ----
    listed_after_update = account_a.api.get(f"/library/{path}")
    listed_item = next(i for i in listed_after_update.json() if i["id"] == item_id)
    assert listed_item["name"] == update_payload["name"], "목록 재조회에 수정값이 반영되지 않았다"

    # ---- Delete ----
    deleted = account_a.api.delete(f"/library/{path}/{item_id}")
    assert deleted.status_code == 204, deleted.text

    row_after_delete = _db_row(db, table, item_id)
    assert row_after_delete is not None, (
        "삭제 후 행 자체가 사라졌다. tombstone(soft delete)이 기대인데 하드 삭제로 보인다"
    )
    assert row_after_delete[1] is not None, "DELETE 204인데 deletedAt이 안 찍혔다"

    # ---- 삭제 후 조회/목록 상태 확인 ----
    listed_after_delete = account_a.api.get(f"/library/{path}")
    assert item_id not in {i["id"] for i in listed_after_delete.json()}, (
        "삭제한 항목이 목록에서 계속 노출된다"
    )

    re_delete = account_a.api.delete(f"/library/{path}/{item_id}")
    assert re_delete.status_code == 404, (
        f"이미 삭제된 항목 재삭제가 {re_delete.status_code}다. soft-delete 뒤 findActive*가 "
        "404를 던져야 한다"
    )
