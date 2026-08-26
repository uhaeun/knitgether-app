"""온보딩 화면.

[다음]과 [시작]은 같은 위치의 버튼이 마지막 페이지에서만 식별자가 바뀐다.
이름 입력칸은 식별자가 없어 화면에 하나뿐인 텍스트 필드로 잡는다.
"""
import time

from support import texts as T

from .base_page import ID, PRED, BasePage


class OnboardingPage(BasePage):

    def tap_next(self):
        self.tap("onboarding.start")
        time.sleep(0.8)

    def enter_name(self, name):
        field = self.find('type == "XCUIElementTypeTextField"', PRED)
        field.clear()
        field.send_keys(name)

    def is_name_shown(self, name):
        return self.has_text(name)

    def tap_start(self):
        """시작 버튼. 식별자와 겉보기 글자를 번갈아 시도하며 메인 도착까지 확인한다."""
        for locator, by in ((", ".join(["onboarding.complete"]), ID),
                            (self.button("시작"), PRED),
                            ('label CONTAINS "시작"', PRED)):
            for _ in range(2):
                els = self._all(locator, by)
                if not els:
                    break
                self.tap_at(els[0])
                for _ in range(10):
                    if self.is_main_page_shown():
                        return
                    time.sleep(0.5)
        raise AssertionError("온보딩 완료 후 메인에 도달하지 못함. "
                             f"화면 텍스트: {[t for t in self.texts() if t][:8]}")

    def is_main_page_shown(self):
        return self.exists(self.button("내 뜨개"), PRED, timeout=1)
