"""작업 화면의 도안 영역.

⋯ 메뉴 항목에는 식별자가 있지만(그리기 삭제만 예외) 모드 토글의 개별 버튼, 보관 분기,
확인창은 전부 문구로 잡는다.
"""
import base64
import io
import time

from PIL import Image, ImageChops

from support import texts as T

from selenium.common.exceptions import (StaleElementReferenceException,
                                        WebDriverException)

from .base_page import ID, PRED
from .workspace_page import WorkspacePage

MENU = "workspace.pattern.focus.menu"


class PatternPanelPage(WorkspacePage):

    # ---------- 메뉴 ----------
    def _menu_open(self):
        return bool(self._all("workspace.pattern.manual"))

    def _settled(self, locator, by=ID, timeout=8):
        """좌표가 두 번 연속 같아질 때까지 기다렸다가 요소를 돌려준다.

        메뉴가 펼쳐지는 동안 rect가 계속 움직인다. 움직이는 중에 누르면
        아무 일도 안 일어나거나(탭 유실) 옆 항목이 눌린다. 둘 다 실제로 겪었다.
        """
        end = time.time() + timeout
        previous = None
        last_seen = None
        while time.time() < end:
            elements = self._all(locator, by)
            if elements:
                last_seen = elements[0]
                try:
                    current = last_seen.rect
                except StaleElementReferenceException:
                    previous = None
                    time.sleep(0.3)
                    continue
                if previous == current:
                    return last_seen
                previous = current
            time.sleep(0.4)
        # 끝내 안정되지 않아도 마지막으로 본 요소는 돌려준다.
        # None을 돌려주면 _pick이 한 번도 누르지 않고 재시도만 반복하다 실패한다.
        return last_seen

    def _pick(self, locator, by=ID, until=None, tries=4):
        """⋯ 메뉴를 열고 항목을 고른다.

        메뉴 항목은 element.click()이 먹지 않아 좌표로 두드린다. 그런데 좌표 탭은
        조용히 유실되기도 하고 옆 항목을 누르기도 한다. 그래서 "메뉴가 걷혔는가"가 아니라
        "기대한 다음 상태가 나타났는가"로 성공을 판정한다. 걷힘만 보면 잘못 눌러도 통과한다.
        """
        for _ in range(tries):
            try:
                if not self._menu_open():
                    self.tap(MENU)
                    time.sleep(1.8)  # 메뉴가 뜨는 동안은 좌표를 읽어도 소용이 없다
                element = self._settled(locator, by)
                if element is not None:
                    self.tap_at(element)
                    if self._wait_for(until or (lambda: not self._menu_open())):
                        return
                # 확인창이 떠 있으면 메뉴를 닫으려다 그 확인창을 눌러 없애게 된다.
                # 실제로 탭은 성공했는데 판정이 늦어 확인창을 지워버린 적이 있다.
                if self._menu_open() and not self._alert_present():
                    self.close_menu()
            except WebDriverException:
                # 메뉴가 다시 그려지는 동안 요소 참조가 끊기는 일이 잦다.
                # 한 번의 조작 실패로 케이스를 죽이지 않고 다시 시도한다.
                time.sleep(0.8)
        raise AssertionError(f"메뉴 항목 선택 실패: {locator}")

    def _alert_present(self):
        return bool(self._all('type == "XCUIElementTypeAlert"', PRED))

    @staticmethod
    def _wait_for(condition, timeout=8):
        end = time.time() + timeout
        while time.time() < end:
            if condition():
                return True
            time.sleep(0.4)
        return False

    def menu(self, item_id, expect=None):
        """⋯ 메뉴 항목 선택. expect를 주면 도착까지 확인한다.

        메뉴가 걷혔는지만 보면 옆 항목을 잘못 눌러도 통과해 버린다.
        """
        self._pick(item_id)
        if expect is not None:
            assert self.has_text(expect, timeout=8), \
                f"'{item_id}'를 골랐는데 기대한 화면이 아니다: {expect}"

    def menu_by_label(self, label, until=None):
        """식별자가 없는 항목(그리기 삭제)용."""
        self._pick(self.button(label), PRED, until=until)

    def close_menu(self):
        self.driver.execute_script("mobile: tap", {"x": 20, "y": 140})
        time.sleep(0.8)

    def menu_has(self, label):
        """메뉴에 항목이 있는지만 확인하고 닫는다. 드로잉 존재 신호로 쓴다."""
        if not self._menu_open():
            self.tap(MENU)
            time.sleep(1.8)
        found = self.exists(self.button(label), PRED, timeout=2)
        self.close_menu()
        return found

    # ---------- 상태 ----------
    def is_empty(self):
        return self.has_text(T.PATTERN_EMPTY)

    def shows_pattern(self, title):
        return self.has_text(title)

    # ---------- PDF 연결 ----------
    def import_pdf(self, file_stem, keep_in_library):
        """PDF 직접 추가. 파일 앱의 '나의 iPhone'에 미리 놓인 파일을 고른다.

        피커는 마지막으로 보던 위치를 기억한다. 최상위(위치 목록)에 서 있을 수도 있어
        파일이 안 보이면 '나의 iPhone'으로 한 단계 들어간다.
        """
        self.menu("workspace.pattern.direct_import")
        time.sleep(2.5)
        self._choose_file(file_stem)
        self.choose_storage(keep_in_library)

    def _choose_file(self, file_stem):
        self.tap_text("둘러보기")
        time.sleep(2)
        if not self.exists(f'label CONTAINS "{file_stem}"', PRED, timeout=2):
            self.tap_text("나의 iPhone")
            time.sleep(2)
        self.tap(f'label CONTAINS "{file_stem}"', PRED)
        time.sleep(2.5)

    def choose_storage(self, keep_in_library):
        """보관 분기. 액션 시트도 오버레이라 좌표로 두드리고 걷혔는지 확인한다."""
        assert self.has_text(T.STORE_PROMPT_TITLE), "보관 분기 확인창이 뜨지 않음"
        label = T.STORE_AND_LINK if keep_in_library else T.LINK_ONLY
        for _ in range(3):
            self.tap_at(self.find(self.button(label), PRED))
            time.sleep(2)
            if not self.exists(self.button(label), PRED, timeout=1):
                return
        raise AssertionError(f"보관 분기 선택 실패: {label}")

    def link_from_library(self, title):
        self.menu("workspace.pattern.library")
        time.sleep(1.5)
        self.tap_row(title)
        time.sleep(2)

    def add_manual(self, title):
        self.menu("workspace.pattern.manual")
        self.type_in("workspace.pattern.manual.title", title)
        self.tap("workspace.pattern.manual.save")
        time.sleep(1.5)

    def unlink(self):
        self._pick("workspace.pattern.unlink",
                   until=lambda: self.alert_shown(T.UNLINK_TITLE, timeout=1))
        self.alert_tap(T.UNLINK_CONFIRM)
        time.sleep(1.5)

    def replace_pdf(self, file_stem, confirm=True, keep_in_library=False):
        """도안 교체. 기존 도안이 있으면 드로잉 삭제 경고가 먼저 뜬다(DEF-10 수정분)."""
        self._pick("workspace.pattern.direct_import",
                   until=lambda: self.alert_shown(T.REPLACE_TITLE, timeout=1))
        assert self.has_text(T.REPLACE_WARNING, timeout=2), "경고 문구에 드로잉 삭제 안내가 없음"
        if not confirm:
            self.alert_tap(T.CANCEL)
            time.sleep(1)
            return
        self.alert_tap(T.REPLACE_CONFIRM)
        time.sleep(2.5)
        self._choose_file(file_stem)
        self.choose_storage(keep_in_library)

    # ---------- 뷰어 페이지 ----------
    def _scroll_view(self):
        return self.find('type == "XCUIElementTypeScrollView"', PRED)

    def viewer_signature(self):
        """지금 보이는 도안 본문 텍스트. 페이지 인디케이터가 없어 이걸 위치 지표로 쓴다."""
        sv = self._scroll_view()
        return [self.label_of(e)[:40]
                for e in sv.find_elements(PRED, 'type == "XCUIElementTypeStaticText"')][:5]

    def scroll_pages(self, count):
        """도안을 아래로 넘긴다. 뷰어가 세로 스크롤이라 페이지 이동도 스크롤이다."""
        for _ in range(count):
            self.driver.execute_script(
                "mobile: swipe", {"elementId": self._scroll_view().id, "direction": "up"})
            time.sleep(1.2)
        return self

    # ---------- 그리기 ----------
    def set_mode(self, label):
        """뷰어 모드 / 그리기 모드. 두 버튼이 같은 식별자를 공유해 라벨로 고른다."""
        self.tap(f'name == "workspace.pattern.focus.mode_toggle" AND label == "{label}"', PRED)
        time.sleep(1)

    _stroke_box = (120, 0, 300, 0)   # draw_stroke가 채운다

    def mark_stroke_box(self):
        """긋지 않고 비교 영역만 정한다. 통제 비교에 쓴다."""
        area = self.find(MENU).rect
        x0, y = 120, area["y"] + 220
        self._stroke_box = (x0, y, x0 + 180, y + 120)
        return self

    def draw_stroke(self):
        """도안 위에 선을 하나 긋는다. 별도 저장 버튼 없이 즉시 저장되는 구조다."""
        area = self.find(MENU).rect          # ⋯ 버튼 기준으로 도안 영역 중앙을 잡는다
        x0, y = 120, area["y"] + 220
        self.driver.execute_script("mobile: dragFromToForDuration", {
            "fromX": x0, "fromY": y, "toX": x0 + 180, "toY": y + 120, "duration": 1.0})
        self._stroke_box = (x0, y, x0 + 180, y + 120)
        time.sleep(1.5)

    def _shot(self):
        return Image.open(io.BytesIO(base64.b64decode(
            self.driver.get_screenshot_as_base64()))).convert("RGB")

    def stroke_area(self):
        """draw_stroke가 지나간 자리를 잘라낸 이미지.

        드로잉이 "보이는가"는 접근성 트리로 알 수 없다. PencilKit 캔버스가 요소로
        노출되지 않기 때문에, 그 자리를 화면에서 직접 잘라 비교한다.
        """
        shot = self._shot()
        scale = shot.width / self.driver.get_window_size()["width"]
        x0, y0, x1, y1 = self._stroke_box
        box = tuple(int(v * scale) for v in (x0 - 10, y0 - 10, x1 + 10, y1 + 10))
        return shot.crop(box)

    @staticmethod
    def looks_same(a, b, tolerance=0.01):
        """두 잘라낸 이미지가 사실상 같은지. 안티에일리어싱 차이는 허용한다."""
        diff = ImageChops.difference(a.convert("RGB"), b.convert("RGB"))
        changed = sum(1 for px in diff.get_flattened_data() if max(px) > 30)
        return changed / (diff.width * diff.height) <= tolerance

    def has_drawing(self):
        """드로잉 존재 신호. ⋯ 메뉴의 '그리기 삭제' 항목 유무로 판정한다."""
        return self.menu_has(T.MENU_DELETE_DRAWING)

    def delete_drawing(self, confirm=True):
        """그리기 삭제. 확인창이 떴는지로 메뉴 선택 성공을 판정한다."""
        self.menu_by_label(T.MENU_DELETE_DRAWING,
                           until=lambda: self.alert_shown(T.DELETE_DRAWING_TITLE, timeout=1))
        self.alert_tap(T.DELETE if confirm else T.CANCEL)
        time.sleep(1.5)


