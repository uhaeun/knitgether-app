"""프로젝트 작업 화면의 뼈대. 도안, 카운터, 정보 탭은 각자 전용 페이지가 맡는다."""
from support import texts as T

from .base_page import ID, PRED, BasePage


class WorkspacePage(BasePage):

    def is_open(self):
        return self.exists("workspace.tab", timeout=self.SHORT)

    def open_edit_form(self):
        self.tap_until("workspace.project.edit", lambda: self.has_text(T.FORM_EDIT_TITLE, 1))
        return self

    def collapse_counter_sheet(self):
        """카운터 시트를 접는다. 펼쳐진 시트가 탭 세그먼트를 가려 전환이 막힌다."""
        if self.exists(self.button(T.SHEET_EXPAND), PRED, timeout=1):
            return self
        self.tap_until("workspace.counter.sheet_toggle",
                       lambda: self.exists(self.button(T.SHEET_EXPAND), PRED, 1))
        return self

    def show_working_tab(self):
        """뜨는 중 탭. 세그먼트 컨테이너에만 식별자가 있어 개별 세그먼트는 글자로 고른다."""
        self.collapse_counter_sheet()
        self.tap_until(self.button(T.TAB_WORKING),
                       lambda: self.exists("workspace.pattern.focus.menu", timeout=1), PRED)
        return self

    def show_info_tab(self):
        self.collapse_counter_sheet()
        self.tap_until(self.button(T.TAB_INFO),
                       lambda: self.has_text(T.INFO_SUMMARY, 1), PRED)
        return self

    def expand_counter_sheet(self):
        """카운터 시트를 펼친다.

        작업 시간 패널은 시트가 펼쳐졌을 때만 그려진다(ProjectWorkspaceView.swift:509-514).
        토글의 접근성 라벨이 현재 상태를 알려주므로 그걸로 판정한다.
        """
        if self.exists(self.button(T.SHEET_COLLAPSE), PRED, timeout=1):
            return self
        self.tap_until("workspace.counter.sheet_toggle",
                       lambda: self.exists(self.button(T.SHEET_COLLAPSE), PRED, 1))
        return self

    def title_shown(self, name):
        return self.has_text(name)
