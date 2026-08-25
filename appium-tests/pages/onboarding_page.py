# 온보딩 화면 페이지 객체
#
# 이름표 지도:
#   [다음] 버튼 = "onboarding.start" (모든 페이지에서 같은 이름표)
#   이름 입력칸 = 이름표 없음 → self.text_field() 사용 (BasePage 제공)
#   [시작] 버튼 (마지막 페이지) = "onboarding.complete"

from pages.base_page import BasePage


class OnboardingPage(BasePage):

    def tap_next(self):
        """[다음] 버튼 한 번 탭."""
        self.tap("onboarding.start")
        

    def enter_name(self, name):
        # 이름 입력칸의 기본값을 지우고 이름 입력
        field = self.text_field()
        field.clear()
        field.send_keys(name)

    def is_name_shown(self, name):
        """마지막 페이지에 {name} 글자가 표시되는지 (True/False 반환)."""
        return self.contains_text(name)
        
    def tap_start(self):
        """[시작] 버튼 탭 → 온보딩 완료."""
        self.tap("onboarding.complete")

    def is_main_page_shown(self):
        """메인 도달 판정: 하단 탭 '내 뜨개'가 보이는지 (True/False)."""
        return self.label_exists("내 뜨개")