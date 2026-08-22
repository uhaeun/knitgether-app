# DEF-15 회귀 테스트, Appium 버전
# XCUITest 버전(KnitGetherQAUITests/DEF-15_RegressionTests.swift)과 같은 플로우를
# Appium + Python으로 재구현해 구조, 속도, 안정성, 유지보수성을 비교한다.
#
# 실행: ./.venv/bin/python def15_test.py  (appium-tests 디렉토리에서)
# 전제: Appium 서버가 4723 포트에 떠 있고, 시뮬레이터에 앱이 설치돼 있음

import time

from appium import webdriver
from appium.options.ios import XCUITestOptions
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# ---------- 여기까지 준비 영역 (Claude 작성) ----------

options = XCUITestOptions()
options.udid = "3E4280D4-3E27-42E0-9C35-E84B24E08BD1"  # iPhone 17 Pro Max 시뮬레이터
options.bundle_id = "com.uhaeun.KnitGether"
# XCUITest 버전과 같은 실행 조건: 온보딩 건너뛰기 + 로컬 모드
options.set_capability("appium:processArguments", {
    "args": ["-knitgether.onboardingCompleted", "YES"],
    "env": {"KNITGETHER_API_BASE_URL": ""},
})

started = time.time()
driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
wait = WebDriverWait(driver, 10)  # 명시적 대기, XCUITest의 waitForExistence(timeout:)에 해당

def find(locator_type, value):
    """세 박자 중 찾기+대기. 요소가 나타날 때까지 기다렸다가 돌려준다."""
    return wait.until(EC.presence_of_element_located((locator_type, value)))

try:
    # ---------- 여기부터 하은 작성 영역 ----------
    # 형식 예시 (내 뜨개 탭 진입, 완성본):
    my_knitting_tab = find(AppiumBy.ACCESSIBILITY_ID, "내 뜨개")
    my_knitting_tab.click()

    # TODO 1. 프로젝트 추가 버튼 탭 (이름표 "project.add")
    project_add_btn = find(AppiumBy.ACCESSIBILITY_ID, "project.add")
    project_add_btn.click()    

    # TODO 2. 이름 입력 (이름표 "project.form.name", 입력은 .send_keys(값))
    project_name = f"DEF15-APPIUM-{int(time.time())}"
    project_form_name = find(AppiumBy.ACCESSIBILITY_ID, "project.form.name")
    project_form_name.send_keys(project_name)

    # TODO 3. 저장 버튼 탭 (이름표 "project.save")
    project_save_btn = find(AppiumBy.ACCESSIBILITY_ID, "project.save")
    project_save_btn.click()

    # TODO 4. 방금 만든 프로젝트 줄 탭 (이름표 대신 project_name 글자로 찾기)
    project_row = find(AppiumBy.ACCESSIBILITY_ID, project_name)
    project_row.click()

    # TODO 5. Given: 시트 열기(이름표 "workspace.counter.sheet_toggle"),
    #         값 요소 찾기(이름표 "workspace.counter.current") 후
    #         assert value.text == "시작 전"

    sheet_toggle = find(AppiumBy.ACCESSIBILITY_ID, "workspace.counter.sheet_toggle")
    sheet_toggle.click()
           
    counter_value = find(AppiumBy.ACCESSIBILITY_ID, "workspace.counter.current")
    assert counter_value.text == "시작 전"
    
    # TODO 6. 시트 닫기 (토글 다시 탭)
    sheet_toggle.click()

    # TODO 7. When: 증가 버튼 탭 (이름표 "workspace.counter.previous")
    previous_btn = find(AppiumBy.ACCESSIBILITY_ID, "workspace.counter.next")
    previous_btn.click()
    
    # TODO 8. Then: 시트 다시 열고 값이 여전히 "시작 전"인지 assert
    sheet_toggle.click()
    
    counter_value = find(AppiumBy.ACCESSIBILITY_ID, "workspace.counter.current")
    assert counter_value.text == "현재 1단"
    
    # ---------- 하은 작성 영역 끝 ----------
    elapsed = time.time() - started
    print(f"PASS ({elapsed:.1f}초)")
finally:
    driver.quit()
