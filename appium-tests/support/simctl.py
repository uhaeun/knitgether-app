"""시뮬레이터 컨테이너 조작.

로컬 모드는 KNITGETHER_LOCAL_CACHE_DIRECTORY가 먹지 않는다(그건 서버 모드 전용,
AppRepositoryContainer.swift:295-327). 그래서 로컬 케이스의 격리와 시딩은
컨테이너의 저장 파일을 직접 다룬다.
"""
import json
import os
import shutil
import subprocess

UDID = os.environ.get("KG_UDID", "3E4280D4-3E27-42E0-9C35-E84B24E08BD1")
BUNDLE_ID = "com.uhaeun.KnitGether"

STORE_FILES = (
    "projects.json", "library.json", "patterns.json", "skills.json",
    "dictionary-terms.json", "profile.json", "gauge-records.json",
    "gauge-targets.json", "progress-photos.json", "sample-patterns-v1.seeded",
)


def _simctl(*args):
    return subprocess.run(["xcrun", "simctl", *args],
                          capture_output=True, text=True, check=True).stdout.strip()


def data_container():
    return _simctl("get_app_container", UDID, BUNDLE_ID, "data")


def store_dir():
    return os.path.join(data_container(), "Library", "Application Support", "KnitGether")


def files_dir():
    """앱이 도안 PDF와 진행 사진 원본을 두는 곳."""
    return os.path.join(data_container(), "Documents", "KnitGetherFiles")


def wipe_store():
    """저장 파일과 첨부 파일을 전부 지운다. 다음 실행에서 앱이 샘플을 다시 심는다."""
    d = store_dir()
    for name in STORE_FILES:
        try:
            os.remove(os.path.join(d, name))
        except FileNotFoundError:
            pass
    shutil.rmtree(files_dir(), ignore_errors=True)


def reset_keychain():
    """시뮬레이터 Keychain을 비운다.

    로그인 토큰은 파일이 아니라 Keychain에 있어서(AuthSessionStore.swift:96-126)
    저장 파일만 지워서는 이전 계정 세션이 그대로 살아 있다. 앱 재설치보다 훨씬 빠르다.
    """
    _simctl("keychain", UDID, "reset")


def put_pattern_file(relative_path, source):
    """도안 PDF를 앱이 기대하는 상대 경로에 놓는다 (localCopyPath 기준)."""
    dest = os.path.join(files_dir(), relative_path)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copyfile(source, dest)
    return dest


def write_store(name, payload):
    d = store_dir()
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, name), "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)


def read_store(name):
    with open(os.path.join(store_dir(), name), encoding="utf-8") as f:
        return json.load(f)


def add_photo(path):
    """사진 라이브러리에 이미지를 넣는다 (UI-57 진행 사진용)."""
    _simctl("addmedia", UDID, path)


def grant_permissions():
    """카메라와 사진 권한을 미리 준다.

    권한 다이얼로그는 시스템 알럿이라 앱 화면을 통째로 막는다. autoAcceptAlerts로 뭉개면
    앱 자신의 확인창(삭제 확인 등)까지 눌러버려 삭제 케이스가 무력화되므로, 권한만 사전 부여한다.
    """
    for service in ("camera", "photos"):
        subprocess.run(["xcrun", "simctl", "privacy", UDID, "grant", service, BUNDLE_ID],
                       capture_output=True, text=True)


def _app_group_dir(identifier):
    """앱 그룹 컨테이너를 식별자로 찾는다. UUID는 시뮬레이터마다 달라 고정할 수 없다."""
    root = os.path.join(os.path.expanduser("~"), "Library", "Developer", "CoreSimulator",
                        "Devices", UDID, "data", "Containers", "Shared", "AppGroup")
    for entry in os.listdir(root):
        meta = os.path.join(root, entry, ".com.apple.mobile_container_manager.metadata.plist")
        try:
            got = subprocess.run(["plutil", "-extract", "MCMMetadataIdentifier", "raw", meta],
                                 capture_output=True, text=True, check=True).stdout.strip()
        except subprocess.CalledProcessError:
            continue
        if got == identifier:
            return os.path.join(root, entry)
    raise LookupError(identifier)


def put_file_on_my_iphone(path):
    """파일 앱의 '내 iPhone'에 파일을 놓는다 (UI-40, 41 문서 피커용)."""
    dest_dir = os.path.join(_app_group_dir("group.com.apple.FileProvider.LocalStorage"),
                            "File Provider Storage")
    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, os.path.basename(path))
    shutil.copyfile(path, dest)
    return dest
