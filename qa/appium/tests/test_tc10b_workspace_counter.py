"""TC10b 작업 화면 - 단수 카운터 (UI-52~55). 시트: UI 케이스 탭 TC10.

카운터 하한은 DEF-15 회귀 이력이라 P1이다. 직접 입력은 경계값으로 본다.
"""
from pages.counter_panel_page import CounterPanelPage
from pages.my_knitting_page import MyKnittingPage
from support import texts as T
from support.seed import Seed


def test_ui_52_simple_mode_increment_and_decrement(kg):
    """UI-52 간편 모드에서 증감이 조작 횟수와 정확히 일치하는지.

    1차 판정 이력: 자동화 완료 (8/22 PASS). 기법: 시나리오
    """
    s = Seed(); s.project("간편모드")
    kg.launch(s)
    lst, counter = kg.page(MyKnittingPage).open(), kg.page(CounterPanelPage)

    lst.open_project("간편모드")
    counter.open()
    assert counter.current_text() == T.COUNTER_START

    counter.next_row(3)
    assert counter.current_text() == T.COUNTER_CURRENT.format(3), \
        f"3회 올렸는데 값이 다름: {counter.current_text()}"

    counter.previous_row(1)
    assert counter.current_text() == T.COUNTER_CURRENT.format(2), \
        f"1회 내렸는데 값이 다름: {counter.current_text()}"


def test_ui_53_row_guide_mode(kg):
    """UI-53 행안내 모드에서 단수와 행 안내가 함께 진행되는지. 기법: 시나리오"""
    s = Seed()
    s.project("행안내", row_guides=("첫 행 안내", "둘째 행 안내", "셋째 행 안내"))
    kg.launch(s)
    lst, counter = kg.page(MyKnittingPage).open(), kg.page(CounterPanelPage)

    lst.open_project("행안내")
    counter.open().select_mode("행안내")
    counter.next_row(1)

    assert counter.current_text() == T.COUNTER_CURRENT.format(1), "단수가 오르지 않음"
    assert counter.has_text("첫 행 안내"), "현재 행의 안내 내용이 보이지 않음"


def test_ui_54_lower_bound_stays_at_start(kg):
    """UI-54 카운터 0(시작 전)에서 감소해도 증가하거나 음수가 되지 않아야 한다.

    DEF-15(0에서 감소가 증가로 오동작) 회귀. 수정 커밋 34f3c00.
    1차 판정 이력: 자동화 완료 (Appium 32.6초, XCUITest 37.3초, CI 게이트 포함)
    기법: 경계값, 회귀
    """
    s = Seed(); s.project("하한경계")
    kg.launch(s)
    lst, counter = kg.page(MyKnittingPage).open(), kg.page(CounterPanelPage)

    lst.open_project("하한경계")
    counter.open()
    assert counter.current_text() == T.COUNTER_START

    counter.previous_row(1)

    assert counter.current_text() == T.COUNTER_START, \
        f"하한에서 감소했더니 값이 변함: {counter.current_text()}"


def test_ui_55_direct_input_boundaries(kg):
    """UI-55 직접 입력 경계값. 10000, 0, 1은 저장되고 재실행 후에도 유지된다.

    2026-11-05 정책 검토: 음수 거절은 별도 케이스에서 25단을 전제로 확인한다.
    """
    s = Seed(); s.project("직접입력")
    kg.launch(s)
    lst, counter = kg.page(MyKnittingPage).open(), kg.page(CounterPanelPage)

    lst.open_project("직접입력")
    counter.open()

    counter.set_current(10000)
    assert counter.current_text() == T.COUNTER_CURRENT.format(10000), \
        f"10000이 반영되지 않음: {counter.current_text()}"

    counter.set_current(0)
    assert counter.current_text() == T.COUNTER_START, "0이 '시작 전'으로 표시되지 않음"

    counter.set_current(1)
    assert counter.current_text() == T.COUNTER_CURRENT.format(1)

    kg.relaunch()
    kg.page(MyKnittingPage).open().open_project("직접입력")
    assert kg.page(CounterPanelPage).open().current_text() == T.COUNTER_CURRENT.format(1)


def test_ui_55_negative_input_preserves_saved_value(kg):
    """25단에서 -1 입력 → 안내·저장 차단 → 취소·재실행 후 25단 유지."""
    s = Seed(); s.project("음수입력보존")
    kg.launch(s)
    kg.page(MyKnittingPage).open().open_project("음수입력보존")
    counter = kg.page(CounterPanelPage).open().set_current(25)

    counter.edit_current(-1)
    assert "음수는 저장할 수 없어요" in counter.number_error()
    assert not counter.number_save_enabled(), "음수 입력인데 저장 버튼이 활성화됨"
    counter.cancel_number()
    assert counter.current_text() == T.COUNTER_CURRENT.format(25)

    kg.relaunch()
    kg.page(MyKnittingPage).open().open_project("음수입력보존")
    assert kg.page(CounterPanelPage).open().current_text() == T.COUNTER_CURRENT.format(25)


def test_ui_55_negative_input_can_be_corrected(kg):
    """같은 입력창에서 -1을 26으로 고치면 오류가 해제되고 26단을 저장한다."""
    s = Seed(); s.project("입력오류복구")
    kg.launch(s)
    kg.page(MyKnittingPage).open().open_project("입력오류복구")
    counter = kg.page(CounterPanelPage).open().set_current(25)

    counter.edit_current(-1)
    assert "음수는 저장할 수 없어요" in counter.number_error()
    assert not counter.number_save_enabled()
    counter.replace_number(26)
    assert counter.number_save_enabled(), "올바른 입력으로 고쳐도 저장할 수 없음"
    counter.save_number().wait_for_current(26)
    assert counter.current_text() == T.COUNTER_CURRENT.format(26)

    kg.relaunch()
    kg.page(MyKnittingPage).open().open_project("입력오류복구")
    assert kg.page(CounterPanelPage).open().current_text() == T.COUNTER_CURRENT.format(26)
