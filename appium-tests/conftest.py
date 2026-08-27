"""드라이버 픽스처와 격리 훅.

드라이버는 세션당 하나만 만든다. terminate + activate 가 processArguments를 유지한다는 것을
실측으로 확인했고(생성 7.0초 대 재활성화 5.4초), 케이스마다 세션을 새로 열면 스위트가
못 쓸 만큼 느려진다.

로컬 모드는 KNITGETHER_LOCAL_CACHE_DIRECTORY가 먹지 않으므로(서버 모드 전용)
격리는 컨테이너의 저장 파일을 지우고 다시 쓰는 방식으로 한다.
"""
import os
import time
import uuid

import pytest
from appium import webdriver
from appium.options.ios import XCUITestOptions

from support import simctl
from support.netgate import NetGate
from support.seed import Seed

APPIUM_SERVER = "http://127.0.0.1:4723"
FAILURE_DIR = os.path.join(os.path.dirname(__file__), "failures")


def pytest_addoption(parser):
    parser.addoption(
        "--empty-given", action="store_true",
        help="Given 주입을 건너뛴다. 음성 대조용: 전제가 사라지면 테스트가 FAIL해야 정상이고, "
             "그래도 PASS하는 테스트는 검출력이 없는 것이다.")


def pytest_configure(config):
    config.addinivalue_line("markers", "server: 서버 기동이 필요한 케이스")


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    report = outcome.get_result()
    if report.when == "call" and report.failed:
        for name in ("kg", "kg_server", "onboarding"):
            obj = item.funcargs.get(name)
            driver = getattr(obj, "driver", None)
            if driver is not None:
                os.makedirs(FAILURE_DIR, exist_ok=True)
                shot = os.path.join(FAILURE_DIR, f"{item.name}.png")
                driver.save_screenshot(shot)
                print(f"\n[실패 스크린샷] {shot}")
                break


def _options(*, onboarding_completed=True, api_base_url="", full_reset=False, cache_dir=None):
    o = XCUITestOptions()
    o.udid = simctl.UDID
    # 재부팅 직후 시뮬레이터가 굼떠 기본 60초를 넘기면 세션이 죽는다 (Appium 로그 권고)
    o.set_capability("appium:wdaLaunchTimeout", 180000)
    # 서버 세션은 로컬 케이스가 도는 30분 넘게 놀고 있게 된다. 기본 60초로 두면
    # 그동안 Appium이 세션을 정리해 버려서 뒤쪽 서버 케이스가 통째로 에러가 난다.
    o.set_capability("appium:newCommandTimeout", 3600)
    if full_reset:
        o.app = os.environ.get("KG_APP_PATH", _default_app_path())
        o.full_reset = True
    else:
        o.bundle_id = simctl.BUNDLE_ID

    env = {"KNITGETHER_API_BASE_URL": api_base_url}
    if api_base_url:
        env["KNITGETHER_DISABLE_DEV_AUTH_TOKEN"] = "1"
    if cache_dir:
        env["KNITGETHER_LOCAL_CACHE_DIRECTORY"] = cache_dir

    args = []
    if onboarding_completed:
        args = ["-knitgether.onboardingCompleted", "YES"]
    else:
        # 런치 인자로 NO를 박으면 인자 도메인이 앱이 저장한 값을 계속 덮어써서
        # 온보딩을 끝내도 다시 온보딩으로 돌아온다. 초기화 전용 환경변수를 써야 한다.
        env["KNITGETHER_UI_TEST_RESET_ONBOARDING"] = "1"
    o.set_capability("appium:processArguments", {"args": args, "env": env})
    return o


def _default_app_path():
    """DerivedData 에서 가장 최근에 빌드된 KnitGether.app 을 고른다.

    DerivedData 폴더 이름의 해시는 프로젝트 '경로'에서 나온다. 레포 폴더 이름을 바꾸거나
    다른 위치로 옮기면 새 폴더가 생기고 옛 폴더는 그대로 남는다. 알파벳순으로 고르면
    그 순간부터 낡은 빌드를 상대로 테스트가 돌면서도 아무 경고가 없다.
    빌드 시각이 가장 늦은 것을 고르고, 후보가 둘 이상이면 어떤 걸 골랐는지 알린다.
    """
    base = os.path.expanduser("~/Library/Developer/Xcode/DerivedData")
    candidates = []
    for entry in os.listdir(base):
        if entry.startswith("KnitGether-"):
            p = os.path.join(base, entry, "Build/Products/Debug-iphonesimulator/KnitGether.app")
            if os.path.isdir(p):
                candidates.append((os.path.getmtime(p), p))

    if not candidates:
        raise LookupError(
            "KnitGether.app 을 DerivedData에서 찾지 못했다. "
            "Xcode에서 시뮬레이터용으로 한 번 빌드하거나 KG_APP_PATH 로 직접 지정하라."
        )

    candidates.sort()
    newest = candidates[-1][1]
    if len(candidates) > 1:
        built = time.strftime("%Y-%m-%d %H:%M", time.localtime(candidates[-1][0]))
        print(f"\n[conftest] DerivedData 후보 {len(candidates)}개 중 최신 빌드 사용 ({built})"
              f"\n           {newest}")
    return newest


