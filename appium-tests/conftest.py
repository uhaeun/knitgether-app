"""드라이버 픽스처와 격리 훅.

드라이버는 세션당 하나만 만든다. terminate + activate 가 processArguments를 유지한다는 것을
실측으로 확인했고(생성 7.0초 대 재활성화 5.4초), 케이스마다 세션을 새로 열면 스위트가
못 쓸 만큼 느려진다.

로컬 모드는 KNITGETHER_LOCAL_CACHE_DIRECTORY가 먹지 않으므로(서버 모드 전용)
격리는 컨테이너의 저장 파일을 지우고 다시 쓰는 방식으로 한다.
"""
import os
import subprocess
import time
import uuid

import pytest
from appium import webdriver
from appium.options.ios import XCUITestOptions

from support import simctl
from support.netgate import NetGate
from support.seed import Seed

APPIUM_SERVER = "http://127.0.0.1:4723"

# 세션을 이만큼 쓰면 멀쩡해 보여도 새로 연다(2026-09-05 실측).
#
# 69분 연속 실행에서 UI-20, UI-24가 NoSuchElement로 실패하고 UI-25에서 WDA가 아예
# 붙지 않았다. 두 실패의 스크린샷이 바이트 단위로 같았고 내용은 완전한 검은 화면이었다.
# 요소를 못 찾은 것이 아니라 찾을 화면이 없었다. 격리 재실행(6분)에서는 10건 모두 통과해
# 제품 결함이 아님을 확인했다. 8/27에도 55분 실행에서 같은 계열이 나왔다(11절 8절).
#
# 시간을 기준으로 삼는 이유는 그것이 실측에서 갈린 유일한 변수이기 때문이다. 어떤 케이스가
# 실패했는지는 회차마다 달랐지만 긴 실행이라는 조건은 두 번 다 같았다.
SESSION_MAX_AGE_SECONDS = int(os.environ.get("KG_SESSION_MAX_AGE", "1200"))
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
        self._opened_at = None

    def get(self, kind, **options):
        """세션을 확보한다. activate_app 실패가 곧 세션 사망은 아니다.

        privacy grant 가 앱을 종료시키므로 뒤이어 activate_app 으로 다시 띄우는데,
        이 호출이 실패해도 세션까지 끊겼는지는 따로 확인해야 한다. 세션이 멀쩡한데
        버리면 멀쩡한 세션을 낭비하고, 죽은 세션을 그대로 돌려주면 실패가 테스트 본문의
        "요소를 못 찾음"으로 둔갑해 원인을 엉뚱한 곳에서 찾게 된다.
        그래서 실패 직후에 살아 있는지 보고, 죽었을 때만 세션을 새로 연다.
        재시도는 1회로 묶는다. 원인이 결정적이면 반복해도 같은 자리에서 죽어
        스위트가 끝나지 않는다.
        """
        if self._kind == kind and self._alive() and not self._expired():
            if self._restore_foreground():
                return self._driver
            print("\n[conftest] 세션은 살아 있는데 앱이 앞으로 오지 않는다. "
                  "세션을 새로 연다.")
        self.close()

        for attempt in (1, 2):
            self._driver = webdriver.Remote(APPIUM_SERVER, options=_options(**options))
            # 재설치(full_reset) 경로에서만 세션이 끊긴다. 재시도까지 재설치를 반복하면
            # 같은 자리에서 또 끊겨 두 번 다 실패한다. 1차 시도가 이미 재설치를 끝냈으므로
            # 컨테이너는 깨끗하고 권한도 부여된 상태다. 재시도는 깔린 앱에 붙기만 한다.
            # 온보딩 초기화는 full_reset 이 아니라 KNITGETHER_UI_TEST_RESET_ONBOARDING 이
            # 하므로 재시도 세션에도 그대로 적용된다.
            options = {**options, "full_reset": False}
            # 앱을 다시 깔면 권한 부여가 초기화된다. 온보딩 케이스가 재설치를 하므로
            # 세션을 새로 열 때마다 다시 준다. 안 주면 문서 스캔에서 권한 다이얼로그가 뜨고
            # 그 다이얼로그가 다음 케이스 화면까지 막는다.
            # simctl privacy grant 는 대상 앱을 종료시킨다. 부여한 뒤 다시 띄워야 한다.
            simctl.grant_permissions()
            try:
                self._driver.activate_app(simctl.BUNDLE_ID)
            except Exception as exc:
                if self._alive():
                    print(f"\n[conftest] activate_app 실패({type(exc).__name__}). "
                          f"세션은 살아 있어 그대로 진행한다.")
                elif attempt == 1:
                    print(f"\n[conftest] activate_app 이 세션까지 끊었다({type(exc).__name__}). "
                          f"세션을 다시 연다.")
                    self.close()
                    continue
                else:
                    raise
            self._kind = kind
            self._opened_at = time.monotonic()
            time.sleep(2)
            self._apply_settings()
            return self._driver

    def _apply_settings(self):
        """오버레이 요소를 인덱스로 바인딩한다.

        컨텍스트 메뉴 항목은 기본 바인딩에서 element.click() 이 조용히 유실된다.
        설정이 거부되더라도 스위트를 죽이지는 않는다. 실패하면 좌표 탭 경로가 그대로 쓰인다.
        """
        try:
            self._driver.update_settings({"boundElementsByIndex": True})
        except Exception as exc:
            print(f"\n[conftest] boundElementsByIndex 적용 실패({type(exc).__name__}). "
                  f"좌표 탭 경로로 진행한다.")

    def _alive(self):
        """세션이 명령에 응답하는지. 화면이 보이는지는 이것으로 알 수 없다.

        get_window_size는 앱이 죽어 검은 화면만 남아도 성공한다. 그래서 이 판정만으로
        세션을 재사용하면 죽은 화면을 그대로 물려주게 되고, 실패는 테스트 본문의
        "요소를 못 찾음"으로 둔갑한다. 2026-09-05가 그 경우였다.
        화면 쪽은 _restore_foreground가 따로 본다.
        """
        try:
            self._driver.get_window_size()
            return True
        except Exception:
            return False

    def _expired(self):
        """오래 쓴 세션은 멀쩡해 보여도 버린다. 근거는 SESSION_MAX_AGE_SECONDS 주석에 있다."""
        if self._opened_at is None:
            return True

        age = time.monotonic() - self._opened_at
        if age < SESSION_MAX_AGE_SECONDS:
            return False

        print(f"\n[conftest] 세션을 {int(age // 60)}분 썼다. 저하되기 전에 새로 연다.")
        return True

    def _restore_foreground(self):
        """앱이 화면 앞에 있는지 확인하고, 아니면 다시 띄운다.

        query_app_state 4가 foreground다. 앱이 죽었거나 뒤로 밀려 있으면 화면에 아무것도
        없으므로, 그 상태로 케이스를 시작하면 전부 요소를 못 찾는다.
        여기서 되살리지 못하면 호출자가 세션을 새로 연다.
        """
        try:
            if self._driver.query_app_state(simctl.BUNDLE_ID) == 4:
                return True

            self._driver.activate_app(simctl.BUNDLE_ID)
            time.sleep(1)
            return self._driver.query_app_state(simctl.BUNDLE_ID) == 4
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
        self._opened_at = None


