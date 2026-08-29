"""07이 06에서 이관받은 3건. 화면으로는 판정할 수 없어 넘어온 항목들이다.

    SYNC-03  원격 반영은 synced 항목이면 PATCH, 아니면 POST를 쓴다
    AUTH-01  토큰은 Keychain에 저장되고 만료는 설정을 따르며 기본 30일이다
    RC-08    연결 해제 시 서버 파일이 고아로 남는가

셋 다 화면에 안 나오는 것을 본다. SYNC-03은 어떤 HTTP 동사를 썼는지, AUTH-01은
토큰 안에 든 만료 시각, RC-08은 디스크에 남은 파일이다.

RC-08은 03에서 치명도 축 밖 운영 리스크로 빼면서 "07에서 psql과 server/storage
대조로 실증한다"고 지정한 항목이다. 응답, DB, 파일 세 층을 모두 봐야 잡히는
유일한 케이스다.
"""
import base64
import os
from pathlib import Path

import pytest

from helpers import project_payload, uid

SERVER_ROOT = Path(__file__).resolve().parents[2] / "server"


def _storage_root():
    """서버가 실제로 파일을 쓰는 경로.

    FILE_STORAGE_ROOT는 서버가 자기 작업 디렉터리 기준으로 푸는 값이라
    상대경로면 서버 루트에 붙여야 한다. pytest의 작업 디렉터리를 기준으로
    풀면 CI에서 엉뚱한 곳을 보고 조용히 skip된다.
    """
    configured = (os.environ.get("FILE_STORAGE_ROOT") or "").strip()
    if not configured:
        return SERVER_ROOT / "storage"
    path = Path(configured)
    return path if path.is_absolute() else (SERVER_ROOT / path).resolve()


STORAGE_ROOT = _storage_root()

# 최소 유효 PDF. 파일 내용이 아니라 저장 여부가 검증 대상이라 이걸로 충분하다.
TINY_PDF = base64.b64decode(
    b"JVBERi0xLjQKMSAwIG9iajw8L1R5cGUvQ2F0YWxvZy9QYWdlcyAyIDAgUj4+ZW5kb2JqCjIgMCBv"
    b"Ymo8PC9UeXBlL1BhZ2VzL0tpZHNbMyAwIFJdL0NvdW50IDE+PmVuZG9iagozIDAgb2JqPDwvVHlw"
    b"ZS9QYWdlL1BhcmVudCAyIDAgUi9NZWRpYUJveFswIDAgOTkgOTldPj5lbmRvYmoKdHJhaWxlcjw8"
    b"L1Jvb3QgMSAwIFI+Pg=="
)


def _payload_with_pattern(name):
    payload = project_payload(name=name)
    pid = payload["id"]
    payload["patternCopy"] = {
        "id": uid(),
        "projectId": pid,
        "sourcePatternDocumentId": None,
        "titleSnapshot": "RC08-도안",
        "designerSnapshot": None,
        "fileNameSnapshot": "rc08.pdf",
        "localCopyPath": None,
        "copiedAt": "2026-08-29T00:00:00.000Z",
    }
    return payload


def _storage_key(db, pid):
    with db.cursor() as cur:
        cur.execute(
            'SELECT "fileStorageKey", "deletedAt" FROM "ProjectPatternCopy" '
            'WHERE "projectId" = %s', (pid,))
        return cur.fetchone()


# ---------------------------------------------------------------- SYNC-03

def test_sync_03_post_upserts_and_patch_requires_existing(account_a):
    """클라이언트의 POST와 PATCH 분기가 기대는 서버 계약을 고정한다.

    클라이언트는 synced 항목이면 PATCH, 아니면 POST를 쓴다
    (`RemoteProjectRepository.swift:34`). 어떤 동사를 골랐는지는 서버에서 볼 수
    없으므로, 여기서는 그 분기가 성립하려면 서버가 무엇을 보장해야 하는지를
    검증한다. 분기가 어긋나도 데이터가 깨지지 않아야 offline-first가 성립한다.
    """
    payload = project_payload(name="SYNC03-분기")
    pid = payload["id"]

    # 아직 없는 항목에 PATCH를 보내면 서버는 거부해야 한다. 클라이언트가 synced로
    # 잘못 판단했을 때 조용히 새로 만들어 버리면 유실을 알아챌 수 없다.
    missing = account_a.api.patch(f"/projects/{uid()}", json=project_payload(name="없는것"))
    assert missing.status_code in (400, 404), (
        f"없는 항목에 PATCH가 {missing.status_code}로 통과했다. "
        "클라이언트 분기가 틀려도 서버가 받아주면 유실이 조용해진다"
    )

    # POST는 클라이언트 생성 UUID를 그대로 쓰는 upsert여야 한다. 재전송이
    # 일어나는 구조라 두 번 보내도 한 건이어야 한다.
    assert account_a.api.create_project(payload).status_code == 201
    again = account_a.api.create_project(payload)
    assert again.status_code in (200, 201, 409), again.text
    assert account_a.api.get(f"/projects/{pid}").status_code == 200


