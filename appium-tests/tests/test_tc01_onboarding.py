"""TC1 온보딩 (UI-01). 시트: UI 케이스 탭.

모든 신규 사용자가 반드시 지나는 첫 관문인데, 기존 자동화는 launch argument로 온보딩을
건너뛰도록 설계돼 있어 사각지대였다. 초기 상태가 필요해 이 케이스만 앱을 지우고 다시 깐다.
기법: 시나리오
"""
from pages.onboarding_page import OnboardingPage

DISPLAY_NAME = "자동화니터"


def test_ui_01_complete_six_pages(onboarding):
    """UI-01 온보딩 6페이지를 완주하면 메인 하단 탭바가 보이는지."""
    page = OnboardingPage(onboarding.driver)

    page.tap_next()                       # 1 → 2
    page.tap_next()                       # 2 → 3
    page.enter_name(DISPLAY_NAME)
    page.tap_next()                       # 3 → 4
    page.tap_next()                       # 4 → 5
    page.tap_next()                       # 5 → 6

    assert page.is_name_shown(DISPLAY_NAME), "마지막 페이지에 입력한 이름이 없음"
    page.tap_start()
    assert page.is_main_page_shown(), "온보딩을 끝냈는데 메인에 도달하지 못함"
