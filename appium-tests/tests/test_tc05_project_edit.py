"""TC5 프로젝트 수정 (UI-18~27). 시트: UI 케이스 탭.

CRUD 기본이라 판정이 명확하다. 진입 경로가 세 갈래(작업 화면, 롱프레스, 스와이프)라
경로별로 같은 결과가 나오는지, 연결이 유지되는지를 본다.
"""
from datetime import date, timedelta

from pages.home_page import HomePage
from pages.my_knitting_page import MyKnittingPage
from pages.project_form_page import ProjectFormPage
from pages.project_info_page import ProjectInfoPage
from pages.workspace_page import WorkspacePage
from support import texts as T
from support.seed import Seed


def _pages(kg):
    return (kg.page(MyKnittingPage), kg.page(WorkspacePage),
            kg.page(ProjectFormPage), kg.page(ProjectInfoPage))


def test_ui_18_rename_from_workspace(kg):
    """UI-18 작업 화면 경로 기본 수정. 기법: 시나리오"""
    s = Seed(); s.project("수정전이름")
    kg.launch(s)
    lst, ws, form, _ = _pages(kg)

    lst.open().open_project("수정전이름")
    ws.open_edit_form()
    form.enter_name("수정후이름").save()

    assert ws.title_shown("수정후이름"), "작업 화면에 변경된 이름이 없음"
    ws.go_back()
    assert lst.has_project("수정후이름") and not lst.has_project("수정전이름")


def test_ui_19_rename_keeps_yarn_link_workspace_path(kg):
    """UI-19 실 연결된 프로젝트에서 이름만 수정. 연결 유지 확인.

    기법: 시나리오, 상태 전이
    """
    s = Seed(); y = s.yarn("유지실"); s.project("연결유지전", yarn=y)
    kg.launch(s)
    lst, ws, form, _ = _pages(kg)

    lst.open().open_project("연결유지전")
    ws.open_edit_form()
    assert form.linked_material_shown("유지실"), "수정 폼에 연결된 실이 안 보임"
    form.enter_name("연결유지후").save()

    ws.open_edit_form()
    assert form.linked_material_shown("유지실"), "저장 후 재진입 시 실 연결이 사라짐"
    form.cancel()
    ws.go_back()
    assert "재료 미연결" not in lst.row_summary("연결유지후"), "목록 카드에서 재료 연결이 사라짐"


def test_ui_20_rename_keeps_yarn_link_long_press_path(kg):
    """UI-20 롱프레스 수정 경로에서도 연결이 유지되는지. 기법: 시나리오, 상태 전이"""
    s = Seed(); y = s.yarn("롱프레스실"); s.project("롱프레스전", yarn=y)
    kg.launch(s)
    lst, _, form, _ = _pages(kg)

    lst.open().long_press_menu("롱프레스전", T.EDIT)
    assert form.linked_material_shown("롱프레스실")
    form.enter_name("롱프레스후").save()

    lst.long_press_menu("롱프레스후", T.EDIT)
    assert form.linked_material_shown("롱프레스실"), "롱프레스 경로 저장 후 실 연결이 사라짐"
    form.cancel()
    assert "재료 미연결" not in lst.row_summary("롱프레스후")


def test_ui_21_rename_from_swipe(kg):
    """UI-21 스와이프 수정 경로 진입 검증. 기법: 시나리오"""
    s = Seed(); s.project("스와이프전")
    kg.launch(s)
    lst, _, form, _ = _pages(kg)

    lst.open().swipe_action("스와이프전", T.EDIT)
    assert lst.has_text(T.FORM_EDIT_TITLE), "스와이프 수정으로 폼이 열리지 않음"
    form.enter_name("스와이프후").save()

    assert lst.has_project("스와이프후")


def test_ui_22_editing_one_project_leaves_others(kg):
    """UI-22 2개 중 1개만 수정. 나머지는 불변. 기법: 상태 전이"""
    s = Seed(); s.project("대상A", status="WIP"); s.project("무관B", status="UFO")
    kg.launch(s)
    lst, _, form, _ = _pages(kg)
    before = lst.open().row_summary("무관B")

    lst.long_press_menu("대상A", T.EDIT)
    form.enter_name("대상A수정됨").save()

    assert lst.has_project("대상A수정됨")
    assert lst.row_summary("무관B") == before, "수정하지 않은 프로젝트의 표시가 바뀜"