# ---------------------------------------------------------------- AUTH-01

def test_auth_01_token_expiry_follows_setting(account_a):
    """토큰 만료가 설정을 따르는가. 기본값은 30일이다.

    저장 위치(Keychain)는 클라이언트 쪽이라 여기서 볼 수 없다. 그쪽은 08의
    simctl 경로가 담당한다. 이 테스트는 서버가 발급하는 만료 시각만 본다.

    발급 시각(iat)이 클레임에 없어 수명을 직접 뺄 수 없다. 방금 발급받은
    토큰이므로 현재 시각을 발급 시각으로 보고 계산한다. 그래서 하루치 여유를 둔다.
    """
    import json
    import time

    parts = account_a.token.split(".")
    assert len(parts) == 3, "JWT 형식이 아니다"

    body = parts[1] + "=" * (-len(parts[1]) % 4)
    claims = json.loads(base64.urlsafe_b64decode(body))
    assert "exp" in claims, f"만료 클레임이 없다: {list(claims)}"

    configured = os.environ.get("AUTH_JWT_EXPIRES_IN_SECONDS")
    expected = int(configured) if configured else 60 * 60 * 24 * 30
    remaining = claims["exp"] - time.time()

    assert abs(remaining - expected) < 86400, (
        f"토큰 잔여 수명이 {remaining / 86400:.1f}일인데 설정은 "
        f"{expected / 86400:.1f}일이다. `access-token.service.ts:117` 과 어긋난다"
    )


# ---------------------------------------------------------------- RC-08

def test_rc_08_deleted_project_leaves_pattern_file_on_disk(account_a, db):
    """프로젝트를 지우면 도안 PDF가 디스크에 고아로 남는가.

    응답, DB, 파일 세 층을 순서대로 본다. 앞 두 층만 보면 삭제가 정상으로
    보이기 때문에, 파일 층을 봐야만 드러나는 결함이다.
    """
    if not STORAGE_ROOT.exists():
        pytest.skip(f"스토리지 경로가 없다: {STORAGE_ROOT}")

    payload = _payload_with_pattern("RC08-고아")
    pid = payload["id"]
    assert account_a.api.create_project(payload).status_code == 201

    up = account_a.api.s.post(
        f"{account_a.api.base}/projects/{pid}/pattern-copy/file",
        headers={"Authorization": f"Bearer {account_a.token}"},
        files={"file": ("rc08.pdf", TINY_PDF, "application/pdf")}, timeout=15)
    assert up.status_code in (200, 201), up.text

    key, deleted_at = _storage_key(db, pid)
    assert key, "업로드했는데 DB에 fileStorageKey가 없다"
    path = STORAGE_ROOT / key
    assert path.exists(), f"DB에는 키가 있는데 디스크에 파일이 없다: {path}"
    assert deleted_at is None

    # 1층 응답: 삭제는 성공한다
    assert account_a.api.delete(f"/projects/{pid}").status_code == 204

    # 2층 DB: 소프트 삭제로 표시된다. 여기까지만 보면 정상이다
    key_after, deleted_after = _storage_key(db, pid)
    assert deleted_after is not None, "삭제했는데 deletedAt이 안 찍혔다"

    # 3층 파일: 남아 있다. 이것이 RC-08이다
    assert path.exists(), (
        "파일이 삭제됐다. RC-08이 해소된 것이므로 03과 10의 기재를 갱신할 것"
    )


def test_rc_08_orphan_census(db):
    """현재 스토리지에 고아 파일이 몇 개인지 센다. 실측 규모를 기록한다.

    개별 재현과 별개로 누적 규모를 남긴다. 운영 리스크는 건당 심각도가 아니라
    쌓이는 속도로 판단해야 하기 때문이다.
    """
    if not STORAGE_ROOT.exists():
        pytest.skip(f"스토리지 경로가 없다: {STORAGE_ROOT}")

    on_disk = {
        str(p.relative_to(STORAGE_ROOT))
        for p in STORAGE_ROOT.rglob("*")
        if p.is_file() and ".omc" not in p.parts
    }

    referenced = set()
    with db.cursor() as cur:
        for sql in (
            'SELECT "fileStorageKey" FROM "ProjectPatternCopy" '
            'WHERE "fileStorageKey" IS NOT NULL AND "deletedAt" IS NULL',
            'SELECT "drawingStorageKey" FROM "ProjectPatternCopy" '
            'WHERE "drawingStorageKey" IS NOT NULL AND "deletedAt" IS NULL',
        ):
            cur.execute(sql)
            referenced.update(r[0] for r in cur.fetchall())

    orphans = on_disk - referenced
    print(f"\n[RC-08 실측] 디스크 {len(on_disk)}건, 살아있는 참조 {len(referenced)}건, "
          f"고아 {len(orphans)}건")

    # 판정이 아니라 기록이다. 고아가 0이 되면 RC-08이 해소된 것이므로 그때 이
    # 단언을 뒤집어 회귀 감시로 쓴다.
    assert len(on_disk) >= 0
