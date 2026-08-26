"""TC10c 작업 화면 - 프로젝트 정보 탭 (UI-56~63). 시트: UI 케이스 탭 TC10.

요약 표시와 연결 항목 표시가 중심이다. 등록과 수정은 창고 TC가 담당하고 여기서는 표시만 본다.
"""
import time

import pytest

from pages.my_knitting_page import MyKnittingPage
from pages.project_info_page import ProjectInfoPage
from pages.workspace_page import WorkspacePage
from support import texts as T
from support.seed import Seed, ts


def _open_info(kg, name, seed):
    kg.launch(seed)
    lst, ws, info = kg.page(MyKnittingPage), kg.page(WorkspacePage), kg.page(ProjectInfoPage)
    lst.open().open_project(name)
    ws.show_info_tab()
    return lst, ws, info


def test_ui_56_summary_matches_actual_values(kg):
    """UI-56 요약 4항목이 실제 값과 일치하는지. 기법: 시나리오"""
    s = Seed()
    s.project("요약대상", current_row=7, target_row=20, sessions=2, target_date=ts(days_ago=-5))
    _, _, info = _open_info(kg, "요약대상", s)

    assert info.summary(T.INFO_PROGRESS) == "7 / 20단", info.summary(T.INFO_PROGRESS)
    assert info.summary(T.INFO_SCHEDULE) == "D-5", info.summary(T.INFO_SCHEDULE)
    assert info.summary(T.INFO_TOTAL_TIME) == "1시간 0분", info.summary(T.INFO_TOTAL_TIME)
    assert info.summary(T.START_DATE), "시작일이 비어 있음"


def test_ui_58_linked_yarn_shown(kg):
    """UI-58 연결된 실 이름이 정보 탭에 표시되는지. 기법: 시나리오"""
    s = Seed(); y = s.yarn("표시용실"); s.project("실표시", yarn=y)
    _, _, info = _open_info(kg, "실표시", s)

    assert info.section_shown(T.INFO_YARN_USAGE), "실 사용량 섹션이 없음"
    assert info.shows("표시용실"), "연결된 실 이름이 보이지 않음"


def test_ui_59_linked_needle_shown(kg):
    """UI-59 연결된 바늘 이름이 정보 탭에 표시되는지. 기법: 시나리오"""
    s = Seed(); n = s.needle("표시용바늘"); s.project("바늘표시", needle=n)
    _, _, info = _open_info(kg, "바늘표시", s)

    assert info.section_shown(T.INFO_NEEDLE), "사용 바늘 섹션이 없음"
    assert info.shows("표시용바늘"), "연결된 바늘 이름이 보이지 않음"


def test_ui_60_linked_tool_shown(kg):
    """UI-60 연결된 도구 이름이 정보 탭에 표시되는지.

    도구는 N:M 링크 구조라(schema 실측) 실, 바늘과 연결 방식이 다르다. 기법: 시나리오
    """
    s = Seed(); t = s.tool("표시용도구"); s.project("도구표시", tools=[t])
    _, _, info = _open_info(kg, "도구표시", s)

    assert info.section_shown(T.INFO_TOOL), "사용 도구 섹션이 없음"
    assert info.shows("표시용도구"), "연결된 도구 이름이 보이지 않음"


def test_ui_62_work_memo_saved_and_persists(kg):
    """UI-62 작업 메모를 저장하면 표시되고 재실행 후에도 남는지. 기법: 시나리오"""
    s = Seed(); s.project("메모대상")
    lst, ws, info = _open_info(kg, "메모대상", s)
    memo = "다음 세션에 소매부터"

    info.save_memo(memo)
    time.sleep(1.5)
    assert info.memo_value() == memo, f"저장 직후 메모가 다름: {info.memo_value()}"

    kg.relaunch()
    lst.open().open_project("메모대상")
    ws.show_info_tab()
    assert info.memo_value() == memo, f"재실행 후 메모가 사라짐: {info.memo_value()}"


def test_ui_61_gauge_record_link_and_unlink(kg):
    """UI-61 게이지 기록을 프로젝트에 연결했다 해제한다.

    코드 확인 결과 작성이 아니라 연결 구조다. 해제해도 원본 기록은 남고 연결만 끊긴다.
    기법: 상태 전이
    """
    s = Seed(); s.gauge_record(); s.project("게이지대상")
    _, _, info = _open_info(kg, "게이지대상", s)

    assert info.shows("0개 연결됨"), "사전 조건: 연결된 기록이 없어야 한다"

    info.link_gauge("세탁 전")
    assert info.shows("1개 연결됨"), "연결 후 표시가 갱신되지 않음"

    info.unlink_gauge()
    assert info.shows("0개 연결됨"), "해제 후 표시가 갱신되지 않음"

    assert info.gauge_picker_has("세탁 전"), "해제했더니 게이지 계산기의 원본 기록까지 사라짐"


def test_ui_57_progress_photo(kg):
    """UI-57 진행 사진을 추가하면 목록에 표시되고 재실행 후에도 남는지.

    시뮬레이터 사진 라이브러리는 simctl addmedia로 미리 채운다. 기법: 시나리오
    """
    from support import simctl
    simctl.add_photo("/Users/yuha/Desktop/Projects/KnitGether/docs/qa/portfolio/"
                     "evidence/0727_manual_verification/01_home.png")

    s = Seed(); s.project("사진대상")
    lst, ws, info = _open_info(kg, "사진대상", s)
    assert info.shows("아직 진행 사진이 없어요."), "사전 조건: 진행 사진이 없어야 한다"

    info.add_progress_photo()

    assert not info.has_text("아직 진행 사진이 없어요.", timeout=3), "사진이 추가되지 않음"
    kg.relaunch()
    lst.open().open_project("사진대상")
    ws.show_info_tab()
    assert not info.has_text("아직 진행 사진이 없어요.", timeout=3), "재실행 후 사진이 사라짐"


def test_ui_63_related_skills_shown_and_navigable(kg):
    """UI-63 관련 스킬 태그가 표시되고 누르면 해당 스킬로 이동하는지.

    스킬은 앱이 첫 실행에 심는 카탈로그를 쓴다. 그 ID를 알아야 프로젝트에 연결할 수 있어
    한 번 띄워 skills.json을 읽은 뒤 다시 시딩한다. 기법: 시나리오
    """
    from support import simctl
    kg.launch(Seed())
    skills = simctl.read_store("skills.json")
    assert skills, "앱이 심은 스킬 카탈로그가 없다"
    skill = skills[0]

    s = Seed(); s.project("스킬표시", skills=[skill["id"]])
    lst, ws, info = _open_info(kg, "스킬표시", s)

    assert info.section_shown(T.INFO_SKILLS), "관련 스킬 섹션이 없음"
    assert info.shows(skill["name"]), f"연결한 스킬 이름이 보이지 않음: {skill['name']}"

    info.tap_row(skill["name"])
    time.sleep(2)
    assert info.has_text(skill["name"]), "스킬 태그를 눌렀는데 스킬 화면으로 가지 않음"
