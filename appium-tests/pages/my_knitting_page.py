"""내 뜨개 프로젝트 목록.

카드 행만 project.row.<uuid> 식별자가 있고 나머지(가운데 추가 버튼, 상태 필터 칩, 개수 표시,
롱프레스 메뉴, 스와이프 액션, 삭제 확인창)는 전부 문구로 잡는다.
"""
import re
import time

from support import texts as T

from .base_page import ID, PRED, BasePage

ROW_PREFIX = "project.row."


class MyKnittingPage(BasePage):

    def open(self):
        self.go_tab("내 뜨개")
        return self

    # ---------- 읽기 ----------
    def _rows(self):
        return self._all(f'name BEGINSWITH "{ROW_PREFIX}"', PRED)

    def project_names(self):
        """목록에 보이는 순서 그대로 이름을 돌려준다. 정렬 케이스가 이 순서를 본다.

        행 자체의 label은 썸네일 안내로 시작하는 합성 문자열이라 이름이 아니다.
        행 안의 첫 StaticText가 프로젝트 이름이다.
        """
        names = []
        for row in self._rows():
            kids = row.find_elements(PRED, 'type == "XCUIElementTypeStaticText"')
            names.append(self.label_of(kids[0]).strip() if kids else "")
        return names

    def has_project(self, name):
        return name in self.project_names()

    def row_summary(self, name):
        """행 label 전체. 도안 유무, 재료 연결, 최근 작업, 즐겨찾기 상태가 여기 다 들어 있다."""
        return self.label_of(self.find(self.row(name), PRED))

    def count_label(self):
        """상단 'n개 프로젝트' 표시. 없으면 None."""
        for t in self.texts():
            m = re.match(r"(\d+)" + T.PROJECT_COUNT, t or "")
            if m:
                return int(m.group(1))
        return None

    def is_empty_state(self):
        return self.has_text(T.EMPTY_PROJECTS)

    # ---------- 이동 ----------
    def open_project(self, name):
        self.tap_row(name)
        return self

    def open_add_form(self):
        """오른쪽 위 + 버튼."""
        self.tap_until("project.add", lambda: self.has_text(T.FORM_ADD_TITLE, 1))
        return self

    def open_add_form_from_empty(self):
        """프로젝트가 없을 때 화면 가운데 추가 버튼. 식별자가 없어 라벨로 잡는다."""
        self.tap_until(self.button("추가"), lambda: self.has_text(T.FORM_ADD_TITLE, 1), by=PRED)
        return self

    def create_project(self, name):
        """폼 검증이 목적이 아닌 케이스에서 프로젝트를 UI로 하나 만든다."""
        self.open_add_form()
        self.type_in("project.form.name", name)
        self.tap_until("project.save", lambda: self.has_text(name, 2))
        return self

    # ---------- 롱프레스 / 스와이프 ----------
    def long_press_menu(self, name, item):
        """롱프레스 메뉴에서 항목을 고른다.

        고른 뒤 상태 확인은 호출부가 한다. 삭제처럼 확인창 버튼과 이름이 같은 경우가 있어
        '메뉴가 사라졌는지'로는 판정할 수 없다.
        """
        self.long_press_row(name, item)
        self.tap_button(item)

    def swipe_action(self, name, label):
        self.swipe_row(name)
        self.tap_button(label)

    # ---------- 삭제 ----------
    def confirm_delete(self):
        assert self.alert_shown(T.DELETE_PROJECT_TITLE), "삭제 확인창이 뜨지 않음"
        self.alert_tap(T.DELETE)

    def cancel_delete(self):
        assert self.alert_shown(T.DELETE_PROJECT_TITLE), "삭제 확인창이 뜨지 않음"
        self.alert_tap(T.CANCEL)

    def retry_sync(self):
        """동기화 배너의 다시 시도. 복구 후 업로드를 촉발하는 입구다."""
        if self.exists(self.button("다시 시도"), PRED, timeout=1):
            self.tap_button("다시 시도")
            time.sleep(2)
        return self

    def pull_to_refresh(self):
        """목록을 아래로 당겨 새로고침한다. 복구 후 업로드를 촉발하는 조회 시점이다."""
        self.driver.execute_script("mobile: swipe", {"direction": "down"})
        time.sleep(2)
        return self

    # ---------- 필터 ----------
    def select_filter(self, title):
        """상태 칩. accessibilityLabel이 '<이름> 프로젝트 필터' 형태다."""
        self.tap(f'label == "{title} 프로젝트 필터"', PRED)
