"""API-27. 창고 입력 상한의 n/n+1 서버 경계값.

이름류는 30자, 도구 링크는 500자다. 각 필드에서 경계값은 저장되고 바로
다음 값은 400이어야 서버와 iOS 폼의 계약이 같은 것으로 판정한다.
"""
import pytest


CASES = [
    ("yarns", "name", 30, lambda value: {"name": value, "quantity": 1}),
    (
        "needles",
        "name",
        30,
        lambda value: {"name": value, "needleType": "circular", "size": "4mm"},
    ),
    ("tools", "name", 30, lambda value: {"name": value, "type": "marker"}),
    (
        "tools",
        "link",
        500,
        lambda value: {"name": "API27-tool", "type": "marker", "link": value},
    ),
]


@pytest.mark.parametrize(
    "resource, field, limit, make_payload",
    CASES,
    ids=["yarn-name", "needle-name", "tool-name", "tool-link"],
)
def test_api_27_library_field_accepts_n_and_rejects_n_plus_one(
    account_a, resource, field, limit, make_payload
):
    at_limit = "a" * limit
    accepted = account_a.api.post(f"/library/{resource}", json=make_payload(at_limit))
    assert accepted.status_code == 201, accepted.text
    assert accepted.json()[field] == at_limit

    over_limit = "b" * (limit + 1)
    rejected = account_a.api.post(f"/library/{resource}", json=make_payload(over_limit))
    assert rejected.status_code == 400, (
        f"{resource}.{field} {limit + 1}자가 {rejected.status_code}로 처리됐다: {rejected.text}"
    )
