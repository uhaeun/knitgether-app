"""③ 생성 재전송의 멱등성 (v2.3 §A-3 offline-first: 클라이언트 생성 UUID 재전송).

오프라인 우선 재시도에서 같은 생성 요청이 중복 전송돼도 레코드가 중복 생성되지 않아야
한다. 이 멱등성은 pending 재시도(§C-1)의 정합성 전제다.

2026-09-15에 그 멱등성을 얻는 방식이 바뀌었다. 예전에는 서버 `createProject`가
client-provided UUID로 업서트를 해서, 같은 id로 두 번 POST하면 두 번째가 그대로 전체
갱신으로 처리됐다. 행은 하나였지만 POST는 baseUpdatedAt을 싣지 않으므로 낙관적 잠금을
거치지 않았고, 응답만 유실된 재전송과 다른 기기가 그 사이 고친 경우를 서버가 구분하지
못했다. 뒤쪽이면 그 수정이 무통보로 사라진다(GitHub #14).

이제 서버는 기존 행에 대한 POST를 409 `PROJECT_ALREADY_EXISTS`로 거부한다. 클라이언트는
서버 본을 조회해 기준값을 얻고 수정(PATCH)으로 다시 보내며, 그때 낙관적 잠금이 판정한다.

**멱등성 자체는 유지된다.** 행은 여전히 하나이고, 재전송의 목적인 "내 생성을 서버에
반영한다"는 PATCH 경로로 달성된다. 바뀐 것은 경로이지 결과가 아니다.
기법: 계약 검증
"""
from helpers import project_payload


def test_duplicate_create_is_rejected_and_row_stays_single(account_a, db):
    """같은 id로 두 번 POST하면 두 번째는 409이고 행은 하나다."""
    payload = project_payload(name="멱등-원본")
    pid = payload["id"]

    r1 = account_a.api.create_project(payload)
    assert r1.status_code == 201, r1.text

    r2 = account_a.api.create_project(project_payload(pid, name="멱등-재전송"))
    assert r2.status_code == 409, r2.text
    assert r2.json()["code"] == "PROJECT_ALREADY_EXISTS", r2.text

    with db.cursor() as cur:
        cur.execute('SELECT COUNT(*) FROM "Project" WHERE id = %s;', (pid,))
        (count,) = cur.fetchone()
    assert count == 1, f"멱등성 위반 — 동일 id 행이 {count}개"

    # 거부된 요청이 값을 바꾸지 않았는지. 409를 돌려주면서 저장까지 하면
    # 상태 코드만 정직하고 데이터는 그대로 덮어써진다.
    assert account_a.api.get(f"/projects/{pid}").json()["name"] == "멱등-원본"


def test_resend_reaches_server_through_update_path(account_a, db):
    """재전송의 목적이 새 경로로 달성되는지. 이 케이스가 없으면 409로 막기만 하고
    사용자의 생성이 영영 서버에 반영되지 않는 구현도 앞 케이스만으로 통과한다.

    클라이언트가 실제로 하는 일을 그대로 따라간다. 409를 받고, 서버 본을 조회해
    기준값을 얻고, 수정으로 다시 보낸다.
    """
    payload = project_payload(name="재전송-원본")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201

    rejected = account_a.api.create_project(project_payload(pid, name="재전송-갱신"))
    assert rejected.status_code == 409, rejected.text

    baseline = account_a.api.get(f"/projects/{pid}").json()["updatedAt"]
    retried = account_a.api.patch(
        f"/projects/{pid}",
        json={**project_payload(pid, name="재전송-갱신"), "baseUpdatedAt": baseline},
    )
    assert retried.status_code == 200, retried.text
    assert account_a.api.get(f"/projects/{pid}").json()["name"] == "재전송-갱신"

    with db.cursor() as cur:
        cur.execute('SELECT COUNT(*) FROM "Project" WHERE id = %s;', (pid,))
        (count,) = cur.fetchone()
    assert count == 1, f"멱등성 위반 — 동일 id 행이 {count}개"