def test_ui_23_cancel_discards_changes(kg):
    """UI-23 취소 분기. 재진입 시 폼에도 남지 않아야 한다. 기법: 상태 전이"""
    s = Seed(); s.project("취소원본")
    kg.launch(s)
    lst, _, form, _ = _pages(kg)

    lst.open().long_press_menu("취소원본", T.EDIT)
    form.enter_name("버려질이름").cancel()

    assert lst.has_project("취소원본") and not lst.has_project("버려질이름")
    lst.long_press_menu("취소원본", T.EDIT)
    assert form.name_value() == "취소원본", "재진입 폼에 취소한 입력이 남음"


def test_ui_24_target_date_shows_and_persists(kg):
    """UI-24 목표일 설정이 정보 탭과 목록 카드 양쪽에 반영되고 재실행 후 유지되는지.

    기법: 시나리오
    """
    s = Seed(); s.project("목표일대상")
    kg.launch(s)
    lst, ws, form, info = _pages(kg)
    target = date.today() + timedelta(days=3)

    lst.open().open_project("목표일대상")
    ws.open_edit_form()
    form.set_target_date(target)
    form.save()

    ws.show_info_tab()
    assert info.summary(T.INFO_SCHEDULE) != "목표일 없음", "정보 탭 일정에 목표일이 없음"
    ws.go_back()
    assert "D-3" in lst.row_summary("목표일대상"), f"목록 카드에 D-3이 없음: {lst.row_summary('목표일대상')}"

    kg.relaunch()
    assert "D-3" in lst.open().row_summary("목표일대상"), "재실행 후 목표일 표시가 사라짐"


def test_ui_25_dday_boundary(kg):
    """UI-25 목표일 표시 경계값. 어제 D+1, 오늘 D-Day, 내일 D-1.

    표시 규칙은 명세 공백이라 8/23 관찰 동작을 회귀 기준으로 채택했다.
    색상(빨강, 회색)은 Appium이 읽을 수 없어 문구만 판정한다.
    기법: 경계값
    """
    s = Seed(); s.project("경계값대상")
    kg.launch(s)
    lst, _, form, _ = _pages(kg)
    today = date.today()

    for delta, expected in ((-1, "D+1"), (0, "D-Day"), (1, "D-1")):
        lst.open().long_press_menu("경계값대상", T.EDIT)
        form.set_target_date(today + timedelta(days=delta))
        form.save()
        assert expected in lst.row_summary("경계값대상"), \
            f"{delta}일 차이에서 {expected}가 없음: {lst.row_summary('경계값대상')}"


def test_ui_26_status_transitions_persist(kg):
    """UI-26 CO→WIP→UFO→WIP→FO 전이. 되돌아가는 전이를 포함한다. 기법: 상태 전이"""
    s = Seed(); s.project("상태전이", status="Planned")
    kg.launch(s)
    lst, _, form, _ = _pages(kg)

    for detail, badge in (("WIP - 진행 중", "WIP"), ("UFO - 잠시 멈춤", "UFO"),
                          ("WIP - 진행 중", "WIP"), ("FO - 완성", "FO")):
        lst.open().long_press_menu("상태전이", T.EDIT)
        form.set_status(detail)
        form.save()
        assert badge in lst.row_summary("상태전이"), f"배지가 {badge}로 안 바뀜"

    kg.relaunch()
    assert "FO" in lst.open().row_summary("상태전이"), "재실행 후 최종 상태가 유지되지 않음"


def test_ui_27_completion_updates_home_counts(kg):
    """UI-27 완료 처리가 홈 집계에 반영되는지. 세 건 완성 전환, 한 건 완성 해제.

    기법: 상태 전이
    """
    s = Seed()
    for name, st in (("집계CO", "Planned"), ("집계WIP", "WIP"),
                     ("집계UFO", "UFO"), ("집계FO", "FO")):
        s.project(name, status=st)
    kg.launch(s)
    lst, _, form, _ = _pages(kg)
    home = kg.page(HomePage)
    before = home.open().stat_int(T.HOME_DONE)

    for name, detail in (("집계CO", "FO - 완성"), ("집계WIP", "FO - 완성"),
                         ("집계UFO", "FO - 완성"), ("집계FO", "CO - 시작")):
        lst.open().long_press_menu(name, T.EDIT)
        form.set_status(detail)
        form.save()

    assert home.open().stat_int(T.HOME_DONE) == before + 3 - 1, "완성됨 집계가 +3 -1이 아님"
    kg.relaunch()
    assert home.open().stat_int(T.HOME_DONE) == before + 3 - 1, "재실행 후 집계가 달라짐"
