"""DEF-08: one corrupt counter must not hide healthy projects.

The original manual reproduction removed a row; later automation only marked
it deleted. Exercise both conditions and verify a changed value from SQL.
The remaining detail-query failure is tracked separately as an expected failure.
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
    assert projects[good_id]["rowCounter"]["currentRow"] == 99, "Return current SQL data, not the initial value"

    with db.cursor() as cur:
        cur.execute('SELECT "currentRow" FROM "RowCounter" WHERE "projectId" = %s', (good_id,))
        assert cur.fetchone() == (99,), "Listing must not change the healthy counter"


@pytest.mark.xfail(strict=True, reason="DEF-08: detail query still returns an unhandled 500 for a missing counter")
def test_def08_detail_query_handles_missing_counter_without_server_error(account_a, db):
    broken = project_payload(name="DEF08-detail-known-failure")
    assert account_a.api.create_project(broken).status_code == 201
    with db.cursor() as cur:
        cur.execute('DELETE FROM "RowCounter" WHERE "projectId" = %s', (broken["id"],))
        assert cur.rowcount == 1
    response = account_a.api.get(f"/projects/{broken['id']}")
    # Detect the known server failure without choosing a new recovery/4xx contract.
    assert response.status_code < 500, response.text
