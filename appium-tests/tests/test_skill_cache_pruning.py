"""API-22 클라이언트 절반. 서버에서 삭제된 스킬이 창고 스킬 화면에서도 사라지는가 (DEF-09).

서버 절반(삭제된 스킬이 API 응답에서 빠지는가)은 qa/api-tests/test_14_skill_soft_delete.py가
FULL로 닫았다. 이 파일은 남은 절반, 클라이언트 로컬 캐시가 실제로 프루닝되는지를 본다.

DEF-09 원인 계열: "원격 캐시 갱신 시 제거 없이 병합만 함"(10_defect_catalog.md 3절). 스킬은
`OfflineFirstSkillRepository.fetchSkills()`가 `local.cacheSyncedSkills(remoteSkills,
pruningStaleEntries: true)`를 호출해 서버 목록에 없는 synced 스킬을 로컬에서 제거한다
(`LocalSampleRepositories.swift`, "LINK-03" 주석 — DEF-09 수정이 실제로 여기 있다).
이 fetchSkills는 창고 > 스킬 화면(`SkillLibraryView`)의 `.task`/`.refreshable`에 물려 있다.

주의: 단건 조회(`fetchSkill(id:)`)는 프루닝하지 않는다. 목록 조회(fetchSkills)를 다시
트리거해야 한다.

트리거는 화면 재진입으로 잡는다. 2026-09-03에 pull-to-refresh 제스처만으로 10회를 돌렸을
때 항목이 계속 남아 DEF-09 재발로 보였으나, 화면을 나갔다 들어와 `.task`를 다시 태우자
한 번에 사라졌다. `mobile: swipe` 아래 방향은 단순 스크롤로 끝나는 경우가 있어서 제스처만
쓰면 "프루닝이 안 됐다"와 "조회를 안 했다"가 구분되지 않는다. 판정이 무엇을 보는지 먼저
고정해야 한다는 뜻이고, 실제 판정은 PASS다.

이 케이스의 UI-NN 번호는 09_test_case_master.md에 아직 없다. 번호 배정은 QA(유하은) 몫으로
남긴다.
"""
import time

import pytest

from pages.auth_page import AuthPage
from pages.library_page import LibraryPage
from support import server_api, texts as T

pytestmark = pytest.mark.server

SKILL_NAME = "API22-테스트스킬"


@pytest.fixture(autouse=True)
def _server_up():
    assert server_api.health_ok(), "서버가 떠 있지 않다"


def test_skill_deleted_on_server_is_pruned_from_local_cache(kg_server):
    account = server_api.register(display_name="스킬캐시계정")
    skill_id = server_api.create_skill(account["token"], SKILL_NAME)

    auth, lib = kg_server.page(AuthPage), kg_server.page(LibraryPage)
    auth.open().login(account["email"], account["password"])
    lib.open(section=T.LIB_SKILL)

    # 판정은 화면에 보이는 항목이 아니라 스크롤해서 찾은 결과로 한다. 스킬 목록은 시스템
    # 스킬을 포함해 40건이 넘어서, 보이는 것만 읽으면 새로 만든 항목이 화면 밖이라는 이유로
    # "없다"가 나온다. 특히 삭제 후 단언에서 이 구분이 없으면 항목이 아래에 그대로 남아
    # 있어도 통과하는 공허한 판정이 된다.
    # 사전조건: 삭제 전에 로컬 화면에 스킬이 실제로 동기화돼 보여야 한다.
    # 이게 안 뜨면 뒤의 "사라졌다"는 판정이 애초에 있지도 않았던 것과 구분이 안 된다.
    synced = False
    deadline = time.time() + 30
    while time.time() < deadline:
        if lib.has_item(SKILL_NAME):
            synced = True
            break
        lib.pull_to_refresh()
    assert synced, "사전조건 실패: 생성한 스킬이 창고 화면에 동기화되지 않았다"

    server_api.delete_skill(account["token"], skill_id)

    pruned = False
    for _ in range(5):
        # 목록 조회를 확실히 다시 태운다. pull-to-refresh 제스처만 쓰면 스와이프가 단순
        # 스크롤로 끝났을 때와 프루닝이 동작하지 않을 때가 구분되지 않는다. 화면을 나갔다
        # 들어오면 SkillLibraryView의 .task가 다시 돌아 fetchSkills를 반드시 거친다.
        lib.open(section=T.LIB_YARN)
        lib.open(section=T.LIB_SKILL)
        if not lib.has_item(SKILL_NAME):
            pruned = True
            break
        lib.pull_to_refresh()

    assert pruned, "서버에서 삭제된 스킬이 창고 로컬 캐시에 계속 남아 있다 (DEF-09 재발)"
