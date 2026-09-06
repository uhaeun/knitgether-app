"""API-23, API-24. 창고 경로 도안의 서버 파일 키 정합성과 교체 후 드로잉 정리.

API-23 (DEF-13, `a74945a` 수정): 창고 경로(`PatternDocument`)로 도안을 연결하면
`ProjectPatternCopy.fileStorageKey`가 채워져야 한다. `projects.service.ts:1601-1632`
(`saveProjectPatternCopy`의 `materializedFileInput`) 실측: 창고 경로 연결은 파일
업로드 없이 메타만 오므로, 서버가 원본 `StoredFile`을 읽어 프로젝트 전용 키로
물리 복사한다("결함 19/38" 주석). `fileStorageKey`가 null이 아닌 것만으로는
부족하다. 실제 파일이 디스크에 있어야 복사가 진짜 일어난 것이다.

API-24 (DEF-14, `0109898` 수정): 도안을 다른 도안으로 교체하면(=`patternCopy.id`가
바뀌면) `projects.service.ts:1634-1653`는 기존 행을 하드 삭제하고 새 행을
만든다("결함 37" 주석). `drawingStorageKey`는 `SaveProjectPatternCopyDto`에 없는
필드라 새 행에 절대 계승되지 않는다. 단, 같은 소스코드 주석이 "교체로 참조가
끊긴 물리 파일 정리는 RC-08에서 별도로 다룬다"고 명시한다. 즉 DB 참조 절단과
물리 파일 삭제는 서로 다른 동작이고, 이 사이클 기준 물리 파일은 지워지지
않는다. 두 판정을 분리해서 본다.
"""
import base64
import os
from pathlib import Path

from helpers import project_payload, uid

SERVER_ROOT = Path(__file__).resolve().parents[2] / "server"

# 최소 유효 PDF. test_09_transferred_from_06.py의 TINY_PDF와 동일한 최소 구성.
TINY_PDF = base64.b64decode(
    b"JVBERi0xLjQKMSAwIG9iajw8L1R5cGUvQ2F0YWxvZy9QYWdlcyAyIDAgUj4+ZW5kb2JqCjIgMCBv"
    b"Ymo8PC9UeXBlL1BhZ2VzL0tpZHNbMyAwIFJdL0NvdW50IDE+PmVuZG9iagozIDAgb2JqPDwvVHlw"
    b"ZS9QYWdlL1BhcmVudCAyIDAgUi9NZWRpYUJveFswIDAgOTkgOTldPj5lbmRvYmoKdHJhaWxlcjw8"
    b"L1Jvb3QgMSAwIFI+Pg=="
)

TINY_DRAWING = b"KNITGETHER-PKDRAWING-STUB-BYTES"


def _storage_root():
    """서버가 실제로 파일을 쓰는 경로. FILE_STORAGE_ROOT는 서버 작업 디렉터리 기준
    상대경로라 서버 루트에 붙여야 한다 (test_09와 동일한 규칙)."""
    configured = (os.environ.get("FILE_STORAGE_ROOT") or "").strip()
    if not configured:
        return SERVER_ROOT / "storage"
    path = Path(configured)
    return path if path.is_absolute() else (SERVER_ROOT / path).resolve()


STORAGE_ROOT = _storage_root()


def _create_library_pattern(account, title):
    """창고(도안 라이브러리)에 PDF가 첨부된 PatternDocument를 만들고 id를 반환한다."""
    r = account.api.s.post(
        f"{account.api.base}/patterns",
        headers={"Authorization": f"Bearer {account.token}"},
        data={"title": title},
        files={"file": (f"{title}.pdf", TINY_PDF, "application/pdf")},
        timeout=15,
    )
    assert r.status_code in (200, 201), f"창고 도안 생성 실패: {r.status_code} {r.text}"
    return r.json()["id"]


def _pattern_copy_row(db, project_id):
    with db.cursor() as cur:
        cur.execute(
            'SELECT id, "fileStorageKey", "fileContentType", "fileByteSize", '
            '"drawingStorageKey" FROM "ProjectPatternCopy" WHERE "projectId" = %s',
            (project_id,),
        )
        return cur.fetchone()


def _row_by_copy_id(db, copy_id):
    with db.cursor() as cur:
        cur.execute('SELECT id FROM "ProjectPatternCopy" WHERE id = %s', (copy_id,))
        return cur.fetchone()


# ---------------------------------------------------------------- API-23

def test_api_23_library_linked_pattern_gets_server_file_key(account_a, db):
    pattern_id = _create_library_pattern(account_a, "API23-창고도안")

    payload = project_payload(name="API23-프로젝트")
    pid = payload["id"]
    payload["patternCopy"] = {
        "id": uid(),
        "projectId": pid,
        "sourcePatternDocumentId": pattern_id,
        "titleSnapshot": "API23-창고도안",
        "designerSnapshot": None,
        "fileNameSnapshot": "api23.pdf",
        "localCopyPath": None,
        "copiedAt": "2026-08-31T00:00:00.000Z",
    }

    created = account_a.api.create_project(payload)
    assert created.status_code == 201, created.text
    # 1층: 응답에는 서버 파일 키 자체가 노출되지 않는다 (project-response.dto.ts에
    # fileStorageKey가 없다). 응답으로는 연결 성사 여부만 확인할 수 있다.
    assert created.json()["patternCopy"]["sourcePatternDocumentId"] == pattern_id

    row = _pattern_copy_row(db, pid)
    assert row is not None, "ProjectPatternCopy 행이 생성되지 않았다"
    _copy_id, file_key, content_type, byte_size, _drawing_key = row

    assert file_key is not None, (
        "창고 경로로 연결했는데 fileStorageKey가 null이다 (DEF-13 재발)"
    )
    assert content_type == "application/pdf"
    assert byte_size == len(TINY_PDF), "저장된 byteSize가 실제 업로드 크기와 다르다"

    # 3층: null이 아닌 것만으로는 부족하다. 실제 파일이 디스크에 있어야 한다.
    file_path = STORAGE_ROOT / file_key
    assert file_path.exists(), (
        f"DB에는 fileStorageKey가 있는데 디스크에 파일이 없다: {file_path}. "
        f"STORAGE_ROOT({STORAGE_ROOT})가 서버가 쓰는 경로와 다를 수 있다"
    )
    assert file_path.read_bytes() == TINY_PDF, "디스크 파일 내용이 원본 창고 PDF와 다르다"