class AppSession:
    """앱을 원하는 Given 상태로 되돌려 세워주고, 페이지 객체를 들고 있는다."""

    def __init__(self, driver, empty_given=False):
        self.driver = driver
        self._empty_given = empty_given
        self._pages = {}

    def launch(self, seed=None):
        self.driver.terminate_app(simctl.BUNDLE_ID)
        simctl.wipe_store()
        if seed is not None and not self._empty_given:
            seed.apply()
        self.driver.activate_app(simctl.BUNDLE_ID)
        time.sleep(1.5)
        self.dismiss_system_alert()
        self._pages.clear()
        return self

    def reset_account_state(self):
        """로그인 세션과 저장 파일을 모두 비우고 앱을 다시 세운다."""
        self.driver.terminate_app(simctl.BUNDLE_ID)
        simctl.reset_keychain()
        simctl.wipe_store()
        self.driver.activate_app(simctl.BUNDLE_ID)
        time.sleep(2)
        self.dismiss_system_alert()
        self._pages.clear()
        return self

    def dismiss_system_alert(self):
        """앞선 케이스가 남긴 권한 다이얼로그가 있으면 치운다. 화면을 통째로 막는다."""
        try:
            alerts = self.driver.find_elements(
                "-ios predicate string", 'type == "XCUIElementTypeAlert"')
            for alert in alerts:
                for label in ("허용", "Allow", "확인", "OK"):
                    btns = alert.find_elements("-ios predicate string", f'label == "{label}"')
                    if btns:
                        btns[0].click()
                        time.sleep(1)
                        return
        except Exception:
            pass

    def relaunch(self):
        """저장 파일은 그대로 두고 앱만 완전 종료 후 재실행 (재방문 보존 검증용)."""
        self.driver.terminate_app(simctl.BUNDLE_ID)
        self.driver.activate_app(simctl.BUNDLE_ID)
        time.sleep(1.5)
        self._pages.clear()
        return self

    def page(self, cls):
        return self._pages.setdefault(cls, cls(self.driver))


API_BASE_URL = os.environ.get("KG_API_BASE_URL", "http://127.0.0.1:3000/api/v1")


class DriverPool:
    """기기당 세션이 하나뿐이라 종류가 바뀔 때만 세션을 새로 연다.

    Appium XCUITest는 같은 시뮬레이터에 두 세션을 동시에 두지 못한다. 새 세션을 열면
    앞선 세션이 조용히 죽어서, 나중에 그 드라이버를 다시 쓰는 케이스가 통째로 에러가 난다.
    """

    def __init__(self):
        self._kind = None
        self._driver = None

    def get(self, kind, **options):
        if self._kind == kind and self._alive():
            return self._driver
        self.close()
        self._driver = webdriver.Remote(APPIUM_SERVER, options=_options(**options))
        # 앱을 다시 깔면 권한 부여가 초기화된다. 온보딩 케이스가 재설치를 하므로
        # 세션을 새로 열 때마다 다시 준다. 안 주면 문서 스캔에서 권한 다이얼로그가 뜨고
        # 그 다이얼로그가 다음 케이스 화면까지 막는다.
        # simctl privacy grant 는 대상 앱을 종료시킨다. 부여한 뒤 다시 띄워야 한다.
        simctl.grant_permissions()
        self._driver.activate_app(simctl.BUNDLE_ID)
        self._kind = kind
        time.sleep(2)
        return self._driver

    def _alive(self):
        try:
            self._driver.get_window_size()
            return True
        except Exception:
            return False

    def close(self):
        if self._driver is not None:
            try:
                self._driver.quit()
            except Exception:
                pass
        self._driver = None
        self._kind = None


@pytest.fixture(scope="session")
def _pool():
    simctl.grant_permissions()
    pool = DriverPool()
    yield pool
    pool.close()


@pytest.fixture
def kg(_pool, request):
    """로컬 모드 세션. 대부분의 케이스가 이걸 쓴다."""
    driver = _pool.get("local")
    return AppSession(driver, empty_given=request.config.getoption("--empty-given"))


@pytest.fixture
def kg_server(_pool):
    """서버 모드 세션. 회원가입, 로그인, 로그아웃 케이스가 쓴다.

    케이스마다 Keychain까지 비워 이전 계정의 세션이 넘어오지 않게 한다.
    토큰은 파일이 아니라 Keychain에 있어서 저장 파일만 지워서는 로그인 상태가 남는다.
    """
    session = AppSession(_pool.get("server", api_base_url=API_BASE_URL))
    session.reset_account_state()
    return session


@pytest.fixture
def netgate():
    """앱과 서버 사이를 끊었다 붙였다 하는 관문."""
    gate = NetGate().open()
    yield gate
    gate.close()


@pytest.fixture
def kg_offline(_pool, netgate):
    """네트워크 제어가 필요한 세션. 앱이 프록시 포트를 바라보게 띄운다."""
    session = AppSession(_pool.get("offline", api_base_url=netgate.base_url))
    session.reset_account_state()
    return session


@pytest.fixture
def onboarding(_pool):
    """온보딩 케이스 전용. 초기 상태가 필요해 앱을 지우고 다시 깐다."""
    _pool.close()          # 재설치 전에 기존 세션을 정리한다
    return AppSession(_pool.get("onboarding", onboarding_completed=False, full_reset=True))
