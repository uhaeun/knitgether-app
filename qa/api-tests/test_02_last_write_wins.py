"""② 동시 수정 충돌 감지 (Issue #14, severity/high).

이 파일은 원래 결함을 증명하는 negative test였다. 같은 리소스에 PATCH 2건을 순차로
보내면 둘 다 200이고 선행 수정이 무통보로 사라지는 것을, 그 자체를 단언해서 고정해
두었다. 문서에 "수정되면 이 테스트는 FAIL 해야 하며 그때가 곧 회귀 알림"이라고 적혀
있었고, 실제로 그렇게 됐다.

2026-09-06 서버가 수정(PATCH)에 낙관적 잠금 기준값을 필수로 요구하게 되면서 계약이
바뀌었다. 그래서 같은 시나리오를 새 계약으로 다시 쓴다. 확인하는 것은 세 가지다.

  1. 기준값 없는 수정은 400이다. 예전에는 검사를 건너뛰고 그냥 저장했다.
     서버가 최후 방어선이 아니었다는 뜻이다. 앱이 값을 보내주면 막고 안 보내면
     안 막았는데, 보호가 필요한 쪽은 값을 보내지 않는 클라이언트다.
  2. 같은 기준에서 출발한 두 수정 중 뒤의 것은 409다.
  3. 선행 수정이 살아남는다. 이것이 이 이슈의 본래 피해였다.

생성(POST)에는 기준값을 요구하지 않는다. 서버에 아직 없는 프로젝트의 "마지막으로 본
서버 시각"은 정의될 수 없기 때문이다. POST가 기존 프로젝트에 업서트되는 경로는 아직
last-write-wins다. 오프라인 클라이언트가 성공한 줄 모르고 생성을 재전송하는 경로라
클라이언트가 기준값을 가질 수 없는 것이 정상이고, 재전송 보호는 DEF-02에서 따로 다뤘다.
알려진 남은 간격이다.
기법: 계약 검증
"""
from helpers import project_payload


def test_update_without_base_updated_at_is_rejected(account_a):
    """기준값 없는 수정을 서버가 거부하는지. 이것이 없으면 서버는 앱이 협조할 때만
    동작하는 방어선이다."""
    payload = project_payload(name="LWW-원본")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201

    rejected = account_a.api.patch(
        f"/projects/{pid}", json=project_payload(pid, name="LWW-기준없음")
    )

    assert rejected.status_code == 400, rejected.text
    assert rejected.json()["code"] == "BASE_UPDATED_AT_REQUIRED", rejected.text

    # 거부된 요청이 값을 바꾸지 않았는지. 400을 돌려주면서 저장까지 해버리면
    # 상태 코드만 정직하고 데이터는 그대로 유실된다.
    assert account_a.api.get(f"/projects/{pid}").json()["name"] == "LWW-원본"


def test_second_update_from_same_baseline_is_rejected_and_first_survives(account_a):
    """같은 기준에서 출발한 두 수정. 뒤의 것이 409여야 하고, 앞의 것이 살아남아야 한다.

    앞의 것이 살아남는지까지 봐야 한다. 409만 확인하면 거부하면서 이미 덮어쓴
    구현도 통과한다. 이 이슈의 피해는 상태 코드가 아니라 사라진 데이터였다.
    """
    payload = project_payload(name="LWW-원본")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201

    baseline = account_a.api.get(f"/projects/{pid}").json()["updatedAt"]

    first = account_a.api.patch(
        f"/projects/{pid}",
        json={**project_payload(pid, name="LWW-변경-1"), "baseUpdatedAt": baseline},
    )
    assert first.status_code == 200, first.text

    # 두 번째 기기는 첫 수정을 모른 채 같은 기준으로 보낸다.
    second = account_a.api.patch(
        f"/projects/{pid}",
        json={**project_payload(pid, name="LWW-변경-2"), "baseUpdatedAt": baseline},
    )

    assert second.status_code == 409, second.text
    assert second.json()["code"] == "PROJECT_CONFLICT", second.text

    final_name = account_a.api.get(f"/projects/{pid}").json()["name"]
    assert final_name == "LWW-변경-1", (
        "선행 수정이 살아남아야 한다. 후행 값이 이겼다면 409를 돌려주면서 "
        "저장은 그대로 한 것이다"
    )


def test_update_with_refreshed_baseline_succeeds(account_a):
    """충돌 뒤 최신 기준값을 다시 읽어 보내면 통과하는지.

    이 대조가 없으면 모든 수정을 409로 막는 구현도 앞 케이스만으로 통과한다.
    앱의 충돌 복구는 서버 본을 다시 받아 재시도하는 흐름이라, 이 경로가 막히면
    사용자는 영영 저장할 수 없다.
    """
    payload = project_payload(name="LWW-원본")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201

    baseline = account_a.api.get(f"/projects/{pid}").json()["updatedAt"]
    assert (
        account_a.api.patch(
            f"/projects/{pid}",
            json={**project_payload(pid, name="LWW-변경-1"), "baseUpdatedAt": baseline},
        ).status_code
        == 200
    )

    refreshed = account_a.api.get(f"/projects/{pid}").json()["updatedAt"]
    retried = account_a.api.patch(
        f"/projects/{pid}",
        json={**project_payload(pid, name="LWW-변경-2"), "baseUpdatedAt": refreshed},
    )

    assert retried.status_code == 200, retried.text
    assert account_a.api.get(f"/projects/{pid}").json()["name"] == "LWW-변경-2"