# ---------------------------------------------------------------- API-24

def test_api_24_pattern_replace_severs_db_reference_but_leaves_old_file(account_a, db):
    pattern_a = _create_library_pattern(account_a, "API24-원본도안")
    pattern_b = _create_library_pattern(account_a, "API24-교체도안")

    payload = project_payload(name="API24-프로젝트")
    pid = payload["id"]
    copy_a_id = uid()
    payload["patternCopy"] = {
        "id": copy_a_id,
        "projectId": pid,
        "sourcePatternDocumentId": pattern_a,
        "titleSnapshot": "API24-원본도안",
        "designerSnapshot": None,
        "fileNameSnapshot": "api24-a.pdf",
        "localCopyPath": None,
        "copiedAt": "2026-08-31T00:00:00.000Z",
    }
    assert account_a.api.create_project(payload).status_code == 201

    # 사전조건: 교체 전에 원본 복사본에 실제로 드로잉이 있어야 "정리됐는지" 검증이 의미 있다
    drawing_up = account_a.api.s.post(
        f"{account_a.api.base}/projects/{pid}/pattern-copy/drawing",
        headers={"Authorization": f"Bearer {account_a.token}"},
        files={"file": ("drawing.pkdrawing", TINY_DRAWING, "application/octet-stream")},
        timeout=15,
    )
    assert drawing_up.status_code in (200, 201), drawing_up.text

    before = _pattern_copy_row(db, pid)
    assert before is not None
    _copy_id_before, file_key_before, _ct, _bs, drawing_key_before = before
    assert _copy_id_before == copy_a_id
    assert file_key_before is not None, "사전조건 실패: 교체 전 fileStorageKey가 비어 있다"
    assert drawing_key_before is not None, "사전조건 실패: 교체 전 drawingStorageKey가 비어 있다"

    old_drawing_path = STORAGE_ROOT / drawing_key_before
    assert old_drawing_path.exists(), "사전조건 실패: 교체 전 드로잉 파일이 디스크에 없다"

    # ---- 도안 B로 교체: patternCopy.id를 바꿔 replace 분기(existing.id !== copy.id)를 태운다 ----
    replace_payload = project_payload(project_id=pid, name="API24-프로젝트")
    replace_payload["id"] = pid
    copy_b_id = uid()
    replace_payload["patternCopy"] = {
        "id": copy_b_id,
        "projectId": pid,
        "sourcePatternDocumentId": pattern_b,
        "titleSnapshot": "API24-교체도안",
        "designerSnapshot": None,
        "fileNameSnapshot": "api24-b.pdf",
        "localCopyPath": None,
        "copiedAt": "2026-08-31T01:00:00.000Z",
    }
    replaced = account_a.api.patch_project(pid, replace_payload)
    assert replaced.status_code == 200, replaced.text
    assert replaced.json()["patternCopy"]["sourcePatternDocumentId"] == pattern_b

    # ---- DB 참조 정리 판정 ----
    assert _row_by_copy_id(db, copy_a_id) is None, (
        "교체 뒤에도 이전 ProjectPatternCopy 행(copy A)이 남아 있다. "
        "하드 삭제+재생성 계약(DEF-14 수정)과 다르다"
    )

    after = _pattern_copy_row(db, pid)
    assert after is not None
    copy_id_after, file_key_after, _ct2, _bs2, drawing_key_after = after
    assert copy_id_after == copy_b_id, "교체 후 행의 id가 새 copy id가 아니다"
    assert file_key_after is not None, "교체된 도안(B)의 fileStorageKey가 비어 있다"
    assert drawing_key_after != drawing_key_before, (
        "새 행이 이전 드로잉 키를 그대로 물려받았다 (결함 37 재발)"
    )
    assert drawing_key_after is None, (
        "새 행에 drawingStorageKey가 채워져 있다. SaveProjectPatternCopyDto에 없는 필드라 "
        "채워질 수 없어야 하는데 값이 있다면 계약이 바뀐 것이다"
    )

    # ---- 물리 파일 정리 판정 (DB 판정과 분리) ----
    # 코드 주석이 명시하듯 이 경로는 참조만 끊고 파일은 지우지 않는다(RC-08로 이관).
    # 파일이 사라져 있다면 RC-08이 해소된 것이므로 이 단언과 07/10의 기재를 갱신할 것.
    assert old_drawing_path.exists(), (
        "이전 드로잉 파일이 디스크에서 사라졌다. RC-08 정리 경로가 생겼다면 이 테스트와 "
        "07/09_test_case_master.md의 'DB 참조 정리와 물리 파일 삭제는 다른 동작' 기재를 갱신할 것"
    )
