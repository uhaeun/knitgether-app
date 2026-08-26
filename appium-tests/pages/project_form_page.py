"""프로젝트 추가/수정 폼. 두 화면이 같은 폼 컴포넌트를 쓴다(코드 확인).

이름, 상태, 메모, 실, 바늘, 도안, 저장, 삭제만 식별자가 있고
즐겨찾기 토글, 목표일 토글, 취소 버튼, 확인창은 문구로 잡는다.
"""
import time

from support import texts as T

from .base_page import ID, PRED, BasePage

DAY_FORMAT = "%A, %B %-d"   # 캘린더 셀 접근성 라벨 형식 (예: Thursday, August 27)


class ProjectFormPage(BasePage):

    def enter_name(self, name):
        self.type_in("project.form.name", name)
        return self

    def name_value(self):
        return self.find("project.form.name").get_attribute("value") or ""

    def save_enabled(self):
        return self.find("project.save").get_attribute("enabled") == "true"

    def save(self):
        self.tap("project.save")
        return self

    def cancel(self):
        self.tap_button(T.CANCEL)
        return self

    def set_status(self, detail_title):
        self.tap("project.form.status")
        self.tap_text(detail_title)
        return self

    def toggle_favorite(self):
        """즐겨찾기 스위치. 식별자가 없어 라벨이 붙은 스위치로 잡는다."""
        self.tap(f'type == "XCUIElementTypeSwitch" AND label CONTAINS "{T.FAVORITE}"', PRED)
        return self

    def favorite_on(self):
        el = self.find(f'type == "XCUIElementTypeSwitch" AND label CONTAINS "{T.FAVORITE}"', PRED)
        return el.get_attribute("value") == "1"

    def _switch(self, label):
        return f'type == "XCUIElementTypeSwitch" AND label CONTAINS "{label}"'

    def set_target_date(self, date):
        """목표일 토글을 켜고 캘린더에서 날짜를 고른다.

        목표일 DatePicker는 토글을 켜야 생기므로 항상 마지막 Date Picker가 목표일이다.
        """
        if self.find(self._switch(T.TARGET_DATE_TOGGLE), PRED).get_attribute("value") != "1":
            self.tap(self._switch(T.TARGET_DATE_TOGGLE), PRED)
            time.sleep(0.8)
        self._all(self.button("Date Picker"), PRED)[-1].click()
        time.sleep(1.2)

        today = __import__("datetime").date.today()
        delta = (date.year - today.year) * 12 + (date.month - today.month)
        for _ in range(abs(delta)):
            self.tap("DatePicker.NextMonth" if delta > 0 else "DatePicker.PreviousMonth")
            time.sleep(0.5)

        cell = date.strftime(DAY_FORMAT)
        target = f"Today, {cell}" if date == today else cell
        self.tap(f'label == "{target}"', PRED)
        time.sleep(0.5)
        self.tap('name == "PopoverDismissRegion"', PRED)
        time.sleep(0.5)
        return self

    def select_yarn(self, name):
        """실 선택. 선택지 라벨이 '이름 · 브랜드 · 색 · 굵기' 합성이라 부분 일치로 고른다."""
        self.tap("project.form.yarn")
        self.tap_row(name)
        return self

    def select_needle(self, name):
        self.tap("project.form.needle")
        self.tap_row(name)
        return self

    def clear_yarn(self):
        self.tap("project.form.yarn")
        self.tap_text("선택 안 함")
        return self

    def clear_needle(self):
        self.tap("project.form.needle")
        self.tap_text("선택 안 함")
        return self

    def linked_material_shown(self, name):
        return self.has_text(name)

    # ---------- 삭제 ----------
    def tap_delete(self):
        """수정 폼의 삭제 카드 버튼. 확인창 버튼과 식별자가 같아서 알럿 전에 눌러야 한다."""
        self.tap("project.delete")
        return self

    def confirm_delete(self):
        assert self.alert_shown(T.DELETE_PROJECT_TITLE), "삭제 확인창이 뜨지 않음"
        self.alert_tap(T.DELETE)

    def cancel_delete(self):
        assert self.alert_shown(T.DELETE_PROJECT_TITLE), "삭제 확인창이 뜨지 않음"
        self.alert_tap(T.CANCEL)
