"""TC12 실 바늘 도구 등록 (UI-65~69). 시트: UI 케이스 탭.

창고 기본 CRUD와 프로젝트 연결. 등록 폼은 미입력 검증부터 본다.
기법: 시나리오, 에러 기대
"""
from pages.library_page import LibraryPage
from pages.my_knitting_page import MyKnittingPage
from pages.project_form_page import ProjectFormPage
from pages.project_info_page import ProjectInfoPage
from pages.workspace_page import WorkspacePage
from support import texts as T
from support.seed import Seed


def _register(kg, section, prefix, fields, name):
    kg.launch(Seed())
    lib = kg.page(LibraryPage).open(section)
    lib.open_form(prefix)
    assert not lib.save_enabled(prefix), "미입력인데 저장이 활성"
    lib.fill_and_save(prefix, fields)
    assert lib.wait_for_item(prefix, name), f"등록한 항목이 목록에 없음: {name}"
    kg.relaunch()
    lib.open(section)
    assert lib.wait_for_item(prefix, name), "재실행 후 등록 항목이 사라짐"


def test_ui_65_register_yarn(kg):
    """UI-65 실 등록. 미입력 시 저장 비활성, 등록 후 목록 표시와 재실행 유지."""
    _register(kg, T.LIB_YARN, "library.yarn",
              {"name": "신규실", "brand": "테스트브랜드"}, "신규실")


def test_ui_66_register_needle(kg):
    """UI-66 바늘 등록. 이름, 종류, 사이즈가 필수다(폼 실측). UI-65와 같은 구조."""
    _register(kg, T.LIB_NEEDLE, "library.needle",
              {"name": "신규바늘", "type": "Circular", "size": "4.0 mm"}, "신규바늘")


def test_ui_67_register_tool(kg):
    """UI-67 도구 등록. 이름과 종류가 필수다(폼 실측). UI-65와 같은 구조."""
    _register(kg, T.LIB_TOOL, "library.tool",
              {"name": "신규도구", "type": "마커"}, "신규도구")


def test_ui_68_link_and_unlink_yarn_and_needle(kg):
    """UI-68 수정 폼에서 실과 바늘을 연결했다 해제한다. 창고 원본은 그대로여야 한다.

    기법: 상태 전이
    """
    s = Seed(); y = s.yarn("연결실"); n = s.needle("연결바늘"); s.project("재료연결")
    kg.launch(s)
    lst, form = kg.page(MyKnittingPage).open(), kg.page(ProjectFormPage)
    ws, info, lib = kg.page(WorkspacePage), kg.page(ProjectInfoPage), kg.page(LibraryPage)

    lst.long_press_menu("재료연결", T.EDIT)
    form.select_yarn("연결실")
    form.select_needle("연결바늘")
    form.save()

    lst.open_project("재료연결")
    ws.show_info_tab()
    assert info.shows("연결실") and info.shows("연결바늘"), "연결한 재료가 정보 탭에 없음"

    ws.go_back()
    lst.long_press_menu("재료연결", T.EDIT)
    form.clear_yarn()
    form.clear_needle()
    form.save()

    lst.open_project("재료연결")
    ws.show_info_tab()
    assert not info.has_text("연결실", timeout=2), "해제했는데 실 표시가 남음"
    ws.go_back()
    assert lib.open(T.LIB_YARN).wait_for_item("library.yarn", "연결실"), "창고 원본이 사라짐"


def test_ui_69_link_and_unlink_tool(kg):
    """UI-69 작업 화면에서 도구를 연결했다 해제한다.

    도구는 N:M 링크라(schema 실측) 연결 입구가 재료와 다르다. 기법: 상태 전이
    """
    s = Seed(); t = s.tool("연결도구"); s.project("도구연결")
    kg.launch(s)
    lst, ws, info, lib = (kg.page(MyKnittingPage).open(), kg.page(WorkspacePage),
                          kg.page(ProjectInfoPage), kg.page(LibraryPage))

    lst.open_project("도구연결")
    ws.show_info_tab()
    info.link_tool("연결도구")
    assert info.shows("연결도구"), "연결한 도구가 표시되지 않음"

    info.unlink_tool("연결도구")
    assert not info.has_text("연결도구", timeout=2), "해제했는데 도구 표시가 남음"

    ws.go_back()
    assert lib.open(T.LIB_TOOL).wait_for_item("library.tool", "연결도구"), "창고 원본이 사라짐"
