"""TC11 재방문 보존 (UI-64). 시트: UI 케이스 탭.

CUJ-2 계열 P1. 작업 재개가 이 제품의 핵심 가치라 종료 전 상태가 그대로 살아 있어야 한다.
기법: 상태 전이, 시나리오
"""
from pages.counter_panel_page import CounterPanelPage
from pages.my_knitting_page import MyKnittingPage
from pages.pattern_panel_page import PatternPanelPage
from pages.project_info_page import ProjectInfoPage
from pages.workspace_page import WorkspacePage
from support import texts as T
from support.seed import Seed


def test_ui_64_state_survives_app_restart(kg):
    """UI-64 앱 완전 종료 후 재실행해도 카운터, 도안, 재료 연결이 유지되는지.

    홈의 '이어서 뜨기' 경로는 DEF-17로 미동작이라 목록 경로로 검증한다.
    """
    s = Seed()
    y = s.yarn("보존실")
    s.project("보존검증", pattern="보존도안", pdf="sample4.pdf", yarn=y)
    kg.launch(s)
    lst, ws = kg.page(MyKnittingPage).open(), kg.page(WorkspacePage)
    counter, pat, info = (kg.page(CounterPanelPage), kg.page(PatternPanelPage),
                          kg.page(ProjectInfoPage))

    # 단수는 시딩하지 않고 화면에서 직접 올린다. 시딩해두면 "표시되는가"만 보게 되고
    # 저장 경로를 통째로 들어내도 통과한다(음성 대조에서 실측).
    lst.open_project("보존검증")
    counter.open().next_row(3)
    assert counter.current_text() == T.COUNTER_CURRENT.format(3)

    kg.relaunch()
    lst.open().open_project("보존검증")

    assert counter.open().current_text() == T.COUNTER_CURRENT.format(3), "카운터 값이 유지되지 않음"
    ws.show_working_tab()
    assert not pat.is_empty(), "도안 연결이 유지되지 않음"
    ws.show_info_tab()
    assert info.shows("보존실"), "실 연결 표시가 유지되지 않음"
