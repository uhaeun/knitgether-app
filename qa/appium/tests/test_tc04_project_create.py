"""TC4 프로젝트 추가 (UI-13~17). 시트: UI 케이스 탭.

모든 여정의 시작점이라 로드맵 P1. 판정 기준은 02 SPEC과 SPEC-PROJ-01.
"""
import pytest

from pages.my_knitting_page import MyKnittingPage
from pages.project_form_page import ProjectFormPage
from support import texts as T
from support.seed import Seed


def test_ui_13_add_via_top_plus(kg):
    """UI-13 오른쪽 상단 [+] 버튼으로 추가. 미입력과 공백은 저장 비활성.

    기법: 시나리오, 에러 기대, 경계값 (0자 경계를 여기서 커버)
    """
    kg.launch(Seed())
    lst, form = kg.page(MyKnittingPage).open(), kg.page(ProjectFormPage)

    lst.open_add_form()
    assert not form.save_enabled(), "미입력인데 저장이 활성"
    form.enter_name("   ")
    assert not form.save_enabled(), "공백만 입력했는데 저장이 활성"
    form.enter_name("상단추가검증")
    assert form.save_enabled(), "이름을 넣었는데 저장이 비활성"
    form.save()

    assert lst.has_project("상단추가검증")


def test_ui_14_add_from_empty_state(kg):
    """UI-14 프로젝트 0개 상태의 화면 가운데 [+ 추가] 버튼.

    기법: 시나리오
    """
    kg.launch(Seed())
    lst, form = kg.page(MyKnittingPage).open(), kg.page(ProjectFormPage)
    assert lst.is_empty_state(), "빈 상태 안내가 없음"

    lst.open_add_form_from_empty()
    assert not form.save_enabled()
    form.enter_name("빈상태추가검증").save()

    assert lst.has_project("빈상태추가검증")


def test_ui_15_add_five_in_a_row(kg):
    """UI-15 서로 다른 이름으로 5개 연속 추가. 개수 표시까지 확인.

    기법: 시나리오
    """
    kg.launch(Seed())
    lst = kg.page(MyKnittingPage).open()
    names = [f"연속추가-{c}" for c in "ABCDE"]

    for n in names:
        lst.create_project(n)

    assert set(names) <= set(lst.project_names()), "5개가 모두 목록에 있지 않음"
    assert lst.count_label() == 5, f"개수 표시가 5가 아님: {lst.count_label()}"


def test_ui_16_duplicate_names_allowed(kg):
    """UI-16 같은 이름으로 2회 생성 (명세 공백 관찰).

    상한이나 중복 금지 명세가 없어 현재 동작을 관찰 기준으로 채택한다.
    기법: 시나리오
    """
    kg.launch(Seed())
    lst = kg.page(MyKnittingPage).open()

    lst.create_project("중복이름")
    lst.create_project("중복이름")

    assert lst.project_names().count("중복이름") == 2, "같은 이름 2개가 별개 항목으로 남지 않음"


def test_ui_17_name_length_boundary(kg):
    """UI-17 프로젝트 이름 길이 상한 경계값.

    판정 기준: SPEC-PROJ-01 (1~30자, 하드 캡, n/30 카운터 표시)
    발견 시점: 8/23 케이스 설계 중 코드 3층 확인으로 제한 부재 확인
    기법: 경계값
    """
    kg.launch(Seed())
    lst, form = kg.page(MyKnittingPage).open(), kg.page(ProjectFormPage)
    lst.open_add_form()

    form.enter_name("가")
    assert form.save_enabled() and form.has_text("1/30"), "1자에서 카운터 1/30이 없음"
    form.enter_name("가" * 30)
    assert form.has_text("30/30"), "30자에서 카운터 30/30이 없음"
    form.enter_name("나" * 31)
    assert len(form.name_value()) == 30, "31자 입력이 30자로 잘리지 않음"
