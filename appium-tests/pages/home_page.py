"""홈 탭. 통계 타일에 식별자가 없어 라벨 다음에 오는 값 텍스트를 읽는다."""
from support import texts as T

from .base_page import PRED, BasePage


class HomePage(BasePage):

    def open(self):
        self.go_tab("홈")
        return self

    def stat(self, label):
        """'전체 프로젝트', '진행 중', '완성됨', '누적 작업' 타일의 값."""
        seq = [t for t in self.texts() if t]
        for i, t in enumerate(seq):
            if t == label and i + 1 < len(seq):
                return seq[i + 1]
        raise AssertionError(f"홈 타일을 찾지 못함: {label}")

    def stat_int(self, label):
        return int(self.stat(label))
