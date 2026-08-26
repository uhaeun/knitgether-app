"""TC10a 작업 화면 - 도안 (UI-39~51). 시트: UI 케이스 탭 TC10.

도안 연결의 네 경로(PDF 직접, 문서 스캔, 창고, 수동), 교체와 해제, 그리기, 페이지 유지를 본다.
DEF-10(교체 시 드로잉 경고) 회귀와 DEF-18, DEF-19 회귀가 여기 모여 있다.
"""
import time

import pytest

from pages.counter_panel_page import CounterPanelPage
from pages.library_page import LibraryPage
from pages.my_knitting_page import MyKnittingPage
from pages.pattern_panel_page import PatternPanelPage
from pages.workspace_page import WorkspacePage
from support import simctl, texts as T
from support.seed import Seed

SAMPLE_PDF = "/Users/yuha/Desktop/Projects/KnitGether/KnitGether/Resources/SamplePatterns/sample4.pdf"
# 창고에는 sample1~4가 샘플 데이터로 이미 들어 있다. 가져오기 결과를 그 샘플과 구분하려면
# 파일 이름이 겹치지 않아야 한다.
IMPORT_PDF_NAME = "qa-import-check"   # 한글 파일명은 macOS에서 NFD로 저장돼 비교가 어긋난다


@pytest.fixture(autouse=True)
def _pdf_available(tmp_path):
    """문서 피커가 고를 수 있도록 파일 앱의 '나의 iPhone'에 고유 이름으로 PDF를 놓아둔다."""
    staged = tmp_path / f"{IMPORT_PDF_NAME}.pdf"
    staged.write_bytes(open(SAMPLE_PDF, "rb").read())
    simctl.put_file_on_my_iphone(str(staged))


def _pages(kg):
    return (kg.page(MyKnittingPage), kg.page(PatternPanelPage),
            kg.page(WorkspacePage), kg.page(LibraryPage))


def test_ui_39_enter_workspace_and_counter(kg):
    """UI-39 프로젝트 생성부터 카운터 초기값까지의 진입 여정 (DEF-15 자동화 경로).

    1차 판정 이력: 자동화 완료 (Appium, XCUITest 양쪽 + CI 게이트)
    기법: 시나리오, 회귀
    """
    kg.launch(Seed())
    lst = kg.page(MyKnittingPage).open()
    name = "진입여정"

    lst.create_project(name)
    lst.open_project(name)
    counter = kg.page(CounterPanelPage).open()

    assert counter.current_text() == T.COUNTER_START, \
        f"카운터 초기값이 '{T.COUNTER_START}'가 아님: {counter.current_text()}"


def test_ui_40_import_pdf_link_only(kg):
    """UI-40 PDF 직접 추가에서 프로젝트에만 연결. 창고에는 생기지 않아야 한다.

    1차 판정 이력: PASS (8/23 수동). 기법: 시나리오
    """
    s = Seed(); s.project("직접연결")
    kg.launch(s)
    lst, pat, ws, lib = _pages(kg)

    lst.open().open_project("직접연결")
    assert pat.is_empty()
    pat.import_pdf(IMPORT_PDF_NAME, keep_in_library=False)

    assert not pat.is_empty(), "도안이 연결되지 않음"
    ws.go_back()
    lib.open(T.LIB_PATTERN)
    names = lib.item_names("library.pattern")
    assert IMPORT_PDF_NAME not in names, f"프로젝트에만 연결인데 창고에 생김: {names}"


def test_ui_41_import_pdf_keep_in_library(kg):
    """UI-41 PDF 직접 추가에서 창고 보관까지 선택. 양쪽에 생겨야 한다.

    1차 판정 이력: PASS (8/23 수동). 기법: 시나리오
    """
    s = Seed(); s.project("창고보관")
    kg.launch(s)
    lst, pat, ws, lib = _pages(kg)

    lst.open().open_project("창고보관")
    pat.import_pdf(IMPORT_PDF_NAME, keep_in_library=True)

    assert not pat.is_empty(), "도안이 연결되지 않음"
    ws.go_back()
    lib.open(T.LIB_PATTERN)
    assert lib.wait_for_item("library.pattern", IMPORT_PDF_NAME), \
        f"창고 보관을 골랐는데 창고에 없음: {lib.item_names('library.pattern')}"


