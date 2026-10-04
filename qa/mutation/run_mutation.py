"""결함을 하나씩 심고 빌드해서, 지정한 케이스만 정확히 빨개지는지 본다.

전건 PASS는 "제품이 정상"일 수도 "테스트가 아무것도 안 본다"일 수도 있다.
일부러 고장을 내면 그 둘이 갈린다. 두 가지를 함께 본다.

  기대 FAIL   심은 고장을 잡아야 하는 케이스. 하나라도 통과하면 검출력이 없는 것이다.
  통제군      그 고장과 무관해야 하는 케이스. 같이 터지면 과잉 결합이라 분리 대상이다.

사용:  python3 qa/mutation/run_mutation.py --all
       python3 qa/mutation/run_mutation.py <주입이름>
       python3 qa/mutation/run_mutation.py --list
"""
import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request
from pathlib import Path
from xml.etree import ElementTree

sys.path.insert(0, os.path.dirname(__file__))
from injections import INJECTIONS, ROOT

UDID = os.environ.get("KG_UDID", "")
SCHEME = "KnitGether Local Offline"
APP = os.environ.get("KG_APP_PATH", "")
DERIVED_DATA = os.environ.get("KG_DERIVED_DATA_PATH", "")
SERVER_PORT = int(os.environ.get("KG_MUTATION_SERVER_PORT", "3106"))
API_BASE_URL = os.environ.get("KG_API_BASE_URL", f"http://127.0.0.1:{SERVER_PORT}/api/v1")
_BACKUPS = {}
_SERVER = None
_SERVER_LOG = None
TESTS = os.path.join(ROOT, "qa/appium")

# 어떤 고장에도 영향받지 않아야 하는 대표 케이스. 영역이 겹치지 않게 골랐다.
CONTROL = [
    "test_ui_13_add_via_top_plus",
    "test_ui_18_rename_from_workspace",
    "test_ui_44_manual_pattern",
    "test_ui_62_work_memo_saved_and_persists",
    "test_ui_65_register_yarn",
    "test_ui_70_yarn_edit_does_not_propagate",
]


def run(cmd, cwd=None, capture=True):
    return subprocess.run(cmd, cwd=cwd, shell=isinstance(cmd, str),
                          capture_output=capture, text=True)


def edits_of(inj):
    """단일 편집 정의와 편집 목록 정의를 같은 형태로 다룬다.

    한 층만 무너뜨려서는 드러나지 않는 고장이 있다. 카운터 하한이 뷰와 ViewModel
    두 곳에서 막혀 있어서, 한쪽만 건드렸을 때 테스트가 통과해 검출력이 없는 것처럼 보였다.
    """
    return inj.get("편집") or [(inj["파일"], inj["찾기"], inj["바꾸기"])]


def ensure_clean(inj):
    for path, _, _ in edits_of(inj):
        state = run(["git", "status", "--porcelain", path], cwd=ROOT)
        if state.returncode or state.stdout.strip():
            raise SystemExit(f"대상 파일에 이미 변경이 있다: {path}")


def patch(inj):
    # Validate every replacement before writing any file.
    pending = {}
    for rel, find, replace in edits_of(inj):
        path = Path(ROOT) / rel
        src = pending.get(path, path.read_text(encoding="utf-8"))
        if src.count(find) != 1:
            raise SystemExit(f"매칭 실패: {rel}")
        pending[path] = src.replace(find, replace, 1)
    try:
        for path, src in pending.items():
            _BACKUPS[path] = path.read_bytes()
            path.write_text(src, encoding="utf-8")
    except BaseException:
        restore(inj)
        raise


def restore(inj):
    # Only restore bytes this process actually changed; never reset a user's files.
    for rel, _, _ in edits_of(inj):
        path = Path(ROOT) / rel
        if path in _BACKUPS:
            path.write_bytes(_BACKUPS[path])
            del _BACKUPS[path]


