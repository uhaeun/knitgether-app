"""단수 카운터. 접힘 바와 펼침 패널이 같은 식별자를 공유하므로 시트 상태를 먼저 맞춘다."""
import time

from support import texts as T

from .base_page import ID, PRED
from .workspace_page import WorkspacePage
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


class CounterPanelPage(WorkspacePage):

    def open(self):
        self.expand_counter_sheet()
        return self

    def current_text(self):
        return self.label_of(self.find("workspace.counter.current"))

    def next_row(self, times=1):
        for _ in range(times):
            self.tap("workspace.counter.next")
            time.sleep(0.6)
        return self

    def previous_row(self, times=1):
        for _ in range(times):
            self.tap("workspace.counter.previous")
            time.sleep(0.6)
        return self

    def edit_current(self, value):
        self.tap("workspace.counter.edit_current")
        return self.replace_number(value)

    def replace_number(self, value):
        self.type_in("workspace.counter.number_field", str(value))
        return self

    def save_number(self):
        self.tap("workspace.counter.number_save")
        WebDriverWait(self.driver, self.TIMEOUT).until(
            EC.invisibility_of_element_located((ID, "workspace.counter.number_field")))
        return self

    def cancel_number(self):
        self.tap("workspace.counter.number_cancel")
        WebDriverWait(self.driver, self.TIMEOUT).until(
            EC.invisibility_of_element_located((ID, "workspace.counter.number_field")))
        return self

    def number_save_enabled(self):
        return self.find("workspace.counter.number_save").is_enabled()

    def number_error(self):
        return self.label_of(self.find("workspace.counter.number_error"))

    def set_current(self, value):
        self.edit_current(value).save_number()
        return self.wait_for_current(value)

    def wait_for_current(self, value):
        expected = T.COUNTER_START if value == 0 else T.COUNTER_CURRENT.format(value)
        WebDriverWait(self.driver, self.TIMEOUT).until(lambda _: self.current_text() == expected)
        return self

    def select_mode(self, label):
        self.tap("workspace.counter.mode")
        self.tap_text(label)
        time.sleep(1)
        return self
