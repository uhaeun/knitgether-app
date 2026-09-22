"""TC7 프로젝트 개수 한계 (UI-32). 시트: UI 케이스 탭.

상한 명세가 없어(명세 공백) 탐색적으로 본다. 1차 판정 이력은 PASS (8/23).
기법: 경계값, 탐색
"""
import time

from pages.home_page import HomePage
from pages.my_knitting_page import MyKnittingPage
from support import texts as T
from support.seed import Seed

BULK = 30


def test_ui_32_bulk_create_thirty(kg):
    """UI-32 30개를 UI로 연속 생성하고 목록과 홈의 개수가 일치하는지.

    생성 자체가 검증 대상이라 Given 주입이 아니라 UI 경로로 만든다.
    개당 소요를 재서 뒤로 갈수록 느려지는지도 본다.
    """
    kg.launch(Seed())
    lst, home = kg.page(MyKnittingPage).open(), kg.page(HomePage)

    elapsed = []
    for i in range(1, BULK + 1):
        t0 = time.time()
        lst.create_project(f"한계관찰-{i:02d}")
        elapsed.append(time.time() - t0)

    first, last = sum(elapsed[:5]) / 5, sum(elapsed[-5:]) / 5
    print(f"\n[측정] 개당 생성 평균 {sum(elapsed)/len(elapsed):.1f}초 "
          f"(앞 5개 {first:.1f}초, 뒤 5개 {last:.1f}초)")

    assert lst.count_label() == BULK, f"목록 개수 표시가 {BULK}이 아님: {lst.count_label()}"
    assert home.open().stat_int(T.HOME_TOTAL) == BULK, "홈의 전체 프로젝트 수가 목록과 다름"

    kg.relaunch()
    assert lst.open().count_label() == BULK, "재실행 후 목록 개수가 달라짐"
    assert home.open().stat_int(T.HOME_TOTAL) == BULK, "재실행 후 홈 개수가 달라짐"