def test_ui_42a_document_scan_on_simulator(kg):
    """UI-42a 문서 스캔 진입. 시뮬레이터에서는 촬영이 불가능한 상태로 스캐너가 열린다.

    앱은 VNDocumentCameraViewController.isSupported가 false일 때를 위한 한글 폴백을
    갖고 있지만(DocumentScannerView.swift:11-13), iOS 26.5 시뮬레이터에서는 isSupported가
    true라 그 폴백이 실행되지 않고 시스템 스캐너가 그대로 열린다. 실기기 실제 촬영은 UI-42b.
    기법: 에러 기대
    """
    s = Seed(); s.project("스캔진입")
    kg.launch(s)
    lst, pat, ws, _ = _pages(kg)

    lst.open().open_project("스캔진입")
    pat.menu("workspace.pattern.scan")
    time.sleep(4)

    assert pat.has_text(T.SCANNER_HINT, timeout=8), "문서 스캐너가 열리지 않음"
    pat.tap_button("Cancel")
    time.sleep(2)
    assert pat.is_empty(), "스캔을 취소했는데 도안이 생김"


@pytest.mark.skip(reason="UI-42b 실기기 전용. 시뮬레이터에 카메라 피드가 없어 실제 촬영을 만들 수 없다. "
                         "클라우드 이미지 주입은 VisionKit 경로를 후킹하지 않아 대안이 되지 못한다.")
def test_ui_42b_document_scan_on_device():
    """UI-42b 실기기에서 실제 촬영으로 도안을 만드는 경로. 수동 트랙."""


def test_ui_43_link_from_library(kg):
    """UI-43 도안 창고에서 골라 연결. 창고 원본은 그대로 남아야 한다.

    창고 원본은 앱이 첫 실행에 심는 샘플 도안을 쓴다.
    1차 판정 이력: PASS (8/23 수동). DEF-13(창고 경로 파일 키 부재) 이력 경로.
    기법: 시나리오
    """
    s = Seed(); s.project("창고연결대상")
    kg.launch(s)
    lst, pat, ws, lib = _pages(kg)

    stored = lib.open(T.LIB_PATTERN).item_names("library.pattern")[0]
    assert stored, "창고에 샘플 도안이 없어 이 케이스를 실행할 수 없다"

    lst.open().open_project("창고연결대상")
    pat.link_from_library(stored)
    assert not pat.is_empty(), "창고에서 연결했는데 도안이 비어 있음"

    ws.go_back()
    lib.open(T.LIB_PATTERN)
    assert stored in lib.item_names("library.pattern"), "창고 원본이 사라짐"


def test_ui_44_manual_pattern(kg):
    """UI-44 수동 입력. 파일 없이 이름만 저장되고 안내가 뜬다.

    1차 판정 이력: PASS (8/23 수동). 기법: 시나리오
    """
    s = Seed(); s.project("수동입력대상")
    kg.launch(s)
    lst, pat, _, _ = _pages(kg)

    lst.open().open_project("수동입력대상")
    pat.add_manual("손으로적은도안")

    assert pat.shows_pattern("손으로적은도안")
    assert pat.has_text(T.PATTERN_NO_FILE), "PDF 부재 안내가 없음"
    assert pat.has_text(T.PATTERN_MANUAL_HINT), "수동 도안 안내가 없음"


