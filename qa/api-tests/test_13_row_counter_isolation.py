"""API-21. RowCounter가 없는 프로젝트 하나가 전체 목록 조회를 깨뜨리지 않는가 (DEF-08 회귀).

DEF-08: 예전에는 `GET /projects`가 한 프로젝트의 RowCounter 결손 때문에 500을
냈다. `06c7a10` 수정 이후 `projects.service.ts:94-104`(listProjects)는
프로젝트별로 try/catch해 변환 실패 항목만 `this.logger.error`로 남기고
건너뛰며, 나머지는 정상 200으로 반환한다.

`toResponse`(projects.service.ts:1710-1722)는 `project.rowCounter`가 없거나,
소유자가 다르거나, `deletedAt`이 찍혀 있으면 500을 던진다. `Project.rowCounter`는
schema.prisma에서 `RowCounter?` (옵셔널) 관계라 RowCounter만 독립적으로
soft-delete할 수 있다. 이 테스트는 그 상태를 psql로 직접 만든다.

로그 기록(`this.logger.error("Skipped project ...")`)은 이 스위트가 서버
프로세스를 직접 띄우지 않아(conftest 전제: 서버가 이미 떠 있어야 함) 표준출력을
가로챌 수 없다. 로그 라인 자체는 위 소스 확인으로 대신하고, 여기서는 HTTP
계약(200 + 정상 포함/결손 제외)만 단언한다.
"""
from helpers import project_payload


def test_api_21_row_counter_missing_project_is_skipped_not_fatal(account_a, db):
    good = project_payload(name="API21-정상")
    broken = project_payload(name="API21-RowCounter결손")

    assert account_a.api.create_project(good).status_code == 201, "정상 프로젝트 생성 실패"
    assert account_a.api.create_project(broken).status_code == 201, "결손 대상 프로젝트 생성 실패"

    good_id, broken_id = good["id"], broken["id"]

    # 사전조건: 결손을 만들기 전에는 RowCounter가 정상 상태여야 한다.
    # 이게 비어 있으면 뒤의 "결손을 만들었다"는 단언 자체가 공허해진다.
    with db.cursor() as cur:
        cur.execute('SELECT "deletedAt" FROM "RowCounter" WHERE "projectId" = %s', (broken_id,))
        precondition = cur.fetchone()
    assert precondition is not None and precondition[0] is None, (
        "사전조건 실패: 생성 직후 RowCounter가 정상 상태가 아니다"
    )

    # DEF-08 조건 재현: RowCounter를 소프트 삭제한다 (toResponse의 deletedAt 체크에 걸림)
    with db.cursor() as cur:
        cur.execute(
            'UPDATE "RowCounter" SET "deletedAt" = now() WHERE "projectId" = %s', (broken_id,)
        )

    listed = account_a.api.get("/projects")
    assert listed.status_code == 200, (
        f"RowCounter 결손 프로젝트 하나 때문에 목록 전체가 {listed.status_code}로 실패했다 "
        "(DEF-08 재발)"
    )

    ids = {p["id"] for p in listed.json()}
    assert good_id in ids, "정상 프로젝트까지 목록에서 함께 사라졌다 (FAIL 조건)"
    assert broken_id not in ids, "RowCounter 결손 프로젝트가 걸러지지 않고 목록에 노출됐다"

    # 수정 범위 고정: listProjects만 가드됐고 단건 조회(getProject)는 가드 밖이다.
    # 이 값이 200으로 바뀌면 방어 범위가 넓어진 것이므로 09/10 기재를 갱신해야 한다.
    single = account_a.api.get(f"/projects/{broken_id}")
    assert single.status_code == 500, (
        f"단건 조회가 {single.status_code}다. listProjects에만 있던 가드가 getProject까지 "
        "넓어졌다면 이 문서와 09/10의 '수정 범위' 기재를 갱신할 것"
    )
