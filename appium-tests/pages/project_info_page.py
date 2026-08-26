"""작업 화면의 프로젝트 정보 탭.

요약 4행(진행, 일정, 시작일, 총 작업시간)과 관련 스킬은 식별자가 없어 라벨 다음 값을 읽는다.
액션(사진 추가, 실 사용 기록, 바늘/도구 연결, 메모 저장)에만 식별자가 있다.
"""
from support import texts as T

import time

from .base_page import ID, PRED, BasePage


class ProjectInfoPage(BasePage):

    def summary(self, label):
        seq = [t for t in self.texts() if t]
        for i, t in enumerate(seq):
            if t == label and i + 1 < len(seq):
                return seq[i + 1]
        raise AssertionError(f"요약 행을 찾지 못함: {label}")

    def section_shown(self, title):
        return self.scroll_to_text(title)

    def shows(self, text):
        return self.scroll_to_text(text)

    def memo_value(self):
        """작업 메모는 TextEditor라 내용이 label이 아니라 value에 담긴다."""
        return self.find("workspace.memo.field").get_attribute("value") or ""

    def save_memo(self, text):
        self.type_in("workspace.memo.field", text)
        self.tap("workspace.memo.save")
        return self

    def link_tool(self, name):
        """도구 연결. 목록에서 고른 뒤 완료로 닫는다."""
        self.tap("workspace.tool.link")
        time.sleep(1.5)
        self.tap_row_start(self.find(self.row(name), PRED))
        time.sleep(1.5)
        if self.exists(self.button("완료"), PRED, timeout=2):
            self.tap_button("완료")
        time.sleep(2)
        return self

    def unlink_tool(self, name):
        """도구 연결 해제. 해제 버튼에 식별자가 없어 접근성 라벨로 찾는다."""
        for label in (f"{name} 연결 해제", "도구 연결 해제"):
            if self.exists(self.button(label), PRED, timeout=2):
                self.tap_button(label)
                break
        else:
            raise AssertionError("도구 연결 해제 버튼을 찾지 못함")
        if self.exists('type == "XCUIElementTypeAlert"', PRED, timeout=2):
            self.alert_tap("연결 해제")
        time.sleep(1.5)
        return self

    def add_progress_photo(self):
        """진행 사진 추가.

        사진 피커에는 사진 격자 말고도 안내 배너 아이콘 같은 이미지 요소가 섞여 있다.
        크기로 걸러 실제 사진 칸만 고른다.
        """
        self.tap("workspace.progress_photo.add")
        time.sleep(3)
        photos = [e for e in self._all('type == "XCUIElementTypeImage"', PRED)
                  if e.rect["width"] >= 100 and e.rect["height"] >= 100]
        assert photos, "사진 피커에 고를 사진이 없다. simctl addmedia로 먼저 채워야 한다"
        self.tap_at(photos[0])
        time.sleep(2)
        if self.exists("workspace.progress_photo.save", timeout=5):
            self.tap("workspace.progress_photo.save")
        time.sleep(2)
        return self

    def link_gauge(self, row_label):
        """게이지 기록 연결. 목록은 바늘 이름이 아니라 '세탁 전/후'와 코수로 표시된다."""
        self.tap("workspace.gauge_record.link")
        time.sleep(1.5)
        self.tap_row_start(self.find(self.row(row_label), PRED))
        time.sleep(2)
        if self.exists(self.button("완료"), PRED, timeout=2):
            self.tap_button("완료")
        time.sleep(1.5)
        return self

    def gauge_picker_has(self, row_label):
        """연결 목록에 기록이 남아 있는지 확인하고 닫는다. 원본 보존 판정에 쓴다."""
        self.tap("workspace.gauge_record.link")
        time.sleep(1.5)
        found = self.has_text(row_label)
        self.tap_button("완료")
        time.sleep(1.2)
        return found

    def unlink_gauge(self, row_label="세탁 전"):
        """연결된 게이지 기록의 연결을 끊는다.

        해제 입구가 버튼이 아니라 행의 롱프레스 메뉴다(식별자 없음).
        """
        # 부분 일치로 찾으면 "게이지 계산기에서 저장한 세탁 전/후 기록을..." 안내 문구가 먼저 잡힌다
        row = f'label == "{row_label}"'
        for _ in range(3):
            self.long_press_element(self.find(row, PRED), "연결 해제")
            time.sleep(1.0)          # 메뉴가 다 뜨기 전에 누르면 탭이 무시된다
            self.tap_at_locator(self.button("연결 해제"), PRED)
            if self.alert_shown("게이지 기록 연결을 해제할까요?", timeout=4):
                self.alert_tap("연결 해제")
                time.sleep(1.5)
                return self
        raise AssertionError("게이지 연결 해제 확인창이 뜨지 않음")
