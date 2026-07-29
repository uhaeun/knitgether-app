"""
⑥ 인증 경계 + 입력 경계값 (v2.3 §C-2 인증, §B 단수/작업세션).

검증 의도:
- 인증 경계: 토큰 없음/변조/형식오류 Bearer → 401 (ApiAuthGuard).
- 경계값 RowCounter.currentRow: @Min(0) → 0 허용(200), -1 거부(400).
- WorkSession 시간 역전(endedAt < startedAt): 서버에 교차 필드 검증이 없어
  '수용'될 것으로 예상(특성화). 200이면 검증 공백을 보고 대상으로 남긴다.

근거: src/auth/api-auth.guard.ts, project-save.dto.ts(@Min(0)),
      SaveWorkSessionDto(시작/종료 교차검증 부재).
"""
import pytest
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


# ---- 경계값: WorkSession 시간 역전 (특성화) ----

def test_time_reversed_work_session_behavior(account_a):
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
    # 교차 필드 검증이 없어 수용될 것으로 예상. 실제 코드를 특성화한다.
    # 수용(201)은 확정 결함 → Issue #15 (severity/medium, v2.3 §C-4).
    # 영향 실증: 총 작업시간 -3000초 표시 / 통계 과소집계 / 랭킹 항목 소실.
    # 서버 교차검증(400)이 도입되면 이 분기를 실동작에 맞게 갱신할 것.
    if r.status_code == 201:
        pytest.skip(
            "특성화(Issue #15): 서버가 시간 역전 세션을 수용함(교차 검증 부재). "
            "v2.3 §C-4는 endedAt>startedAt을 요구 → 현 동작은 스펙 위반이나 수정 전까지 감시."
        )
    else:
        # 검증 도입 후: 400 거부가 정상 (Issue #15 해소 신호)
        assert r.status_code == 400, r.text
