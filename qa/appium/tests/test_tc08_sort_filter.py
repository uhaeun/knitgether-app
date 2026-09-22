"""TC8 프로젝트 정렬과 필터 (UI-33~36). 시트: UI 케이스 탭.

순서 비교라 판정이 명확하다. DEF-17(마지막 작업 시각 미저장) 회귀 3건을 포함한다.
"""
import pytest

from pages.my_knitting_page import MyKnittingPage
from pages.work_time_panel_page import WorkTimePanelPage
from pages.workspace_page import WorkspacePage
from support import texts as T
from support.seed import Seed, ts


def _record(kg, lst, name):
    lst.open().open_project(name)
    kg.page(WorkTimePanelPage).record_session()
    kg.page(WorkspacePage).go_back()


def test_ui_33_recent_work_moves_to_top(kg):
    """UI-33 10초 이상 작업 기록이 정렬과 최근 작업 표시에 반영되는지.

    판정 기준: 02 SPEC 정렬 규칙 / 발견 시점: DEF-17은 8/23 케이스 설계 중 발견
    기법: 상태 전이, 회귀
    """
    s = Seed()
    s.project("위쪽", started=ts(days_ago=1))
    s.project("아래쪽", started=ts(days_ago=9))
    kg.launch(s)
    lst = kg.page(MyKnittingPage).open()
    assert lst.project_names()[-1] == "아래쪽", "사전 조건: 대상이 맨 아래여야 함"

    _record(kg, lst, "아래쪽")

    assert lst.open().project_names()[0] == "아래쪽", "작업한 프로젝트가 상단으로 오지 않음"
    assert "최근 작업 없음" not in lst.row_summary("아래쪽"), "최근 작업 표시가 갱신되지 않음"
    kg.relaunch()
    assert lst.open().project_names()[0] == "아래쪽", "재실행 후 순서가 유지되지 않음"


def test_ui_34_start_date_desc_without_history(kg):
    """UI-34 작업 이력이 없으면 시작일 내림차순(나중 생성이 위).

    생성 시각이 서로 달라야 하므로 UI로 순서대로 만든다.
    기법: 시나리오
    """
    kg.launch(Seed())
    lst = kg.page(MyKnittingPage).open()
    for n in ("정렬A", "정렬B", "정렬C"):
        lst.create_project(n)

    assert lst.project_names() == ["정렬C", "정렬B", "정렬A"], \
        f"시작일 내림차순이 아님: {lst.project_names()}"


def test_ui_35_relative_order_between_histories(kg):
    """UI-35 복수 작업 이력 간 상대 순서. 마지막에 작업한 쪽이 항상 위.

    기법: 상태 전이, 회귀
    """
    s = Seed(); s.project("이력A"); s.project("이력B")
    kg.launch(s)
    lst = kg.page(MyKnittingPage).open()

    _record(kg, lst, "이력A")
    _record(kg, lst, "이력B")
    assert lst.open().project_names()[0] == "이력B", "나중에 작업한 B가 위가 아님"

    _record(kg, lst, "이력A")
    assert lst.open().project_names()[0] == "이력A", "다시 작업한 A가 위로 오지 않음"


def test_ui_36_status_filter(kg):
    """UI-36 상태 칩 필터. 개수 표시가 필터를 따르는지도 관찰한다.

    개수 표시는 코드상 항상 전체 수라 필터 중 어긋날 것으로 보고, 명세 공백으로 기록만 한다.
    기법: 시나리오
    """
    s = Seed(); s.project("진행중건", status="WIP"); s.project("멈춤건", status="UFO")
    kg.launch(s)
    lst = kg.page(MyKnittingPage).open()

    lst.select_filter("WIP")
    assert lst.project_names() == ["진행중건"], f"WIP만 남지 않음: {lst.project_names()}"

    lst.select_filter("UFO")
    assert lst.project_names() == ["멈춤건"], f"UFO만 남지 않음: {lst.project_names()}"

    lst.select_filter(T.FILTER_ALL)
    assert set(lst.project_names()) == {"진행중건", "멈춤건"}, "전체 선택에서 모두 돌아오지 않음"
