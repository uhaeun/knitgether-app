"""API-01, 07, 12, 15 — 기존 PARTIAL 판정에 비용이 낮은 assertion을 보강한다.

이 파일은 새 API 케이스를 여는 게 아니라, 07 3-2/09 3절 대조에서 PARTIAL로
남았던 항목 중 "부수적으로만 지나가서 부분"인 것들을 직접 assertion으로
닫는다. API-19처럼 클라이언트 계층이 필요한 항목은 여기 넣지 않는다.
"""
from helpers import project_payload, uid, work_session


# ---------------------------------------------------------------- API-01

def test_api_01_register_creates_user_account_row(account_a, db):
    """conftest._register는 1층(201, accessToken, /auth/me 200)만 확인한다.
    2층(UserAccount 행 생성)은 그동안 미조회였다. 세션 계정으로 직접 대조한다.
    """
    with db.cursor() as cur:
        cur.execute(
            'SELECT id, email, "deletedAt" FROM "UserAccount" WHERE email = %s',
            (account_a.email,),
        )
        row = cur.fetchone()

    assert row is not None, "회원가입 성공(201)인데 UserAccount 행이 없다"
    db_id, db_email, deleted_at = row
    assert db_id == account_a.user_id, "DB id가 /auth/me가 반환한 user_id와 다르다"
    assert db_email == account_a.email
    assert deleted_at is None


# ---------------------------------------------------------------- API-07

def test_api_07_missing_scalar_field_is_rejected(account_a):
    """필수 스칼라 필드 누락이 400인지는 그동안 신규 실행 필요/미검증으로 남아
    있었다. SaveProjectDto(`project-save.dto.ts`)에서 @IsOptional이 없는
    대표 필드(name)를 빼고 보낸다. @IsString()이 undefined를 그대로 거부한다.
    """
    without_name = project_payload(name="API07-누락테스트")
    del without_name["name"]
    r = account_a.api.create_project(without_name)
    assert r.status_code == 400, f"name 누락이 {r.status_code}로 통과했다: {r.text}"


def test_api_07_missing_row_counter_leaks_500_not_400(account_a):
    """신규 발견(QA 신규 발견, 2026-08-31): 필수 중첩 객체(rowCounter) 누락은
    400이 아니라 500이다. API-07의 판정 기준("누락 400")을 이 필드에서는
    만족하지 못한다.

    재현: rowCounter 키 자체를 뺀 SaveProjectDto로 POST /projects.
    원인: `project-save.dto.ts`의 `rowCounter`는 `@ValidateNested()`만 있고
    `@IsDefined()`/`@IsNotEmptyObject()`가 없다. class-validator는 값이
    undefined면 ValidateNested 자체를 건너뛰어 검증을 통과시킨다. 그 뒤
    `projects.service.ts:1417`의 `saveProjectChildren`이 `body.rowCounter.id`
    등을 무조건 역참조하면서 TypeError로 크래시하고, Nest 기본 예외 필터가
    이를 일반 500(`Internal server error`)으로 감싼다.
    영향: 클라이언트가 rowCounter를 빠뜨린 페이로드를 보내면 400으로 폼을
    고쳐 재시도할 수 있는 대신 내부 오류를 받는다. 이 assertion은 결함을
    감추지 않고 현재 실제 동작(500)을 그대로 고정해 회귀 감시로 쓴다.
    500이 400으로 바뀌면 이 결함이 해소된 것이므로 그때 뒤집는다.
    """
    without_row_counter = project_payload(name="API07-rowCounter누락")
    del without_row_counter["rowCounter"]
    r = account_a.api.create_project(without_row_counter)
    assert r.status_code == 500, (
        f"rowCounter 누락이 {r.status_code}다. 500이었던 결함이 해소됐다면 이 단언을 "
        "400으로 뒤집고 09/10의 API-07 기재를 갱신할 것"
    )


# ---------------------------------------------------------------- API-12 (부분 보강)

def test_api_12_work_session_missing_started_at_is_rejected(account_a):
    """세션 저장 검증 규칙 중 형식 축. `SaveWorkSessionDto.startedAt`은
    @IsISO8601로 필수다. 시간 역전 규칙(test_06, Issue #15로 skip)과는 다른
    축이라 이 축은 실제로 400이 나온다.

    주의: 이 테스트가 통과해도 API-12는 여전히 PARTIAL이다. 판정 기준의
    "시간 역전 세션 400"은 test_06에서 skip 상태로 남아 있고(현재 201),
    이 테스트는 그와 다른 규칙(필수 필드 형식)만 닫는다.
    """
    payload = project_payload(name="API12-세션형식오류")
    pid = payload["id"]
    payload["workSessions"] = [{
        "id": uid(),
        "projectId": pid,
        # startedAt 누락
        "endedAt": "2026-07-29T01:10:00.000Z",
        "memo": None,
    }]
    r = account_a.api.create_project(payload)
    assert r.status_code == 400, f"startedAt 누락 세션이 {r.status_code}로 통과했다: {r.text}"


def test_api_12_work_session_malformed_started_at_is_rejected(account_a):
    """startedAt이 ISO8601 형식이 아니면 거부되는가."""
    payload = project_payload(name="API12-세션형식오류2")
    pid = payload["id"]
    ws = work_session(pid, session_id=uid(), started_at="이건-날짜가-아니다")
    payload["workSessions"] = [ws]
    r = account_a.api.create_project(payload)
    assert r.status_code == 400, f"형식이 틀린 startedAt이 {r.status_code}로 통과했다: {r.text}"


# ---------------------------------------------------------------- API-15

def test_api_15_single_get_matches_db_row(account_a, db):
    """단건 조회 응답 필드가 psql 행과 일치하는가. 그동안 여러 테스트가
    부수적으로 GET을 썼을 뿐 이 케이스를 직접 겨냥한 assertion은 없었다.
    """
    payload = project_payload(name="API15-단건조회")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201

    got = account_a.api.get(f"/projects/{pid}")
    assert got.status_code == 200
    body = got.json()

    with db.cursor() as cur:
        cur.execute(
            'SELECT name, status, "isFavorite", memo, "startDate" '
            'FROM "Project" WHERE id = %s', (pid,)
        )
        row = cur.fetchone()

    assert row is not None, "사전조건 실패: DB에 프로젝트 행이 없다"
    db_name, db_status, db_is_favorite, db_memo, db_start_date = row

    assert body["name"] == db_name == payload["name"]
    assert body["status"] == db_status == payload["status"]
    assert body["isFavorite"] == db_is_favorite == payload["isFavorite"]
    assert body["memo"] == db_memo == payload["memo"]
    # startDate는 DB가 datetime, 응답은 ISO 문자열이라 날짜 부분으로 비교한다
    assert body["startDate"].startswith(db_start_date.date().isoformat())
