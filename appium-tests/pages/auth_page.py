"""설정 탭의 계정 연동 화면.

이메일, 비밀번호, 표시 이름, 제출, 로그아웃에는 식별자가 있다.
로그인/회원가입 모드 전환은 컨테이너에만 식별자가 있어 개별 버튼은 글자로 고른다.
"""
import time

from support import texts as T

from .base_page import ID, PRED, BasePage


class AuthPage(BasePage):

    def open(self):
        self.go_tab("설정")
        self.tap_until("settings.account",
                       lambda: self.exists("auth.submit", timeout=1) or
                               self.exists("auth.logout", timeout=1))
        return self

    def logged_in(self):
        return self.exists("auth.logout", timeout=2)

    def ensure_logged_out(self):
        """이전 테스트가 남긴 세션이 있으면 정리한다. 토큰은 Keychain에 남는다."""
        self.open()
        if self.logged_in():
            self.logout()
        return self

    def select_mode(self, label):
        """로그인 / 회원가입 전환."""
        self.tap_button(label)
        time.sleep(1)
        return self

    def fill(self, email=None, password=None, display_name=None):
        if email is not None:
            self.type_in("auth.email", email)
        if password is not None:
            self.type_in("auth.password", password)
        if display_name is not None and self.exists("auth.display_name", timeout=2):
            self.type_in("auth.display_name", display_name)
        return self

    def submit_enabled(self):
        return self.find("auth.submit").get_attribute("enabled") == "true"

    def submit(self):
        self.tap("auth.submit")
        time.sleep(3)
        return self

    def signup(self, email, password, display_name):
        self.select_mode(T.SIGNUP)
        self.fill(email, password, display_name)
        return self.submit()

    def login(self, email, password):
        self.select_mode(T.LOGIN)
        self.fill(email, password)
        return self.submit()

    def logout(self):
        self.tap("auth.logout")
        if self.exists('type == "XCUIElementTypeAlert"', PRED, timeout=2):
            self.alert_tap(T.LOGOUT)
        time.sleep(2.5)
        return self

    def error_shown(self, fragment):
        return self.has_text(fragment, timeout=6)