def build_app():
    if not UDID or not APP:
        raise SystemExit("전용 시뮬레이터 KG_UDID와 KG_APP_PATH를 지정해야 합니다")
    if not DERIVED_DATA:
        raise SystemExit("빌드와 설치 대상을 일치시키려면 KG_DERIVED_DATA_PATH가 필요합니다")
    expected_app = Path(DERIVED_DATA) / "Build/Products/Debug-iphonesimulator/KnitGether.app"
    if Path(APP).resolve() != expected_app.resolve():
        raise SystemExit("KG_APP_PATH가 지정한 DerivedData의 빌드 결과와 다릅니다")
    r = run(["xcodebuild", "build", "-project", "KnitGether.xcodeproj",
             "-scheme", SCHEME, "-destination", f"id={UDID}",
             "-derivedDataPath", DERIVED_DATA, "-jobs", "2"], cwd=ROOT)
    if r.returncode != 0:
        print(r.stdout[-2000:])
        raise SystemExit("빌드 실패")
    installed = run(["xcrun", "simctl", "install", UDID, APP])
    if installed.returncode:
        raise SystemExit("앱 설치 실패")


def stop_server():
    global _SERVER, _SERVER_LOG
    if _SERVER is not None:
        if _SERVER.poll() is None:
            _SERVER.terminate()
            try:
                _SERVER.wait(timeout=10)
            except subprocess.TimeoutExpired:
                _SERVER.kill()
                _SERVER.wait()
        _SERVER = None
    if _SERVER_LOG is not None:
        _SERVER_LOG.close()
        _SERVER_LOG = None


def restart_server():
    """Start an owned test server; never kill another process on the configured port."""
    global _SERVER, _SERVER_LOG
    stop_server()
    probe = run(["lsof", "-nP", f"-tiTCP:{SERVER_PORT}", "-sTCP:LISTEN"])
    if probe.returncode not in (0, 1) or probe.stdout.strip():
        raise SystemExit(f"{SERVER_PORT} 포트를 비운 전용 테스트 환경에서 실행해야 합니다")
    if API_BASE_URL.rstrip("/") != f"http://127.0.0.1:{SERVER_PORT}/api/v1":
        raise SystemExit("KG_API_BASE_URL이 결함 주입 서버 포트와 일치하지 않습니다")
    server_dir = Path(ROOT) / "server"
    built = run(["npm", "run", "build"], cwd=server_dir)
    if built.returncode != 0:
        raise SystemExit("서버 빌드 실패")
    entry = next((p for p in [server_dir / "dist/main.js", server_dir / "dist/src/main.js"]
                  if p.exists()), None)
    if entry is None:
        raise SystemExit("서버 빌드 산출물 없음")
    _SERVER_LOG = tempfile.TemporaryFile(mode="w+")
    env = dict(os.environ, PORT=str(SERVER_PORT), NODE_ENV="test")
    _SERVER = subprocess.Popen(["node", str(entry)], cwd=server_dir, env=env,
                               stdout=_SERVER_LOG, stderr=subprocess.STDOUT)
    for _ in range(30):
        if _SERVER.poll() is not None:
            raise SystemExit("테스트 서버 시작 실패")
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{SERVER_PORT}/api/v1/health", timeout=2) as r:
                if r.status == 200:
                    return
        except OSError:
            pass
        time.sleep(1)
    raise SystemExit("테스트 서버 응답 없음")


def apply_target(inj):
    build_app() if inj["대상"] == "app" else restart_server()


