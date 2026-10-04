"""창고 사진의 실제 업로드, 교체, 삭제 및 계정 격리를 API와 DB 및 파일로 검증한다."""
import base64
import os
from pathlib import Path

import pytest
import requests

from helpers import bearer

PNG = base64.b64decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC'
)
REPLACEMENT_PNG = base64.b64decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC'
)
RESOURCES = [
    ('yarns', 'Yarn', {'name': '사진 검증', 'quantity': 1}),
    ('needles', 'Needle', {'name': '사진 검증', 'needleType': 'circular', 'size': '4mm'}),
    ('tools', 'ToolItem', {'name': '사진 검증', 'type': '가위'}),
]


def _stored(db, table, item_id):
    with db.cursor() as cur:
        cur.execute(f'SELECT "photoStorageKey", "photoByteSize" FROM "{table}" WHERE id=%s', (item_id,))
        return cur.fetchone()


def _upload(account, url, content=PNG, mime='image/png'):
    return requests.post(url, headers=bearer(account.token), files={'file': ('qa.png', content, mime)}, timeout=15)


@pytest.mark.parametrize('path,table,payload', RESOURCES, ids=[r[0] for r in RESOURCES])
def test_library_photo_roundtrip_replacement_deletion_and_owner_isolation(account_a, account_b, db, path, table, payload):
    created = account_a.api.post(f'/library/{path}', json=payload)
    assert created.status_code == 201, created.text
    item_id = created.json()['id']
    endpoint = f'/library/{path}/{item_id}/photo'
    url = account_a.api.base + endpoint
    storage = Path(os.environ.get('FILE_STORAGE_ROOT') or 'storage')
    if not storage.is_absolute():
        storage = Path(__file__).resolve().parents[2] / 'server' / storage

    uploaded = _upload(account_a, url)
    assert uploaded.status_code == 201, uploaded.text
    key, size = _stored(db, table, item_id)
    assert size == len(PNG) and (storage / key).read_bytes() == PNG
    downloaded = account_a.api.get(endpoint)
    assert downloaded.status_code == 200 and downloaded.content == PNG
    assert downloaded.headers['Content-Type'].startswith('image/png')

    assert account_b.api.get(endpoint).status_code == 404
    assert _upload(account_b, url).status_code == 404
    assert account_b.api.delete(endpoint).status_code == 404
    assert _stored(db, table, item_id) == (key, size)
    assert account_a.api.get(endpoint).content == PNG

    replaced = _upload(account_a, url, REPLACEMENT_PNG)
    assert replaced.status_code == 201, replaced.text
    new_key, new_size = _stored(db, table, item_id)
    assert new_key != key and new_size == len(REPLACEMENT_PNG)
    assert not (storage / key).exists(), '교체 전 파일이 남음'
    assert (storage / new_key).read_bytes() == REPLACEMENT_PNG
    assert account_a.api.get(endpoint).content == REPLACEMENT_PNG

    deleted = account_a.api.delete(endpoint)
    assert deleted.status_code == 200, deleted.text
    assert _stored(db, table, item_id) == (None, None)
    assert not (storage / new_key).exists(), '사진 삭제 후 파일이 남음'
    assert account_a.api.get(endpoint).status_code == 404


@pytest.mark.parametrize('path,table,payload', RESOURCES, ids=[r[0] for r in RESOURCES])
def test_invalid_or_missing_photo_preserves_existing_photo(account_a, db, path, table, payload):
    created = account_a.api.post(f'/library/{path}', json=payload)
    assert created.status_code == 201, created.text
    item_id = created.json()['id']
    endpoint = f'/library/{path}/{item_id}/photo'
    url = account_a.api.base + endpoint
    assert _upload(account_a, url).status_code == 201
    original = _stored(db, table, item_id)
    assert _upload(account_a, url, b'not an image', 'text/plain').status_code == 400
    missing = requests.post(url, headers=bearer(account_a.token), timeout=15)
    assert missing.status_code == 400, missing.text
    assert _stored(db, table, item_id) == original
    assert account_a.api.get(endpoint).content == PNG
