"""DEF-08: one corrupt counter must not hide healthy projects.

The original manual reproduction removed a row; later automation only marked
it deleted. Exercise both conditions and verify a changed value from SQL.
An unavailable item must be reported explicitly without changing stored data.
"""
import pytest

from helpers import project_payload


@pytest.mark.parametrize("corruption", ["removed", "soft-deleted"])
def test_api_21_row_counter_missing_project_is_skipped_not_fatal(account_a, db, corruption):
    good = project_payload(name="API21-healthy", current_row=22)
    broken = project_payload(name="API21-corrupt")
    assert account_a.api.create_project(good).status_code == 201
    assert account_a.api.create_project(broken).status_code == 201
    good_id, broken_id = good["id"], broken["id"]

    with db.cursor() as cur:
        cur.execute('SELECT "deletedAt" FROM "RowCounter" WHERE "projectId" = %s', (broken_id,))
        assert cur.fetchone() == (None,), "Precondition: the counter must exist and be active"
        if corruption == "removed":
            cur.execute('DELETE FROM "RowCounter" WHERE "projectId" = %s', (broken_id,))
        else:
            cur.execute('UPDATE "RowCounter" SET "deletedAt" = now() WHERE "projectId" = %s', (broken_id,))
        assert cur.rowcount == 1, "Fault injection must change exactly one counter"
        cur.execute('UPDATE "RowCounter" SET "currentRow" = 99 WHERE "projectId" = %s', (good_id,))
        assert cur.rowcount == 1

    response = account_a.api.get("/projects")
    assert response.status_code == 200, response.text
    projects = {project["id"]: project for project in response.json()}
    assert good_id in projects, "The healthy project must remain accessible"
    assert broken_id not in projects, "The corrupt item must be isolated"
    unavailable = set(response.headers.get("X-KnitGether-Unavailable-Projects", "").split(","))
    assert broken_id in unavailable
    assert good_id not in unavailable
    assert projects[good_id]["rowCounter"]["currentRow"] == 99, "Return current SQL data, not the initial value"

    with db.cursor() as cur:
        cur.execute('SELECT "currentRow" FROM "RowCounter" WHERE "projectId" = %s', (good_id,))
        assert cur.fetchone() == (99,), "Listing must not change the healthy counter"


@pytest.mark.parametrize("corruption", ["removed", "soft-deleted", "wrong-owner"])
def test_def08_detail_reports_incomplete_data_without_repair_or_data_loss(account_a, account_b, db, corruption):
    broken = project_payload(name="DEF08-detail", current_row=37)
    broken["memo"] = "Do not reset this project or its counter."
    assert account_a.api.create_project(broken).status_code == 201
    with db.cursor() as cur:
        cur.execute('SELECT to_jsonb(r) FROM "RowCounter" r WHERE "projectId" = %s', (broken["id"],))
        counter_backup = cur.fetchone()[0]
        if corruption == "removed":
            cur.execute('DELETE FROM "RowCounter" WHERE "projectId" = %s', (broken["id"],))
        elif corruption == "soft-deleted":
            cur.execute('UPDATE "RowCounter" SET "deletedAt" = now() WHERE "projectId" = %s', (broken["id"],))
        else:
            cur.execute('UPDATE "RowCounter" SET "ownerId" = %s WHERE "projectId" = %s', (account_b.user_id, broken["id"]))
        assert cur.rowcount == 1

    def snapshot():
        with db.cursor() as cur:
            cur.execute('SELECT to_jsonb(p) FROM "Project" p WHERE id = %s', (broken["id"],))
            project = cur.fetchone()[0]
            cur.execute('SELECT to_jsonb(r) FROM "RowCounter" r WHERE "projectId" = %s', (broken["id"],))
            counter = cur.fetchone()
        return project, counter

    before = snapshot()
    response = account_a.api.get(f"/projects/{broken['id']}")
    assert response.status_code == 409, response.text
    assert response.json()["code"] == "PROJECT_ROW_COUNTER_MISSING"
    assert response.json()["details"] == {"projectId": broken["id"]}
    assert snapshot() == before, "Reading must not fabricate a default counter or change project data"

    # An incomplete record still belongs to its owner; other accounts must not learn its state.
    hidden = account_b.api.get(f"/projects/{broken['id']}")
    assert hidden.status_code == 404
    assert hidden.json()["code"] == "PROJECT_NOT_FOUND"
    other_list = account_b.api.get("/projects")
    assert other_list.status_code == 200
    assert broken["id"] not in other_list.headers.get("X-KnitGether-Unavailable-Projects", "")
    assert snapshot() == before

    # Restore the injected fault from the known test backup, not from a guessed value.
    with db.cursor() as cur:
        if corruption == "removed":
            from psycopg2.extras import Json
            cur.execute('INSERT INTO "RowCounter" SELECT * FROM jsonb_populate_record(NULL::"RowCounter", %s::jsonb)', (Json(counter_backup),))
        elif corruption == "soft-deleted":
            cur.execute('UPDATE "RowCounter" SET "deletedAt" = NULL WHERE "projectId" = %s', (broken["id"],))
        else:
            cur.execute('UPDATE "RowCounter" SET "ownerId" = %s WHERE "projectId" = %s', (counter_backup["ownerId"], broken["id"]))
        assert cur.rowcount == 1
    restored = account_a.api.get(f"/projects/{broken['id']}")
    assert restored.status_code == 200, restored.text
    assert restored.json()["rowCounter"]["id"] == broken["rowCounter"]["id"]
    assert restored.json()["rowCounter"]["currentRow"] == 37
    assert restored.json()["memo"] == broken["memo"]
    restored_list = account_a.api.get("/projects")
    assert restored_list.status_code == 200
    assert broken["id"] not in restored_list.headers.get("X-KnitGether-Unavailable-Projects", "")
