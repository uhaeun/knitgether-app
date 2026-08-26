"""모든 페이지의 공통 부모.

설계 원칙 두 가지.
1. 이동은 반드시 도착까지 확인한다. 탭만 하고 넘어가면 애니메이션이 끝나기 전에 다음 요소를
   찾게 되고, 엉뚱한 화면의 동명 요소를 눌러도 조용히 통과한다. (홈의 '이어서 뜨기' 카드가
   DEF-17로 미동작이라 실제로 이 함정에 빠졌다.)
2. 로케이터 문자열은 페이지 객체 밖으로 새지 않는다. 테스트는 의미 있는 메서드만 부른다.
"""
import time
import unicodedata

from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import StaleElementReferenceException
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

from support import texts as T

ID = AppiumBy.ACCESSIBILITY_ID
PRED = AppiumBy.IOS_PREDICATE

class BasePage:
    TIMEOUT = 12
    SHORT = 3

    def __init__(self, driver):
        self.driver = driver

    # ---------- 찾기 ----------
    def _all(self, value, by=ID):
        return self.driver.find_elements(by, value)

    def find(self, value, by=ID, timeout=TIMEOUT):
        return WebDriverWait(self.driver, timeout).until(
            EC.presence_of_element_located((by, value)))

    def exists(self, value, by=ID, timeout=SHORT):
        end = time.time() + timeout
        while time.time() < end:
            if self._all(value, by):
                return True
            time.sleep(0.25)
        return False

    @staticmethod
    def label_of(element):
        """요소의 label을 NFC로 맞춰 읽는다.

        macOS 파일 시스템은 파일 이름을 NFD로 저장한다. 파일에서 온 한글 문자열은
        눈으로는 같아 보여도 파이썬 리터럴(NFC)과 비교하면 어긋난다.
        """
        return unicodedata.normalize("NFC", element.get_attribute("label") or "")

    def button(self, label):
        """겉보기 글자로 버튼을 잡는다. 식별자 없는 요소가 많아 이 경로를 자주 쓴다."""
        return f'type == "XCUIElementTypeButton" AND label == "{label}"'

    def has_text(self, text, timeout=SHORT):
        """화면 어딘가에 이 글자가 포함된 요소가 있는가."""
        return self.exists(f'label CONTAINS "{text}"', PRED, timeout)

    def texts(self):
        return [self.label_of(e) for e in self._all('type == "XCUIElementTypeStaticText"', PRED)]

    # ---------- 조작 ----------
    def tap(self, value, by=ID, timeout=TIMEOUT):
        self.find(value, by, timeout).click()

    def tap_text(self, label):
        self.tap(f'label == "{label}"', PRED)

    def tap_button(self, label):
        self.tap(self.button(label), PRED)

    def tap_at(self, element):
        """요소의 중심을 좌표로 두드린다.

        컨텍스트 메뉴 항목처럼 오버레이로 뜨는 요소는 element.click()이 조용히 무시된다.
        롱프레스도 같아서, 오버레이 계열은 전부 좌표로 다룬다.
        """
        r = element.rect
        self.driver.execute_script(
            "mobile: tap", {"x": r["x"] + r["width"] // 2, "y": r["y"] + r["height"] // 2})

    def tap_at_locator(self, value, by=ID, tries=4):
        """좌표가 멎은 뒤에 두드린다.

        메뉴가 펼쳐지는 중에 rect를 읽으면 최종 위치와 어긋나서 옆 항목이 눌린다.
        실제로 '사전/스킬 찾기'를 누르려다 'PDF 교체'가 눌린 적이 있다.
        두 번 연속 같은 좌표가 나올 때까지 기다렸다가 누른다.
        """
        for attempt in range(tries):
            try:
                first = self.find(value, by).rect
                time.sleep(0.4)
                element = self.find(value, by)
                if element.rect == first or attempt == tries - 1:
                    self.tap_at(element)
                    return
            except StaleElementReferenceException:
                if attempt == tries - 1:
                    raise
            time.sleep(0.5)

    def tap_row_start(self, element, inset=40):
        """행의 왼쪽 끝을 두드린다.

        시트 안 List의 행은 라벨이 왼쪽 정렬이라 가운데가 히트 영역 밖인 경우가 있다.
        도구 연결과 게이지 연결 피커가 그렇다. 가운데를 누르면 아무 일도 일어나지 않는다.
        """
        r = element.rect
        self.driver.execute_script(
            "mobile: tap", {"x": r["x"] + inset, "y": r["y"] + r["height"] // 2})

    def tap_until(self, value, until, by=ID, tries=3):
        """누르고 도착을 확인한다. 안 되면 다시 누른다.

        until: 도착했는지 판정하는 무인자 함수.
        """
        for _ in range(tries):
            self.tap(value, by)
            end = time.time() + self.TIMEOUT
            while time.time() < end:
                if until():
                    return
                time.sleep(0.25)
        raise AssertionError(f"이동 실패: {value}")

    def type_in(self, value, text, by=ID, clear=True):
        field = self.find(value, by)
        if clear:
            field.clear()
        field.send_keys(text)

    # ---------- 탭바 ----------
    def go_tab(self, name):
        """하단 탭 이동.

        상세 화면은 탭바를 덮으므로 탭 버튼이 없으면 먼저 뒤로 나온다.
        탭 버튼만 정확히 겨냥하고 도착 문구까지 확인한다.
        """
        landmark = T.TAB_LANDMARK[name]
        if self.has_text(landmark, timeout=1):
            return
        for _ in range(3):
            if self.exists(self.button(name), PRED, timeout=1):
                break
            if not self.leave_screen():
                break
            time.sleep(0.8)
        self.tap_until(self.button(name), lambda: self.has_text(landmark, 1), PRED)

    # ---------- 확인창 ----------
    def alert_shown(self, title, timeout=TIMEOUT):
        return self.exists(f'type == "XCUIElementTypeAlert" AND label == "{title}"', PRED, timeout)

    def alert_tap(self, label):
        """확인창 버튼. 본문 버튼과 같은 이름이 흔해서 알럿 안으로 범위를 좁힌다."""
        alert = self.find('type == "XCUIElementTypeAlert"', PRED)
        alert.find_element(PRED, f'label == "{label}"').click()

    # ---------- 목록 행 ----------
    def row(self, name):
        return f'label CONTAINS "{name}"'

    def tap_row(self, name):
        self.tap(self.row(name), PRED)

    def long_press_element(self, element, expect):
        """이미 찾아둔 요소를 길게 누른다."""
        r = element.rect
        self.driver.execute_script("mobile: touchAndHold", {
            "x": r["x"] + r["width"] // 2, "y": r["y"] + r["height"] // 2, "duration": 1.2})
        assert self.exists(self.button(expect), PRED, self.TIMEOUT), \
            f"롱프레스 메뉴에 '{expect}'가 없음"

    def long_press_row(self, name, expect):
        """롱프레스 메뉴를 연다.

        요소 핸들로 touchAndHold를 걸면 열리지 않고 좌표로 걸어야 열린다.
        메뉴 컨테이너 이름은 경우에 따라 달라서, 열림 판정은 나와야 할 항목의 존재로 한다.
        """
        r = self.find(self.row(name), PRED).rect
        self.driver.execute_script("mobile: touchAndHold", {
            "x": r["x"] + r["width"] // 2, "y": r["y"] + r["height"] // 2, "duration": 1.2})
        assert self.exists(self.button(expect), PRED, self.TIMEOUT), \
            f"롱프레스 메뉴에 '{expect}'가 없음"

    def tap_and_wait_gone(self, value, by=ID):
        """메뉴 항목을 고르고 메뉴가 걷힐 때까지 기다린다."""
        self.tap(value, by)
        end = time.time() + self.TIMEOUT
        while time.time() < end:
            if not self._all(value, by):
                return
            time.sleep(0.25)
        raise AssertionError(f"메뉴가 닫히지 않음: {value}")

    def swipe_row(self, name):
        """행을 왼쪽으로 밀어 스와이프 액션을 드러낸다."""
        el = self.find(self.row(name), PRED)
        self.driver.execute_script("mobile: swipe", {"elementId": el.id, "direction": "left"})
        time.sleep(0.8)

    def go_back(self):
        """네비게이션 뒤로. SwiftUI가 name=BackButton 으로 노출한다."""
        self.tap('name == "BackButton"', PRED)

    def leave_screen(self):
        """현재 화면에서 한 단계 빠져나온다.

        상세 화면이 푸시(BackButton)일 수도 모달 시트(닫기)일 수도 있어 둘 다 본다.
        """
        if self.exists(self.button(T.CLOSE), PRED, timeout=1):
            self.tap_button(T.CLOSE)
            return True
        if self.exists('name == "BackButton"', PRED, timeout=1):
            self.go_back()
            return True
        return False

    # ---------- 스크롤 ----------
    def scroll_to_text(self, text, tries=8):
        for _ in range(tries):
            if self.has_text(text, timeout=1):
                return True
            self.driver.execute_script("mobile: swipe", {"direction": "up"})
            time.sleep(0.6)
        return self.has_text(text, timeout=1)

    def scroll_to(self, value, by=ID, tries=8):
        for _ in range(tries):
            if self.exists(value, by, timeout=1):
                return True
            self.driver.execute_script("mobile: swipe", {"direction": "up"})
            time.sleep(0.6)
        return self.exists(value, by, timeout=1)
