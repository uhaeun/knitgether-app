"""TC9 프로젝트 즐겨찾기 (UI-37~38). 시트: UI 케이스 탭.

토글 상태의 보존과 상단 고정을 본다. 별 아이콘은 표시 전용이고 토글 입구는 수정 폼 단일이다.
기법: 상태 전이
"""
import pytest

from pages.my_knitting_page import MyKnittingPage
from pages.project_form_page import ProjectFormPage
from pages.work_time_panel_page import WorkTimePanelPage
from pages.workspace_page import WorkspacePage
from support import texts as T
from support.seed import Seed, ts


def test_ui_37_favorite_pins_to_top(kg):
    """UI-37 즐겨찾기를 켜면 별이 채워지고 최상단으로 이동, 재실행 후 유지, 끄면 원위치.

    1차 판정 이력: PASS (8/23 수동)
    """
    s = Seed()
    s.project("최신건", started=ts(days_ago=1))
    s.project("아래건", started=ts(days_ago=9))
    kg.launch(s)
    lst, form = kg.page(MyKnittingPage).open(), kg.page(ProjectFormPage)

    lst.long_press_menu("아래건", T.EDIT)
    form.toggle_favorite().save()

    assert lst.project_names()[0] == "아래건", "즐겨찾기가 최상단으로 오지 않음"
    assert "즐겨찾기 아님" not in lst.row_summary("아래건"), "별이 채워지지 않음"
    kg.relaunch()
    assert lst.open().project_names()[0] == "아래건", "재실행 후 고정이 풀림"

    lst.long_press_menu("아래건", T.EDIT)
    form.toggle_favorite().save()
    assert lst.project_names()[0] == "최신건", "해제 후 원래 정렬로 돌아오지 않음"


def test_ui_38_order_inside_favorite_group(kg):
    """UI-38 즐겨찾기 그룹 안에서도 마지막에 작업한 쪽이 위.

    기법: 상태 전이, 회귀
    """
    s = Seed(); s.project("즐겨A", favorite=True); s.project("즐겨B", favorite=True)
    kg.launch(s)
    lst, ws = kg.page(MyKnittingPage).open(), kg.page(WorkspacePage)

    for first, second in (("즐겨A", "즐겨A"), ("즐겨B", "즐겨B")):
        lst.open().open_project(first)
        kg.page(WorkTimePanelPage).record_session()
        ws.go_back()
        assert lst.open().project_names()[0] == second, f"{second}가 그룹 최상단이 아님"