def test_ui_46_unlink_pattern(kg):
    """UI-46 도안 연결 해제. 프로젝트에서만 빠지고 창고 원본은 남는다.

    1차 판정 이력: PASS (8/23 수동). 기법: 상태 전이
    """
    s = Seed(); s.project("해제대상", pattern="해제도안", pdf="sample4.pdf")
    kg.launch(s)
    lst, pat, _, _ = _pages(kg)

    lst.open().open_project("해제대상")
    assert not pat.is_empty()
    pat.unlink()

    assert pat.is_empty(), "연결 해제 후에도 도안이 남아 있음"


def test_ui_45_replace_warns_and_clears_drawing(kg):
    """UI-45 도안 교체 시 드로잉 삭제 경고. 취소하면 유지, 승인하면 교체되고 드로잉이 사라진다.

    DEF-10(교체 시 확인창 없이 드로잉 삭제) 수정분(8f1a4ad)의 회귀.
    1차 판정 이력: PASS (8/23 수동). 기법: 상태 전이, 회귀
    """
    s = Seed(); s.project("교체대상", pattern="원래도안", pdf="sample4.pdf")
    kg.launch(s)
    lst, pat, _, _ = _pages(kg)

    lst.open().open_project("교체대상")
    pat.set_mode(T.MODE_DRAW)
    pat.draw_stroke()
    assert pat.has_drawing(), "사전 조건: 드로잉이 있어야 한다"

    pat.replace_pdf(IMPORT_PDF_NAME, confirm=False)
    assert pat.has_drawing(), "교체를 취소했는데 드로잉이 사라짐"

    pat.replace_pdf(IMPORT_PDF_NAME, confirm=True)
    assert not pat.has_drawing(), "교체 후에도 이전 드로잉이 남아 있음"


def test_ui_47_draw_on_pattern(kg):
    """UI-47 그리기 모드에서 선을 긋는다. 저장 버튼 없이 즉시 저장되는 구조다.

    1차 판정 이력: PASS (8/23 수동). 기법: 시나리오
    """
    s = Seed(); s.project("그리기대상", pattern="그릴도안", pdf="sample4.pdf")
    kg.launch(s)
    lst, pat, _, _ = _pages(kg)

    lst.open().open_project("그리기대상")
    assert not pat.has_drawing(), "사전 조건: 드로잉이 없어야 한다"

    pat.set_mode(T.MODE_DRAW)
    pat.draw_stroke()

    assert pat.has_drawing(), "그린 뒤에도 드로잉 존재 신호가 없음"


def test_ui_48_drawing_survives_relaunch(kg):
    """UI-48 앱을 완전히 종료했다 켜도 그린 내용이 남아 있는지.

    저장 버튼이 없는 구조라 이 케이스가 저장이 실제로 일어났다는 증명이다.
    1차 판정 이력: PASS (8/23 수동). 기법: 상태 전이
    """
    s = Seed(); s.project("보존대상", pattern="보존도안", pdf="sample4.pdf")
    kg.launch(s)
    lst, pat, _, _ = _pages(kg)

    lst.open().open_project("보존대상")
    pat.set_mode(T.MODE_DRAW)
    pat.draw_stroke()
    assert pat.has_drawing()

    kg.relaunch()
    lst.open().open_project("보존대상")
    pat.set_mode(T.MODE_DRAW)

    assert pat.has_drawing(), "재실행 후 드로잉이 사라짐"


