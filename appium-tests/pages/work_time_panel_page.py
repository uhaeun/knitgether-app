"""뜨는 중 탭의 작업 시간 섹션.

10초 미만 세션은 작업으로 인정되지 않으므로(02 SPEC) 세션을 남기려면 그만큼 기다려야 한다.
"""
import time

from support import texts as T

from .base_page import ID, PRED
from .workspace_page import WorkspacePage

MIN_SESSION_SECONDS = 11


class WorkTimePanelPage(WorkspacePage):

    def record_session(self, seconds=MIN_SESSION_SECONDS):
        """작업 세션을 seconds 만큼 유지했다가 종료한다.

        작업 화면에 들어가면 앱이 세션을 자동으로 시작한다(ProjectWorkspaceView.swift:413).
        그래서 보통은 시작 버튼이 없고 종료 버튼만 있다. 멈춰 있는 경우에만 시작을 누른다.
        """
        self.expand_counter_sheet()
        if self.scroll_to("workspace.work_time.start", tries=3):
            self.tap("workspace.work_time.start")
        time.sleep(seconds)
        assert self.scroll_to("workspace.work_time.finish"), "작업 종료 버튼을 찾지 못함"
        self.tap("workspace.work_time.finish")
        time.sleep(1.5)
        self._dismiss_followups()
        return self

    def _dismiss_followups(self):
        """종료 직후 뜨는 확인창(완료 전환 제안 등)이 있으면 뒤로 물린다."""
        for label in ("나중에", T.CANCEL):
            if self.exists(f'type == "XCUIElementTypeAlert"', PRED, timeout=1):
                try:
                    self.alert_tap(label)
                    return
                except Exception:
                    continue
