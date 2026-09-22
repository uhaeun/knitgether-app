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
    """UI-55 직접 입력 경계값. 큰 값과 0은 반영되고 음수는 0으로 보정된다.

    음수 무통보 보정은 06 관찰 이력이고 상한은 명세가 없다. 기법: 경계값
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

    counter.set_current(-5)
    assert counter.current_text() == T.COUNTER_START, "음수가 0으로 보정되지 않음"
