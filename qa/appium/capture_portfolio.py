"""Capture actual simulator screenshots and assertions for the submission.

Run only on a dedicated, disposable simulator using KG_UDID. The supplied
local test data is reset between scenarios. Existing regression tests stay intact.
"""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

if not os.environ.get("KG_UDID"):
    raise SystemExit("KG_UDID must name a dedicated capture simulator.")

from conftest import AppSession, DriverPool
from pages.my_knitting_page import MyKnittingPage
from pages.pattern_panel_page import PatternPanelPage
from pages.library_page import LibraryPage
from support import simctl, texts as T
from support.seed import Seed

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(sys.argv[1]).resolve()
OUT.mkdir(parents=True, exist_ok=True)
if (OUT / "events.jsonl").exists():
    raise SystemExit("Use a fresh output directory to preserve earlier run evidence.")
INPUTS = OUT / "inputs"
events = []
pool = DriverPool()
driver = None


def record(kind, **data):
    event = {"time": datetime.now(timezone.utc).isoformat(), "kind": kind, **data}
    events.append(event)
    with (OUT / "events.jsonl").open("a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")
    print(json.dumps(event, ensure_ascii=False), flush=True)


def check(name, value, actual=None):
    record("assertion", name=name, passed=bool(value), actual=actual)
    assert value, name


def shot(name, meaning):
    time.sleep(0.7)
    path = OUT / f"{name}.png"
    driver.save_screenshot(str(path))
    (OUT / f"{name}.xml").write_text(driver.page_source, encoding="utf-8")
    record("screenshot", file=path.name, meaning=meaning,
           sha256=hashlib.sha256(path.read_bytes()).hexdigest())


def seed_for(name):
    seed = Seed()
    seed.SAMPLE_DIR = str(INPUTS)
    yarn = seed.yarn("아이보리 울", brand="QA 테스트", quantity=3)
    needle = seed.needle("5mm 대바늘")
    seed.project(name, pattern="검증용 도안 A", pdf="qa-original.pdf", pages=4,
                 yarn=yarn, needle=needle)
    return seed


def page_marker():
    # The generic helper selected an empty overlapping scroll view. Read the full
    # accessibility snapshot and require the fixture's visible unique marker.
    nodes = ET.fromstring(driver.page_source).iter()
    return [{"label": n.get("label"), "y": float(n.get("y"))} for n in nodes
            if n.get("type") == "XCUIElementTypeStaticText"
            and n.get("visible") == "true"
            and n.get("label", "").startswith("Unique page marker:")]


def same_page(before, after):
    return (len(before) == len(after) == 1 and before[0]["label"] == after[0]["label"])


try:
    record("run_start", repository_reference_commit=subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        udid=simctl.UDID, mode="local repository, no API server",
        actor="Codex executed Appium capture on user request",
        build_provenance="Installed app; see installed-app.json for binary hash, not a new source build",
        fixture="Generated test PDFs, not commercial knitting patterns")
    driver = pool.get("local")
    kg = AppSession(driver)
    simctl.put_file_on_my_iphone(str(INPUTS / "qa-replacement.pdf"))

    if os.environ.get("KG_CAPTURE_ONLY") != "pages":
        kg.launch(seed_for("드로잉 보존 검증"))
        lst = kg.page(MyKnittingPage)
        pat = kg.page(PatternPanelPage)
        lst.open().open_project("드로잉 보존 검증")
        shot("01_workspace", "앱 소개용 작업 화면, 테스트 데이터")
        pat.set_mode(T.MODE_DRAW)
        pat.draw_stroke()
        check("교체 전 드로잉 존재", pat.has_drawing())
        shot("02_drawing_before", "기존 도안 A에 드로잉 존재")

        pat._pick("workspace.pattern.direct_import",
                  until=lambda: pat.alert_shown(T.REPLACE_TITLE, timeout=1))
        check("교체 확인창과 드로잉 삭제 안내", pat.has_text(T.REPLACE_WARNING, timeout=2))
        shot("03_replace_warning", "드로잉 삭제 안내와 취소 및 교체 선택")
        pat.alert_tap(T.CANCEL)
        time.sleep(1)
        check("취소 후 드로잉 유지", pat.has_drawing())
        check("취소 후 도안 A 유지", pat.shows_pattern("검증용 도안 A"))
        shot("04_cancel_preserved", "교체 취소 후 도안 A와 드로잉 유지")

        pat.replace_pdf("qa-replacement", confirm=True)
        check("승인 후 드로잉 제거", not pat.has_drawing())
        check("승인 후 도안 B 파일명 표시", pat.has_text("qa-replacement"))
        shot("05_confirm_replaced", "교체 승인 후 도안 B 표시와 이전 드로잉 제거")
        kg.relaunch()
        lst.open().open_project("드로잉 보존 검증")
        pat.set_mode(T.MODE_DRAW)
        check("재실행 후 드로잉 없음", not pat.has_drawing())
        check("재실행 후 도안 B 파일명 유지", pat.has_text("qa-replacement"))
        shot("06_relaunch_replaced", "재실행 후 교체한 도안과 드로잉 제거 상태 유지")
        record("case_complete", case="UI-45 direct PDF replacement + relaunch", result="PASS")

    kg.launch(seed_for("도안 위치 유지 검증"))
    lst = kg.page(MyKnittingPage)
    pat = kg.page(PatternPanelPage)
    lst.open().open_project("도안 위치 유지 검증")
    pat.set_mode(T.MODE_VIEWER)
    initial = page_marker()
    pat.scroll_pages(2)
    time.sleep(1)
    before = page_marker()
    check("1페이지에서 3페이지로 이동", bool(before) and before[0]["label"].endswith("A-03")
          and before != initial, {"initial": initial, "before": before})
    shot("07_page_before", "홈 이동 전 도안 본문 위치")
    pat.go_back()
    pat.go_tab("홈")
    shot("08_home_between", "프로젝트 목록을 나와 홈 탭에 진입")
    lst.open().open_project("도안 위치 유지 검증")
    time.sleep(2)
    after = page_marker()
    check("홈 복귀 후 같은 페이지 표시", same_page(before, after), {"before": before, "after": after})
    shot("09_page_after_home", "홈을 거쳐 같은 프로젝트로 돌아온 도안 위치")
    pat.menu("workspace.pattern.lookup", expect="사전")
    time.sleep(1)
    shot("10_lookup_between", "작업 화면에서 사전 조회로 이동")
    pat.tap_button("완료")
    check("사전 시트 닫힘", pat.exists("workspace.pattern.focus.menu", timeout=8)
          and not pat.has_text("도안 보며 찾아보기", timeout=1))
    time.sleep(2)
    after_lookup = page_marker()
    check("사전 복귀 후 같은 페이지 표시", same_page(before, after_lookup),
          {"before": before, "after": after_lookup})
    shot("11_page_after_lookup", "사전 조회 후 돌아온 도안 위치")
    record("case_complete", case="UI-51 home and lookup return", result="PASS")

    pat.go_back()
    kg.page(LibraryPage).open()
    shot("12_library_hub", "앱 소개용 창고 종류 화면")
    record("run_complete", result="PASS")
except Exception as exc:
    record("run_failed", error=type(exc).__name__, message=str(exc))
    if driver:
        try:
            shot("failure", "실패 당시 화면, 성공 증거로 사용하지 않음")
        except Exception:
            pass
    raise
finally:
    pool.close()
