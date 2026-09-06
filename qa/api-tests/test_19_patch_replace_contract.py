"""API-28. 수정 엔드포인트의 계약은 전체 교체다 (GitHub #16).

동사는 PATCH지만 동작은 전체 교체(full-replace)다. 필수 필드를 하나라도 빼면 400이고,
부분 전송으로 한 필드만 고칠 수 없다. 스펙에 부분 수정의 의미가 정의된 적이 없어
동사와 구현이 어긋난 채로 남아 있었다.

전체 교체를 계약으로 확정한다. 진짜 부분 수정으로 바꾸지 않은 이유는 이 프로젝트의
치명도 1위가 무통보 데이터 유실(RC-01)이기 때문이다. 병합 구현에서 "생략된 필드"를
"비우라는 뜻"으로 처리하는 실수가 정확히 그 결함이고, 수정 엔드포인트 16곳마다
그 실수의 기회가 생긴다. 게다가 중첩 컬렉션(workSessions, rowInstructions)은 생략의
의미 자체가 정의돼 있지 않다. 전부 지우라는 뜻인지 그대로 두라는 뜻인지 정할 근거가 없다.
얻는 것은 없다. 오프라인 우선 클라이언트는 이미 항상 전체 객체를 보낸다.

그래서 이 파일은 계약을 산문이 아니라 실행으로 고정한다. 누군가 나중에 DTO를 optional로
바꾸면 여기서 깨진다. 그때가 이 결정을 다시 논의할 시점이다.
기법: 계약 검증
"""
import pytest

from helpers import project_payload, uid


def test_api_28_dictionary_patch_rejects_partial_body(account_a):
    """이슈 #16의 재현 그대로. description만 보내면 term이 없어 400이다."""
    created = account_a.api.post(
        "/dictionary-terms",
        json={"term": f"API28-{uid()[:8]}", "description": "처음 설명"},
    )
    assert created.status_code == 201, created.text
    term_id = created.json()["id"]

    partial = account_a.api.patch(
        f"/dictionary-terms/{term_id}",
        json={"description": "새 설명"},
    )
    assert partial.status_code == 400, (
        "부분 전송이 통과했다. 전체 교체 계약이 바뀐 것이라면 이 케이스와 "
        f"docs/spec 결정을 함께 갱신해야 한다: {partial.text}"
    )

    full = account_a.api.patch(
        f"/dictionary-terms/{term_id}",
        json={"term": created.json()["term"], "description": "새 설명"},
    )
    assert full.status_code == 200, full.text
    assert full.json()["description"] == "새 설명"


def test_api_28_project_patch_rejects_partial_body(account_a):
    """집합체도 같다. name만 보내면 나머지 필수 필드가 없어 400이다."""
    payload = project_payload(name=f"API28-{uid()[:8]}")
    created = account_a.api.create_project(payload)
    assert created.status_code == 201, created.text
    project_id = created.json()["id"]

    partial = account_a.api.patch(
        f"/projects/{project_id}",
        json={"name": "이름만 바꾼다"},
    )
    assert partial.status_code == 400, (
        f"부분 전송이 통과했다. 전체 교체 계약이 바뀌었는지 확인해야 한다: {partial.text}"
    )


def test_api_28_project_patch_accepts_full_body(account_a):
    """전체 객체를 보내면 통과한다. 앞 케이스가 400인 이유가 서버 오류가 아니라
    필수 필드 누락임을 확인한다. 이 대조가 없으면 어떤 이유로든 400을 뱉는 서버도
    앞 케이스만으로 통과한다."""
    payload = project_payload(name=f"API28-{uid()[:8]}")
    created = account_a.api.create_project(payload)
    assert created.status_code == 201, created.text
    project_id = created.json()["id"]

    body = dict(payload)
    body["id"] = project_id
    body["name"] = "전체로 보내면 바뀐다"

    updated = account_a.api.patch(f"/projects/{project_id}", json=body)
    assert updated.status_code == 200, updated.text
    assert updated.json()["name"] == "전체로 보내면 바뀐다"


@pytest.mark.parametrize(
    "resource, make_payload",
    [
        ("yarns", lambda name: {"name": name, "quantity": 1}),
        (
            "needles",
            lambda name: {"name": name, "needleType": "circular", "size": "4mm"},
        ),
        ("tools", lambda name: {"name": name, "type": "marker"}),
    ],
    ids=["yarn", "needle", "tool"],
)
def test_api_28_library_patch_rejects_partial_body(account_a, resource, make_payload):
    """창고 세 종류가 같은 계약을 쓰는지. 하나만 부분 수정을 받아들이면
    클라이언트가 자원마다 다른 규칙을 기억해야 한다."""
    created = account_a.api.post(
        f"/library/{resource}", json=make_payload(f"API28-{uid()[:8]}")
    )
    assert created.status_code == 201, created.text
    item_id = created.json()["id"]

    partial = account_a.api.patch(
        f"/library/{resource}/{item_id}", json={"memo": "부분 수정 시도"}
    )
    assert partial.status_code == 400, (
        f"{resource}가 부분 전송을 받아들였다. 세 자원의 계약이 갈라졌다: {partial.text}"
    )
