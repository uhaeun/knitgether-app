"""
⑥ 인증 경계 + 입력 경계값 (v2.3 §C-2 인증, §B 단수/작업세션).

검증 의도:
- 인증 경계: 토큰 없음/변조/형식오류 Bearer → 401 (ApiAuthGuard).
- 경계값 RowCounter.currentRow: @Min(0) → 0 허용(200), -1 거부(400).
- WorkSession 시간 역전(endedAt < startedAt): 400으로 거부하고 프로젝트를 생성하지 않는다.

근거: src/auth/api-auth.guard.ts, project-save.dto.ts(@Min(0)),
      SaveWorkSessionDto와 서버의 세션 시간 검증.
"""
import requests

from helpers import bearer, project_payload, work_session


# ---- 인증 경계 ----

def test_missing_token_is_401(base_url):
    assert requests.get(f"{base_url}/projects", timeout=15).status_code == 401


def test_tampered_token_is_401(base_url, account_a):
    tampered = account_a.token[:-3] + ("aaa" if not account_a.token.endswith("aaa") else "bbb")
    r = requests.get(f"{base_url}/projects", headers=bearer(tampered), timeout=15)
    assert r.status_code == 401, r.text


def test_garbage_bearer_is_401(base_url):
    r = requests.get(f"{base_url}/projects", headers=bearer("not-a-jwt"), timeout=15)
    assert r.status_code == 401, r.text


# ---- 경계값: RowCounter.currentRow ----

def _make_project_with_current_row(account, current_row):
    payload = project_payload(name="경계-단수", current_row=max(current_row, 0))
    account.api.create_project(payload)
    rc = payload["rowCounter"]
    rc = {**rc, "currentRow": current_row}  # 경계 대상 값으로 교체
    return payload["id"], rc


def test_current_row_zero_is_accepted(account_a):
    pid, rc = _make_project_with_current_row(account_a, 0)
    r = account_a.api.patch(f"/projects/{pid}/row-counter", json=rc)
    assert r.status_code == 200, r.text


def test_negative_current_row_is_rejected_400(account_a):
    pid, rc = _make_project_with_current_row(account_a, -1)
    r = account_a.api.patch(f"/projects/{pid}/row-counter", json=rc)
    assert r.status_code == 400, f"@Min(0) 위반인데 {r.status_code}"


# ---- 경계값: WorkSession 시간 역전 ----

def test_time_reversed_work_session_behavior(account_a, db):
    pid = project_payload()["id"]
    payload = project_payload(pid, name="시간역전")
    # endedAt < startedAt (논리적으로 불가능한 구간)
    payload["workSessions"] = [
        work_session(
            pid,
            started_at="2026-07-29T05:00:00.000Z",
            ended_at="2026-07-29T04:00:00.000Z",
        )
    ]
    r = account_a.api.create_project(payload)
    # 수정된 계약의 회귀 검사다. 다시 수용하면 SKIP이 아니라 실패해야 한다.
    assert r.status_code == 400, r.text
    assert account_a.api.get(f"/projects/{pid}").status_code == 404, "거부한 프로젝트가 저장됨"
    with db.cursor() as cur:
        cur.execute('SELECT count(*) FROM "Project" WHERE id=%s', (pid,))
        assert cur.fetchone()[0] == 0, "거부한 프로젝트가 DB에 저장됨"
        cur.execute('SELECT count(*) FROM "RowCounter" WHERE "projectId"=%s', (pid,))
        assert cur.fetchone()[0] == 0, "거부한 프로젝트의 단수 정보가 DB에 저장됨"
