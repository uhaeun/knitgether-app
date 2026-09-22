"""TC13 등록 항목 수정 (UI-70~72). 시트: UI 케이스 탭.

LINK-05(연결 스냅샷 불변, 원본 수정 비전파)의 회귀 확인이 핵심이다.
실과 바늘은 스냅샷이라 원본을 고쳐도 프로젝트 쪽이 그대로여야 하고,
도구는 링크 구조(N:M)라 동작이 다를 수 있다.
기법: 상태 전이
"""
from pages.library_page import LibraryPage
from pages.my_knitting_page import MyKnittingPage
from pages.project_info_page import ProjectInfoPage
from pages.workspace_page import WorkspacePage
from support import texts as T
from support.seed import Seed


def _check_info(kg, project):
    lst, ws, info = kg.page(MyKnittingPage), kg.page(WorkspacePage), kg.page(ProjectInfoPage)
    lst.open().open_project(project)
    ws.show_info_tab()
    return info


def test_ui_70_yarn_edit_does_not_propagate(kg):
    """UI-70 창고에서 실 이름을 바꿔도 프로젝트 쪽 스냅샷은 그대로여야 한다."""
    s = Seed(); y = s.yarn("원본실"); s.project("스냅샷실", yarn=y)
    kg.launch(s)
    lib = kg.page(LibraryPage)

    lib.open(T.LIB_YARN).edit("library.yarn", "원본실", {"name": "바뀐실"})
    assert lib.wait_for_item("library.yarn", "바뀐실"), "창고 목록에 변경된 이름이 없음"

    info = _check_info(kg, "스냅샷실")
    assert info.shows("원본실"), "프로젝트 쪽 스냅샷이 원본 수정에 끌려감"


def test_ui_71_needle_edit_does_not_propagate(kg):
    """UI-71 바늘도 같은 구조. 창고는 갱신되고 프로젝트 스냅샷은 불변."""
    s = Seed(); n = s.needle("원본바늘"); s.project("스냅샷바늘", needle=n)
    kg.launch(s)
    lib = kg.page(LibraryPage)

    lib.open(T.LIB_NEEDLE).edit("library.needle", "원본바늘", {"name": "바뀐바늘"})
    assert lib.wait_for_item("library.needle", "바뀐바늘"), "창고 목록에 변경된 이름이 없음"

    info = _check_info(kg, "스냅샷바늘")
    assert info.shows("원본바늘"), "프로젝트 쪽 스냅샷이 원본 수정에 끌려감"


def test_ui_72_tool_edit_propagates(kg):
    """UI-72 도구는 링크 구조라 스냅샷이 없다. 원본을 고치면 프로젝트 표시도 따라간다.

    실, 바늘과 동작이 다른 지점이라 시트의 "관찰 후 확정"을 여기서 확정한다.
    """
    s = Seed(); t = s.tool("원본도구"); s.project("도구수정", tools=[t])
    kg.launch(s)
    lib = kg.page(LibraryPage)

    lib.open(T.LIB_TOOL).edit("library.tool", "원본도구", {"name": "바뀐도구"})
    assert lib.wait_for_item("library.tool", "바뀐도구"), "창고 목록에 변경된 이름이 없음"

    info = _check_info(kg, "도구수정")
    assert info.shows("바뀐도구"), "도구는 참조 구조라 프로젝트 표시도 따라가야 한다"
