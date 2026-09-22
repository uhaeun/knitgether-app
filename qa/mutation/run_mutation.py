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
import subprocess
import sys
from xml.etree import ElementTree

sys.path.insert(0, os.path.dirname(__file__))
from injections import INJECTIONS, ROOT

UDID = "3E4280D4-3E27-42E0-9C35-E84B24E08BD1"
SCHEME = "KnitGether Local Offline"
APP = os.path.expanduser(
    "~/Library/Developer/Xcode/DerivedData/KnitGether-bqtdpqvqguybtqcutrziolwflksh/"
    "Build/Products/Debug-iphonesimulator/KnitGether.app")
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
        if run(["git", "status", "--porcelain", path], cwd=ROOT).stdout.strip():
            raise SystemExit(f"대상 파일에 이미 변경이 있다: {path}")


def patch(inj):
    for rel, find, replace in edits_of(inj):
        path = os.path.join(ROOT, rel)
        src = open(path, encoding="utf-8").read()
        if src.count(find) != 1:
            raise SystemExit(f"매칭 실패: {rel}")
        open(path, "w", encoding="utf-8").write(src.replace(find, replace, 1))


def restore(inj):
    for rel, _, _ in edits_of(inj):
        run(["git", "checkout", "--", rel], cwd=ROOT)


def build_app():
    r = run(["xcodebuild", "build", "-project", "KnitGether.xcodeproj",
             "-scheme", SCHEME, "-destination", f"id={UDID}"], cwd=ROOT)
    if r.returncode != 0:
        print(r.stdout[-2000:])
        raise SystemExit("빌드 실패")
    run(["xcrun", "simctl", "install", UDID, APP])


def restart_server():
    """서버를 새 소스로 다시 띄운다.

    프로세스 이름으로 죽이면 안 된다. 실제로 3000 포트를 쥐고 있는 것은
    `node dist/src/main.js` 라서 'nest start' 패턴에 걸리지 않았고, 새 서버가
    EADDRINUSE 로 죽는 동안 원본 서버가 계속 응답해 주입이 반영되지 않았다.
    포트 기준으로 죽이고, dist 를 다시 빌드해야 소스 변경이 실제로 반영된다.
    """
    server_dir = os.path.join(ROOT, "server")
    run("lsof -ti tcp:3000 | xargs kill -9 2>/dev/null || true")
    run("sleep 2")

    built = run("npm run build", cwd=server_dir)
    if built.returncode != 0:
        print(built.stdout[-1500:])
        raise SystemExit("서버 빌드 실패")

    subprocess.Popen("node dist/src/main.js > /tmp/kg_server.log 2>&1",
                     cwd=server_dir, shell=True)
    for _ in range(60):
        if run("curl -s --max-time 2 http://127.0.0.1:3000/api/v1/health").stdout.strip():
            return
        run("sleep 2")
    raise SystemExit("서버가 뜨지 않음")


def apply_target(inj):
    build_app() if inj["대상"] == "app" else restart_server()


def pytest_run(names):
    """지정한 케이스만 돌리고 케이스별 결과를 돌려준다.

    콘솔 출력을 파싱하면 안 된다. 실패 시 스크린샷 훅이 한 줄을 끼워 넣어서
    FAILED 가 테스트 이름과 다른 줄로 밀린다. 그 탓에 실패를 통째로 못 읽고
    전부 통과로 집계한 적이 있다. junit XML 로 읽는다.
    """
    report = "/tmp/kg_mutation_report.xml"
    args = [os.path.join(TESTS, ".venv/bin/python"), "-m", "pytest", "tests/",
            "-q", "--tb=no", "--runxfail", "-k", " or ".join(names),
            f"--junitxml={report}"]
    subprocess.run(args, cwd=TESTS, capture_output=True, text=True)

    results = {}
    tree = ElementTree.parse(report)
    for case in tree.iter("testcase"):
        name = case.get("name", "").split("[")[0]
        state = "PASSED"
        for child in case:
            if child.tag in ("failure", "error"):
                state = "FAILED"
            elif child.tag == "skipped":
                state = "SKIPPED"
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
        restore(inj)

    caught, missed, collateral = [], [], []
    for t in expected:
        (caught if results.get(t) in ("FAILED", "ERROR") else missed).append(t)
    for c in controls:
        if results.get(c) in ("FAILED", "ERROR"):
            collateral.append(c)

    print(f"  잡음   {len(caught)}/{len(expected)}")
    for t in caught:
        print(f"    O {t}")
    for t in missed:
        print(f"    X {t}  <- 고장을 심었는데 통과했다. 검출력 없음")
    if collateral:
        for c in collateral:
            print(f"    ! {c}  <- 무관한데 같이 터졌다. 과잉 결합")
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
    summary = []
    try:
        for name in names:
            summary.append(check(name))
    finally:
        print("\n원상복구 후 재빌드 중...")
        for name in names:
            restore(INJECTIONS[name])
        build_app()
        restart_server()
        print("복구 완료")

    print(f"\n{'=' * 62}\n음성 대조 종합\n{'=' * 62}")
    for s in summary:
        state = "통과" if not s["missed"] and not s["collateral"] else "확인 필요"
        print(f"  {s['name']:24s} 잡음 {len(s['caught'])}건  "
              f"놓침 {len(s['missed'])}건  과잉 {len(s['collateral'])}건  {state}")


if __name__ == "__main__":
    main()
