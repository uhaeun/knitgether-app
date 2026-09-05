"""창고 탭. 허브의 진입 행에는 식별자가 없어 문구로 들어간다."""
import time

from support import texts as T

from .base_page import ID, PRED, BasePage


# 허브 진입 행에는 식별자가 없어 문구로 들어가되, 도착 판정은 그 화면에만 있는
# 등록 버튼 식별자로 한다. 허브에도 "도안 창고" 같은 글자가 있어서 문구로 도착을 판정하면
# 들어가기도 전에 도착했다고 오판한다.
SECTION_PREFIX = {
    T.LIB_PATTERN: "library.pattern",
    T.LIB_YARN: "library.yarn",
    T.LIB_NEEDLE: "library.needle",
    T.LIB_TOOL: "library.tool",
    T.LIB_SKILL: "library.skill",
}


class LibraryPage(BasePage):

    def open(self, section=None):
        self.go_tab("창고")
        if section:
            prefix = SECTION_PREFIX[section]
            self.tap_until(f'label CONTAINS "{section}"',
                           lambda: self.exists(f"{prefix}.add", timeout=1), by=PRED)
            time.sleep(0.8)
        return self

    def item_names(self, prefix):
        """목록 행의 이름들. 행 안 첫 StaticText가 이름이다(프로젝트 목록과 같은 구조)."""
        names = []
        for row in self._all(f'name BEGINSWITH "{prefix}.row."', PRED):
            kids = row.find_elements(PRED, 'type == "XCUIElementTypeStaticText"')
            if kids:
                names.append(self.label_of(kids[0]).strip())
        return names

    def pull_to_refresh(self):
        """목록을 아래로 당겨 새로고침한다. 서버 삭제분 프루닝을 촉발하는 조회 시점이다."""
        self.driver.execute_script("mobile: swipe", {"direction": "down"})
        time.sleep(2)
        return self

    def wait_for_rows(self, prefix, timeout=20):
        """목록에 행이 하나라도 나타날 때까지 기다린다."""
        end = time.time() + timeout
        while time.time() < end:
            if self.item_names(prefix):
                return True
            time.sleep(0.5)
        return False

    def wait_for_item(self, prefix, name, timeout=30):
        """목록에 항목이 나타날 때까지 기다린다.

        저장 직후에는 목록 갱신이 한 박자 늦어서, 한 번만 읽으면 없다고 나온다.
        """
        end = time.time() + timeout
        while time.time() < end:
            if name in self.item_names(prefix):
                return True
            time.sleep(0.5)
        return False

    def has_item(self, name):
        return self.scroll_to_text(name)

    def open_form(self, prefix):
        self.tap_until(f"{prefix}.add", lambda: self.exists(f"{prefix}.save", timeout=1))
        return self

    def fill_and_save(self, prefix, fields):
        for key, value in fields.items():
            self.type_in(f"{prefix}.form.{key}", value)
        self.tap(f"{prefix}.save")
        time.sleep(1.5)
        return self

    def save_enabled(self, prefix):
        return self.find(f"{prefix}.save").get_attribute("enabled") == "true"

    def edit(self, prefix, name, fields):
        """목록에서 항목을 열어 수정하고 목록으로 돌아온다."""
        self.tap_row(name)
        self.tap_until(f"{prefix}.edit", lambda: self.exists(f"{prefix}.form.name", timeout=1))
        for key, value in fields.items():
            self.type_in(f"{prefix}.form.{key}", value)
        self.tap(f"{prefix}.save")
        time.sleep(1.5)
        self.leave_screen()     # 저장 후에는 상세 화면(모달)이라 닫아야 목록이 보인다
        time.sleep(1)
        return self

    def delete_by_swipe(self, name, alert_title):
        """도안 창고는 삭제 버튼에 식별자가 없어 스와이프 액션으로 지운다."""
        self.swipe_row(name)
        self.tap_button(T.DELETE)
        assert self.alert_shown(alert_title), f"삭제 확인창이 뜨지 않음: {alert_title}"
        self.alert_tap(T.DELETE)
        time.sleep(1.5)
        return self

    def delete(self, prefix, name, alert_title):
        self.tap_row(name)
        time.sleep(1.2)
        self.tap(f"{prefix}.delete")
        assert self.alert_shown(alert_title), f"삭제 확인창이 뜨지 않음: {alert_title}"
        self.alert_tap(T.DELETE)
        time.sleep(1.5)
        return self
