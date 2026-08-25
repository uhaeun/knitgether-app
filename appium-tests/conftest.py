# pytest 공통 설정: 드라이버 생성 픽스처 (준비 영역)
#
# 사용법:
#   def test_something(driver): ...        # 온보딩 완료 상태, 로컬 모드 (일반 케이스용)
#   def test_onboarding(fresh_driver): ... # 앱 삭제 후 재설치, 온보딩 미완료 (UI-01용)
#
# 실행: ./.venv/bin/python -m pytest tests/ -v

import pytest
from appium import webdriver
from appium.options.ios import XCUITestOptions

UDID = "3E4280D4-3E27-42E0-9C35-E84B24E08BD1"  # iPhone 17 Pro Max 시뮬레이터
BUNDLE_ID = "com.uhaeun.KnitGether"
APP_PATH = (
    "/Users/yuha/Library/Developer/Xcode/DerivedData/"
    "KnitGether-bqtdpqvqguybtqcutrziolwflksh/Build/Products/"
    "Debug-iphonesimulator/KnitGether.app"
)
APPIUM_SERVER = "http://127.0.0.1:4723"


def _make_driver(onboarding_completed: bool, full_reset: bool, server_mode: bool):
    options = XCUITestOptions()
    options.udid = UDID
    # WDA(현장 요원) 기상 대기를 60초 → 180초로 연장.
    # 재부팅 직후 시뮬레이터가 굼뜰 때 60초를 넘겨 세션이 죽는 문제 대응 (Appium 로그 권고)
    options.set_capability("appium:wdaLaunchTimeout", 180000)

    if full_reset:
        # 앱을 지우고 새로 설치해 "초기 상태(첫 실행)" Given을 만든다
        options.app = APP_PATH
        options.full_reset = True
    else:
        options.bundle_id = BUNDLE_ID

    process_args = {"env": {}}
    if onboarding_completed:
        process_args["args"] = ["-knitgether.onboardingCompleted", "YES"]
    if server_mode:
        process_args["env"]["KNITGETHER_API_BASE_URL"] = "http://127.0.0.1:3000/api/v1"
    else:
        process_args["env"]["KNITGETHER_API_BASE_URL"] = ""  # 로컬 모드
    options.set_capability("appium:processArguments", process_args)

    return webdriver.Remote(APPIUM_SERVER, options=options)


@pytest.fixture
def driver():
    """일반 케이스용: 온보딩 완료, 로컬 모드."""
    d = _make_driver(onboarding_completed=True, full_reset=False, server_mode=False)
    yield d
    d.quit()


@pytest.fixture
def fresh_driver():
    """온보딩 케이스용: 앱 재설치로 초기 상태."""
    d = _make_driver(onboarding_completed=False, full_reset=True, server_mode=False)
    yield d
    d.quit()


@pytest.fixture
def server_driver():
    """서버 케이스용(회원가입, 로그인 등): 온보딩 완료, 서버 모드."""
    d = _make_driver(onboarding_completed=True, full_reset=False, server_mode=True)
    yield d
    d.quit()
