"""TC14 등록 항목 삭제 (UI-73~76). 시트: UI 케이스 탭.

연결된 항목을 지웠을 때 프로젝트 쪽 스냅샷이 살아남는지가 핵심이다(LINK-05).
도안은 ProjectPatternCopy 복사본 구조라 창고 원본을 지워도 열람이 되어야 한다.
기법: 상태 전이
"""
from pages.library_page import LibraryPage
from pages.my_knitting_page import MyKnittingPage
from pages.pattern_panel_page import PatternPanelPage
from pages.project_info_page import ProjectInfoPage
from pages.workspace_page import WorkspacePage
from support import texts as T
from support.seed import Seed


def _info(kg, project):
    lst, ws, info = kg.page(MyKnittingPage), kg.page(WorkspacePage), kg.page(ProjectInfoPage)
    lst.open().open_project(project)
    ws.show_info_tab()
    return info


def test_ui_73_delete_unlinked_yarn(kg):
    """UI-73 어느 프로젝트에도 연결되지 않은 실 삭제. 재실행 후에도 돌아오지 않아야 한다."""
    s = Seed(); s.yarn("미연결실")
    kg.launch(s)
    lib = kg.page(LibraryPage).open(T.LIB_YARN)

    lib.delete("library.yarn", "미연결실", T.DELETE_YARN_TITLE)
    assert "미연결실" not in lib.item_names("library.yarn"), "삭제했는데 목록에 남음"

    kg.relaunch()
    lib.open(T.LIB_YARN)
    assert "미연결실" not in lib.item_names("library.yarn"), "재실행 후 삭제한 실이 돌아옴"


def test_ui_74_delete_linked_yarn_keeps_snapshot(kg):
    """UI-74 연결된 실을 창고에서 지워도 프로젝트 쪽 스냅샷 표시는 남아야 한다."""
    s = Seed(); y = s.yarn("연결된실"); s.project("스냅샷보존", yarn=y)
    kg.launch(s)
    lib = kg.page(LibraryPage).open(T.LIB_YARN)

    lib.delete("library.yarn", "연결된실", T.DELETE_YARN_TITLE)
    assert "연결된실" not in lib.item_names("library.yarn"), "창고에서 삭제되지 않음"

    info = _info(kg, "스냅샷보존")
    assert info.shows("연결된실"), "원본을 지웠더니 프로젝트 스냅샷까지 사라짐"


def test_ui_75_delete_linked_needle_and_tool(kg):
    """UI-75 연결된 바늘과 도구를 지웠을 때의 동작.

    바늘은 스냅샷이라 프로젝트 표시가 남고, 도구는 링크 구조라 표시가 사라진다(schema 실측).
    """
    s = Seed()
    n = s.needle("연결된바늘"); t = s.tool("연결된도구")
    s.project("삭제영향", needle=n, tools=[t])
    kg.launch(s)
    lib = kg.page(LibraryPage)

    lib.open(T.LIB_NEEDLE).delete("library.needle", "연결된바늘", "바늘을 삭제할까요?")
    lib.open(T.LIB_TOOL).delete("library.tool", "연결된도구", "도구를 삭제할까요?")

    info = _info(kg, "삭제영향")
    assert info.shows("연결된바늘"), "바늘 스냅샷이 사라짐"
    assert not info.has_text("연결된도구", timeout=2), "도구는 참조라 표시가 사라져야 한다"


def test_ui_76_delete_library_pattern_keeps_project_copy(kg):
    """UI-76 창고 도안을 지워도 프로젝트에 복사된 도안은 그대로 열람돼야 한다.

    ProjectPatternCopy 복사본 구조(schema 실측). 이게 깨지면 도안 열람 불가(치명도 5위)다.
    """
    s = Seed(); s.project("복사본유지", pattern="복사본도안", pdf="sample4.pdf")
    kg.launch(s)
    lib, pat = kg.page(LibraryPage), kg.page(PatternPanelPage)
    lst, ws = kg.page(MyKnittingPage), kg.page(WorkspacePage)

    lib.open(T.LIB_PATTERN)
    # 저장 파일을 지우면 앱이 샘플 도안을 다시 심는다. 그 시딩이 끝나기 전에 읽으면 목록이 비어 있다.
    assert lib.wait_for_rows("library.pattern"), "창고에 샘플 도안이 나타나지 않음"
    target = lib.item_names("library.pattern")[0]
    lib.delete_by_swipe(target, "도안을 삭제할까요?")
    assert target not in lib.item_names("library.pattern"), "창고에서 삭제되지 않음"

    lst.open().open_project("복사본유지")
    ws.show_working_tab()
    assert not pat.is_empty(), "창고 원본을 지웠더니 프로젝트 도안까지 사라짐"
