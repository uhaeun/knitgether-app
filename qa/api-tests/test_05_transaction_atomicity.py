"""
⑤ 트랜잭션 원자성 — 부분 커밋 없음 (v2.3 §A-3 저장소 계층, $transaction).

검증 의도: updateProject는 $transaction 안에서 부모 update → saveProjectChildren를
순차 실행한다. 자식 저장 단계에서 실패가 나면 이미 적용된 부모 변경까지
롤백돼야 한다(원자성).

실패 주입: rowInstruction 두 건을 **동일 id(중복 PK)** 로 전송 →
`rowInstruction.createMany`(projects.service.ts:1530, skipDuplicates 없음)가
PK 충돌로 던진다. 이는 부모 이름 변경(트랜잭션 내 선행 update) 이후에 발생하므로,
롤백되면 프로젝트 이름은 원본으로 남아야 한다.

주입 지점 변경 이력 (2026-08-29)
    원래 이 테스트는 workSession 중복 PK로 실패를 주입했다. DEF-01, 02 수정
    커밋(`d0a753a`)이 그 경로를 full-replace(deleteMany + createMany)에서 증분
    upsert로 바꾸면서(projects.service.ts:1445-1450) 중복 id가 더 이상 던지지
    않게 됐다. 서버는 200을 돌려주고 테스트는 실패했다.

    이때 실패한 것은 제품이 아니라 테스트다. 주입이 작동하지 않으면 원자성은
    검증되지 않은 채 남는데, 그 사실이 "원자성 의심"이라는 메시지로 잘못
    보고됐다. 아직 full-replace로 남아 있는 rowInstruction으로 주입 지점을
    옮겨 검출력을 되살렸다.

    수정이 기존 테스트의 실패 주입 경로를 지워 버리는 이 유형은 10의 4절
    함정 사례와 같은 계열이다. 통과하던 테스트가 갑자기 실패했을 때 제품부터
    의심하면 원인을 엉뚱한 곳에서 찾게 된다.
"""
import uuid

from helpers import project_payload


def _row_instruction(counter_id, instruction_id, row_number):
    return {
        "id": instruction_id,
        "rowCounterId": counter_id,
        "rowNumber": row_number,
        "instructionText": "원자성 주입용",
        "skillTags": None,
    }


def test_child_failure_rolls_back_parent_update(account_a, db):
    payload = project_payload(name="원자성-원본")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201

    # 실패 주입: 이름을 바꾸면서 중복 id rowInstruction 2건 첨부
    bad = project_payload(pid, name="원자성-깨진변경")
    # 카운터 id를 유지해야 한다. 새 id를 보내면 FK 위반(P2003)으로 먼저 터져서
    # 중복 PK 주입에 닿지 못한다. 그 경로는 아래 별도 케이스가 담당한다.
    bad["rowCounter"]["id"] = payload["rowCounter"]["id"]
    counter_id = bad["rowCounter"]["id"]
    dup_id = str(uuid.uuid4())
    bad["rowCounter"]["rowInstructions"] = [
        _row_instruction(counter_id, dup_id, 1),
        _row_instruction(counter_id, dup_id, 2),   # 동일 PK → createMany 실패
    ]
    r = account_a.api.patch_project(pid, bad)

    # 200이면 안 됨(자식 저장 실패가 삼켜졌거나 주입이 작동하지 않는다는 뜻).
    assert r.status_code >= 400, (
        f"중복 PK인데 성공 응답({r.status_code})이다. 자식 저장 실패가 삼켜졌거나, "
        "이 경로도 upsert로 바뀌어 주입이 더 이상 작동하지 않는다. 후자라면 제품이 "
        "아니라 이 테스트를 고쳐야 한다"
    )

    # 핵심: 부모 이름이 롤백돼 원본이어야 함(부분 커밋 없음)
    with db.cursor() as cur:
        cur.execute('SELECT name FROM "Project" WHERE id=%s;', (pid,))
        (name,) = cur.fetchone()
    assert name == "원자성-원본", (
        f"부분 커밋 발생 — 부모 이름이 '{name}'으로 남음(롤백 실패)"
    )


def test_injection_actually_injects(account_a):
    """실패 주입이 중복 PK 때문인지 확인한다. 앞 테스트의 전제다.

    서로 다른 id 2건은 통과해야 한다. 이것까지 400이면 거부 사유가 중복이 아니라
    페이로드 형식이라는 뜻이고, 그러면 앞 테스트는 원자성을 전혀 보지 않은 채
    통과하게 된다. 2026-08-29에 실제로 이 함정을 밟아 필드명을 고쳤다.
    """
    payload = project_payload(name="주입확인-원본")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201

    ok = project_payload(pid, name="주입확인-변경")
    ok["rowCounter"]["id"] = payload["rowCounter"]["id"]
    counter_id = ok["rowCounter"]["id"]
    ok["rowCounter"]["rowInstructions"] = [
        _row_instruction(counter_id, str(uuid.uuid4()), 1),
        _row_instruction(counter_id, str(uuid.uuid4()), 2),
    ]
    r = account_a.api.patch_project(pid, ok)
    assert r.status_code == 200, (
        f"서로 다른 id 2건이 {r.status_code}로 거부됐다: {r.text[:160]}. "
        "거부 사유가 중복 PK가 아니므로 원자성 테스트의 주입이 작동하지 않는다"
    )


def test_unknown_row_counter_id_is_rejected_without_mutation(account_a, db):
    """DEF-20 회귀. 저장되지 않은 rowCounter id는 400으로 거부하고 원본을 보존한다.

    클라이언트가 기존 프로젝트에 새 rowCounter id를 보내면서 행 지시를 함께
    보내면 서버가 500을 돌려준다. 서버는 프로젝트당 카운터를 1:1로 유지하므로
    보내온 새 id는 저장되지 않는데, 행 지시는 그 없는 id를 참조하도록 만들어져
    외래키(`RowInstruction_rowCounterId_fkey`, P2003)가 터진다.

    서버에는 이미 `ROW_COUNTER_NOT_FOUND` 검증이 있지만 지시의 rowCounterId가
    본문의 카운터 id와 같은지만 본다. 본문의 카운터 id가 실제 저장된 것과 같은지는
    보지 않아 가드가 불완전하다.

    클라이언트 UUID 생성 구조라 이 상황이 만들어질 수 있고, 그때 사용자가 받는 것은
    처리 가능한 4xx가 아니라 내부 오류다.

    내부 FK 오류를 500으로 노출하지 않고, 입력 계약 위반으로 처리해야 한다.
    부모 이름까지 바뀌지 않아야 거부가 원자적이라고 판정한다.
    """
    payload = project_payload(name="FK누수-원본")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201

    bad = project_payload(pid, name="FK누수-변경")
    stale_counter = bad["rowCounter"]["id"]        # 저장된 적 없는 새 id
    bad["rowCounter"]["rowInstructions"] = [
        _row_instruction(stale_counter, str(uuid.uuid4()), 1),
    ]
    r = account_a.api.patch_project(pid, bad)

    assert r.status_code == 400, f"없는 rowCounter id가 {r.status_code}로 처리됐다: {r.text}"
    assert r.json().get("code") == "VALIDATION_FAILED"

    with db.cursor() as cur:
        cur.execute('SELECT name FROM "Project" WHERE id=%s;', (pid,))
        (name,) = cur.fetchone()
    assert name == "FK누수-원본", "거부된 요청이 부모 프로젝트를 일부 변경했다"
