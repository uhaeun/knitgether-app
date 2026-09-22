"""단수 카운터. 접힘 바와 펼침 패널이 같은 식별자를 공유하므로 시트 상태를 먼저 맞춘다."""
import time

from support import texts as T

from .base_page import ID, PRED
from .workspace_page import WorkspacePage


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

    def set_current(self, value):
        self.tap("workspace.counter.edit_current")
        self.type_in("workspace.counter.number_field", str(value))
        self.tap("workspace.counter.number_save")
        time.sleep(1.2)
        return self

    def select_mode(self, label):
        self.tap("workspace.counter.mode")
        self.tap_text(label)
        time.sleep(1)
        return self
