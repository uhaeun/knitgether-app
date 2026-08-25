# 모든 페이지의 공통 부모 (준비 영역, Claude 작성)
# XCUITest POM의 공통 헬퍼(찾기, 대기, 세 박자)에 해당한다.

from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


class BasePage:
    DEFAULT_TIMEOUT = 10

    def __init__(self, driver):
        self.driver = driver
        self.wait = WebDriverWait(driver, self.DEFAULT_TIMEOUT)

    def find(self, value, by=AppiumBy.ACCESSIBILITY_ID):
        """세 박자 중 찾기+대기. 요소가 나타날 때까지 기다렸다가 돌려준다."""
        return self.wait.until(EC.presence_of_element_located((by, value)))

    def tap(self, value, by=AppiumBy.ACCESSIBILITY_ID):
        """찾기+대기+행동을 한 번에."""
        self.find(value, by).click()

    def exists(self, value, by=AppiumBy.ACCESSIBILITY_ID, timeout=10):
        """존재 여부만 판정 (assert용). 짧은 대기로 없음도 빠르게 확인."""
        try:
            WebDriverWait(self.driver, timeout).until(
                EC.presence_of_element_located((by, value))
            )
            return True
        except Exception:
            return False

    def label_exists(self, label, timeout=10):
        """겉에 보이는 글자(label)로 존재 판정. 탭 버튼처럼 name이 아이콘 이름인 요소용."""
        return self.exists(f'label == "{label}"', by=AppiumBy.IOS_PREDICATE, timeout=timeout)

    def label_tap(self, label):
        """label로 찾아서 탭."""
        self.tap(f'label == "{label}"', by=AppiumBy.IOS_PREDICATE)

    def contains_text(self, text, timeout=3):
        """화면 어딘가에 text가 포함된 요소가 있는지 (부분 일치 검색).
        "자동화니터님"처럼 문장에 섞인 글자를 찾을 때 쓴다."""
        return self.exists(
            f'label CONTAINS "{text}"', by=AppiumBy.IOS_PREDICATE, timeout=timeout
        )

    def text_field(self):
        """화면에 입력칸이 하나뿐일 때 종류로 찾기."""
        return self.find('type == "XCUIElementTypeTextField"', AppiumBy.IOS_PREDICATE)

    def go_tab(self, tab_name):
        """하단 탭 이동 (홈, 내 뜨개, 창고, 도구, 설정). 탭 버튼은 name이 아이콘 이름이라 label로 찾는다."""
        self.label_tap(tab_name)
