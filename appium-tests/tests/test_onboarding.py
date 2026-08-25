# UI-01. 온보딩 6페이지 완주 후 메인 페이지 확인 (설계: 케이스 시트 UI-01)
# Given 초기 상태(첫 실행) / When 6페이지 완주 / Then 메인 하단 탭바 표시
#
# 실행: ./.venv/bin/python -m pytest tests/test_onboarding.py -v

from pages.onboarding_page import OnboardingPage


def test_onboarding_full_journey(fresh_driver):
    page = OnboardingPage(fresh_driver)
    display_name = "자동화니터"

    # ---------- 여기부터 하은 작성 영역 (시트 UI-01 스텝을 페이지 메서드 호출로) ----------

    # TODO 1. [다음] 클릭 (1페이지 → 2페이지)
    page.tap_next()

    # TODO 2. [다음] 클릭 (2 → 3)
    page.tap_next() 
    
    # TODO 3-1. 이름 입력
    
    page.enter_name(display_name)

    # TODO 3-2. [다음] 클릭 (3 → 4)
    page.tap_next()
    
    # TODO 4. [다음] 클릭 (4 → 5)
    page.tap_next()
        
    # TODO 5. [다음] 클릭 (5 → 6)
    page.tap_next()
    
    # TODO 6-1. 마지막 페이지에 display_name 표시 확인 (assert page.is_name_shown(...))
    assert page.is_name_shown(display_name)
    
    # TODO 6-2. [시작] 클릭
    page.tap_start()
    
    # TODO 7. 메인 도달 확인 (assert page.is_main_page_shown())
    assert page.is_main_page_shown()
    # ---------- 하은 작성 영역 끝 ----------
