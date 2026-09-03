"""API-26. 낙관적 잠금 기준 시각은 서버 밀리초를 보존해 왕복한다.

같은 서버 시각은 저장할 수 있어야 하고, 초 단위로 잘린 과거 시각은 409로
거부돼야 한다. 두 분기를 함께 봐야 단순히 모든 요청을 허용하거나 거부하는
구현을 통과시키지 않는다.
"""
from helpers import project_payload


SERVER_TIME = "2026-09-02T01:02:03.123Z"


def _created_project(account, name):
    payload = project_payload(name=name)
    response = account.api.create_project(payload)
    assert response.status_code == 201, response.text
    return payload, response.json()


def _set_server_updated_at(db, project_id):
    with db.cursor() as cur:
        cur.execute(
            'UPDATE "Project" SET "updatedAt" = %s WHERE id = %s',
            (SERVER_TIME, project_id),
        )


def test_api_26_exact_millisecond_timestamp_allows_save(account_a, db):
    payload, created = _created_project(account_a, "API26-밀리초일치")
    _set_server_updated_at(db, payload["id"])

    update = project_payload(payload["id"], name="API26-수정성공")
    update["rowCounter"]["id"] = created["rowCounter"]["id"]
    update["baseUpdatedAt"] = SERVER_TIME
    response = account_a.api.patch(f'/projects/{payload["id"]}', json=update)

    assert response.status_code == 200, response.text
    assert response.json()["name"] == "API26-수정성공"


def test_api_26_truncated_timestamp_is_rejected_without_mutation(account_a, db):
    payload, created = _created_project(account_a, "API26-원본보존")
    _set_server_updated_at(db, payload["id"])

    update = project_payload(payload["id"], name="API26-덮어쓰면안됨")
    update["rowCounter"]["id"] = created["rowCounter"]["id"]
    update["baseUpdatedAt"] = "2026-09-02T01:02:03Z"
    response = account_a.api.patch(f'/projects/{payload["id"]}', json=update)

    assert response.status_code == 409, response.text
    assert response.json().get("code") == "PROJECT_CONFLICT"
    with db.cursor() as cur:
        cur.execute('SELECT name FROM "Project" WHERE id = %s', (payload["id"],))
        (stored_name,) = cur.fetchone()
    assert stored_name == "API26-원본보존"