def pytest_run(names):
    """지정한 케이스만 돌리고 케이스별 결과를 돌려준다.

    콘솔 출력을 파싱하면 안 된다. 실패 시 스크린샷 훅이 한 줄을 끼워 넣어서
    FAILED 가 테스트 이름과 다른 줄로 밀린다. 그 탓에 실패를 통째로 못 읽고
    전부 통과로 집계한 적이 있다. junit XML 로 읽는다.
    """
    with tempfile.TemporaryDirectory(prefix="kg-mutation-") as directory:
        report = Path(directory) / "report.xml"
        args = [os.path.join(TESTS, ".venv/bin/python"), "-m", "pytest", "tests/",
                "-q", "--tb=short", "--runxfail", "-k", " or ".join(names),
                f"--junitxml={report}"]
        result = subprocess.run(args, cwd=TESTS, capture_output=True, text=True,
                                env=dict(os.environ, KG_API_BASE_URL=API_BASE_URL))
        artifact_root = Path(os.environ.get("KG_MUTATION_RESULTS_DIR", "/tmp/knitgether-mutation-results"))
        artifact_root.mkdir(parents=True, exist_ok=True)
        artifact_name = f"{time.time_ns()}-{names[0] if names else 'empty'}"
        (artifact_root / f"{artifact_name}.log").write_text(
            (getattr(result, "stdout", "") or "") + (getattr(result, "stderr", "") or ""),
            encoding="utf-8")
        if report.exists():
            shutil.copy2(report, artifact_root / f"{artifact_name}.xml")
        print(f"  실행 원본: {artifact_root / artifact_name}")
        if result.returncode not in (0, 1) or not report.exists():
            raise RuntimeError("pytest 실행이 완료되지 않아 결함 검출을 판정할 수 없음")
        return parse_results(report)


def parse_results(report):
    results = {}
    for case in ElementTree.parse(report).iter("testcase"):
        name = case.get("name", "").split("[")[0]
        state = ("ERROR" if case.find("error") is not None else
                 "FAILED" if case.find("failure") is not None else
                 "SKIPPED" if case.find("skipped") is not None else "PASSED")
        # Mixed parameter results must never hide an error or an unexpected pass.
        if name in results and results[name] != state:
            state = "MIXED"
        results[name] = state
    return results


def check(name):
    inj = INJECTIONS[name]
    expected = inj["FAIL 기대"]
    controls = [c for c in CONTROL if c not in expected]

    print(f"\n{'=' * 62}\n[{name}] {inj['설명']}\n{'=' * 62}")
    ensure_clean(inj)
    patch(inj)
    try:
        apply_target(inj)
        results = pytest_run(expected + controls)
    finally:
        stop_server()
        restore(inj)
        if inj["대상"] == "app":
            build_app()
        else:
            rebuilt = run(["npm", "run", "build"], cwd=Path(ROOT) / "server")
            if rebuilt.returncode:
                raise RuntimeError("원본 서버 코드의 재빌드 실패: 실행 전에 다시 빌드해야 합니다")

    caught, missed, collateral = [], [], []
    for t in expected:
        (caught if results.get(t) == "FAILED" else missed).append(t)
    for c in controls:
        if results.get(c) != "PASSED":
            collateral.append(c)

    print(f"  검출   {len(caught)}/{len(expected)}")
    for t in caught:
        print(f"    O {t}")
    for t in missed:
        print(f"    X {t}  <- 기대한 assertion 실패가 아님. 결과 또는 실행 환경 확인")
    if collateral:
        for c in collateral:
            print(f"    ! {c}  <- 대조 케이스가 통과하지 않음. 실패, 오류, 누락 여부 확인")
    else:
        print(f"  통제군 {len(controls)}건 모두 정상")
    return {"name": name, "caught": caught, "missed": missed, "collateral": collateral}


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "--list"
    if arg == "--list":
        for name, inj in INJECTIONS.items():
            print(f"{name:24s} {inj['설명']}")
        return

    names = list(INJECTIONS) if arg == "--all" else [arg]
    if any(name not in INJECTIONS for name in names):
        raise SystemExit("알 수 없는 주입 이름입니다. --list를 확인하세요")
    if not UDID or not APP or not Path(APP).is_dir():
        raise SystemExit("전용 시뮬레이터 KG_UDID와 빌드한 앱 KG_APP_PATH를 지정하세요")
    for name in names:
        ensure_clean(INJECTIONS[name])
    summary = [check(name) for name in names]

    print(f"\n{'=' * 62}\n음성 대조 종합\n{'=' * 62}")
    for s in summary:
        state = "통과" if not s["missed"] and not s["collateral"] else "확인 필요"
        print(f"  {s['name']:24s} 검출 {len(s['caught'])}건  "
              f"놓침 {len(s['missed'])}건  대조 실패 {len(s['collateral'])}건  {state}")

    if any(s["missed"] or s["collateral"] for s in summary):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
