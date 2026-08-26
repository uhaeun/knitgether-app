"""TC6 프로젝트 삭제 (UI-28~31). 시트: UI 케이스 탭.

삭제 후 잔존까지 본다. 캐시 잔존 결함(DEF-11) 이력 계열이라 앱 재실행 확인을 붙인다.
기법: 상태 전이
"""
from pages.my_knitting_page import MyKnittingPage
from pages.project_form_page import ProjectFormPage
from pages.workspace_page import WorkspacePage
from support.seed import Seed


def test_ui_28_delete_from_edit_form_with_cancel(kg):
    """UI-28 수정 폼 경로. 확인창에서 취소가 진짜 취소인지까지 본다."""
    s = Seed(); s.project("폼삭제대상")
    kg.launch(s)
    lst, ws, form = kg.page(MyKnittingPage).open(), kg.page(WorkspacePage), kg.page(ProjectFormPage)

    lst.open_project("폼삭제대상")
    ws.open_edit_form()
    form.tap_delete()
    form.cancel_delete()
    form.cancel()
    ws.go_back()
    assert lst.has_project("폼삭제대상"), "취소했는데 프로젝트가 사라짐"

    lst.open_project("폼삭제대상")
    ws.open_edit_form()
    form.tap_delete()
    form.confirm_delete()
    assert not lst.has_project("폼삭제대상"), "승인했는데 목록에 남음"

    kg.relaunch()
    assert not lst.open().has_project("폼삭제대상"), "재실행 후 삭제한 프로젝트가 돌아옴"


def test_ui_29_delete_via_long_press(kg):
    """UI-29 롱프레스 메뉴 경로."""
    s = Seed(); s.project("롱프레스삭제")
    kg.launch(s)
    lst = kg.page(MyKnittingPage).open()

    lst.long_press_menu("롱프레스삭제", "삭제")
    lst.confirm_delete()

    assert not lst.has_project("롱프레스삭제")


def test_ui_30_delete_via_swipe(kg):
    """UI-30 스와이프 액션 경로."""
    s = Seed(); s.project("스와이프삭제")
    kg.launch(s)
    lst = kg.page(MyKnittingPage).open()

    lst.swipe_action("스와이프삭제", "삭제")
    lst.confirm_delete()

    assert not lst.has_project("스와이프삭제")


def test_ui_31_delete_two_of_three_keeps_rest(kg):
    """UI-31 3개 중 2개 연속 삭제. 남은 1개가 재실행 후에도 유지되는지."""
    s = Seed()
    for n in ("격리A", "격리B", "격리C"):
        s.project(n)
    kg.launch(s)
    lst = kg.page(MyKnittingPage).open()

    for n in ("격리A", "격리B"):
        lst.long_press_menu(n, "삭제")
        lst.confirm_delete()

    assert lst.project_names() == ["격리C"], f"남은 목록이 다름: {lst.project_names()}"
    kg.relaunch()
    assert lst.open().project_names() == ["격리C"], "재실행 후 삭제한 항목이 돌아옴"
