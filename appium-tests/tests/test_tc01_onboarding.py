"""TC1 온보딩 (UI-01). 시트: UI 케이스 탭.

모든 신규 사용자가 반드시 지나는 첫 관문인데, 기존 자동화는 launch argument로 온보딩을
건너뛰도록 설계돼 있어 사각지대였다. 초기 상태가 필요해 이 케이스만 앱을 지우고 다시 깐다.
기법: 시나리오
"""
from pages.onboarding_page import OnboardingPage

DISPLAY_NAME = "자동화니터"


def test_ui_01_complete_five_pages(onboarding):
    """UI-01 온보딩 5페이지를 완주하면 메인 하단 탭바가 보이는지.

    단위 선택 단계는 2026-09-06에 제거됐다(DEF-26, DEF-29). Metric과 US, Imperial 중
    무엇을 골라도 앱 동작이 같았고, 게이지 계산기와 상세 측정 어디에도 그 값을 읽는 코드가
    없었다. 선택지만 있고 효과가 없는 설정이라 없애고 cm로 고정했다.
    """
    page = OnboardingPage(onboarding.driver)

    page.tap_next()                       # 1 → 2
    page.tap_next()                       # 2 → 3
    page.enter_name(DISPLAY_NAME)
    page.tap_next()                       # 3 → 4
    page.tap_next()                       # 4 → 5

    assert page.is_name_shown(DISPLAY_NAME), "마지막 페이지에 입력한 이름이 없음"
    page.tap_start()
    assert page.is_main_page_shown(), "온보딩을 끝냈는데 메인에 도달하지 못함"