@pytest.fixture(scope="session", autouse=True)
def _installed_app():
    """세션 시작 시 최신 빌드를 시뮬레이터에 설치한다.

    이것이 없으면 대부분의 케이스(full_reset=False)가 bundle_id로 이미 설치된 앱을
    실행만 하므로, 코드를 고쳐도 시뮬레이터에는 예전 바이너리가 남아 있고 스위트는 그것을
    검증한다. 2026-09-03에 이 상태로 로그인 케이스 전체가 실패했고, 원인을 앱이 아니라
    서버와 키체인에서 찾느라 시간을 썼다.

    검출력과는 다른 축의 문제다. 케이스가 무엇을 보는지 이전에, 어느 바이너리를 보는지가
    특정되지 않으면 회귀 판정의 대상이 없다.
    """
    app_path = os.environ.get("KG_APP_PATH") or _default_app_path()
    subprocess.run(["xcrun", "simctl", "install", simctl.UDID, app_path],
                   capture_output=True, text=True, check=True)
    built = time.strftime("%Y-%m-%d %H:%M", time.localtime(os.path.getmtime(app_path)))
    print(f"\n[conftest] 앱 설치 완료 (빌드 {built})\n           {app_path}")
    return app_path


@pytest.fixture(scope="session")
def _pool(_installed_app):
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
