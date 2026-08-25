# TC7 개수 한계 관찰용 시딩 스크립트 (Claude 작성, 관찰 보조 도구)
# 프로젝트 30개를 UI 경로로 연속 생성해 목록 상태를 관찰할 수 있게 한다.
# 실행: ./.venv/bin/python count_seed.py

import time

from appium import webdriver
from appium.options.ios import XCUITestOptions
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

TOTAL = 30

options = XCUITestOptions()
options.udid = "3E4280D4-3E27-42E0-9C35-E84B24E08BD1"
options.bundle_id = "com.uhaeun.KnitGether"
options.set_capability("appium:processArguments", {
    "args": ["-knitgether.onboardingCompleted", "YES"],
    "env": {"KNITGETHER_API_BASE_URL": ""},  # 로컬 모드
})

started = time.time()
driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
wait = WebDriverWait(driver, 10)

def find(locator_type, value):
    return wait.until(EC.presence_of_element_located((locator_type, value)))

try:
    find(AppiumBy.ACCESSIBILITY_ID, "내 뜨개").click()

    for i in range(1, TOTAL + 1):
        loop_started = time.time()
        find(AppiumBy.ACCESSIBILITY_ID, "project.add").click()
        find(AppiumBy.ACCESSIBILITY_ID, "project.form.name").send_keys(f"한계관찰-{i:02d}")
        find(AppiumBy.ACCESSIBILITY_ID, "project.save").click()
        print(f"{i}/{TOTAL} 생성 ({time.time() - loop_started:.1f}초)", flush=True)

    elapsed = time.time() - started
    print(f"완료: {TOTAL}개 생성 ({elapsed:.1f}초)")
finally:
    driver.quit()