def test_ui_49_drawing_visible_in_viewer_mode(kg):
    """UI-49 보기 모드로 바꿔도 그린 내용이 보여야 한다.

    판정 근거: 02 PAT 신규 SPEC(오너 확정). 발견 시점: DEF-18은 8/23 UI-48 실행 중 관찰.
    기법: 상태 전이, 회귀
    """
    s = Seed(); s.project("뷰어대상", pattern="뷰어도안", pdf="sample4.pdf")
    kg.launch(s)
    lst, pat, _, _ = _pages(kg)

    lst.open().open_project("뷰어대상")

    # 통제: 드로잉이 없을 때 모드 전환만으로는 도안 영역이 바뀌지 않아야 한다.
    # 이걸 먼저 확인해야 아래 차이를 드로잉 탓으로 돌릴 수 있다.
    pat.set_mode(T.MODE_DRAW)
    pat.mark_stroke_box()
    blank_draw = pat.stroke_area()
    pat.set_mode(T.MODE_VIEWER)
    assert pat.looks_same(pat.stroke_area(), blank_draw), \
        "드로잉이 없는데도 모드 전환만으로 화면이 달라진다. 이 비교 방법 자체가 무효다"

    pat.set_mode(T.MODE_DRAW)
    pat.draw_stroke()
    drawn = pat.stroke_area()

    pat.set_mode(T.MODE_VIEWER)
    assert pat.looks_same(pat.stroke_area(), drawn), "보기 모드로 바꾸자 그린 내용이 사라짐"


def test_ui_50_delete_drawing_with_cancel(kg):
    """UI-50 그리기 삭제. 취소하면 유지, 승인하면 드로잉만 사라지고 도안은 남는다.

    1차 판정 이력: PASS (8/23 수동). 기법: 상태 전이
    """
    s = Seed(); s.project("그리기삭제", pattern="남을도안", pdf="sample4.pdf")
    kg.launch(s)
    lst, pat, _, _ = _pages(kg)

    lst.open().open_project("그리기삭제")
    pat.set_mode(T.MODE_DRAW)
    pat.draw_stroke()

    pat.delete_drawing(confirm=False)
    assert pat.has_drawing(), "삭제를 취소했는데 드로잉이 사라짐"

    pat.delete_drawing(confirm=True)
    assert not pat.has_drawing(), "삭제 승인 후에도 드로잉 신호가 남음"
    assert not pat.is_empty(), "드로잉만 지워야 하는데 도안까지 사라짐"


def test_ui_51_step3_page_kept_after_lookup(kg):
    """UI-51 스텝3 사전/스킬 찾기로 이탈했다 돌아와도 보던 위치가 유지되는지.

    PAT-05 기존 약속. 1차 판정 이력: PASS (8/23 수동). 기법: 상태 전이
    """
    s = Seed(); s.project("검색이탈", pattern="여러장도안", pdf="sample4.pdf", pages=8)
    kg.launch(s)
    lst, pat, ws, _ = _pages(kg)

    lst.open().open_project("검색이탈")
    pat.set_mode(T.MODE_VIEWER)
    pat.scroll_pages(3)
    before = pat.viewer_signature()

    pat.menu("workspace.pattern.lookup", expect="사전")
    time.sleep(2)
    ws.go_back()
    time.sleep(2)

    assert pat.viewer_signature() == before, "검색에서 돌아오니 보던 위치가 달라짐"


def test_ui_51_step2_page_kept_after_tab_round_trip(kg):
    """UI-51 스텝2 다른 탭을 다녀와도 보던 도안 위치가 유지되는지.

    작업 화면에는 탭바가 없어 다른 탭으로 가려면 반드시 목록으로 나갔다 와야 한다.
    시트 스텝의 "홈 탭 다녀오기"는 실제로 이 경로다.
    판정 근거: PAT-05 개정판(탭 이동 포함, 오너 결정 8/23)
    발견 시점: DEF-19는 8/23 UI-51 실행 중 관찰. 기법: 상태 전이, 회귀
    """
    s = Seed(); s.project("탭복귀", pattern="여러장도안", pdf="sample4.pdf", pages=8)
    kg.launch(s)
    lst, pat, ws, _ = _pages(kg)

    lst.open().open_project("탭복귀")
    pat.set_mode(T.MODE_VIEWER)
    pat.scroll_pages(3)
    before = pat.viewer_signature()

    ws.go_back()
    pat.go_tab("홈")
    lst.open().open_project("탭복귀")
    time.sleep(2)

    assert pat.viewer_signature() == before, "탭을 다녀오니 보던 위치가 처음으로 돌아감"
