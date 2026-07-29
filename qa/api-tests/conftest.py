"""
산출물 3 — API 정합성 테스트 하네스 (conftest).

★ 미션: 기존 서버 e2e(Jest)는 12개 중 9개가 mock Prisma(인메모리)라
  실 DB 정합성(ownerId 격리·soft delete·cascade·트랜잭션 원자성·제약)을
  아무도 검증하지 않는다. 이 계층은 **실행 중인 서버 + 실 Postgres**를
  black-box HTTP로 때려 그 공백을 메운다. 각 테스트는 v2.3 스펙 조항을
  docstring에 명시하고, 실패는 결함 후보로 '보고'한다(여기서 고치지 않음).

전제:
- 서버가 API_BASE_URL(기본 http://127.0.0.1:3000/api/v1)에서 기동 중
- Postgres가 DB_* 접속 정보로 접근 가능(기본 localhost:5433 knitgether_dev)
실행:
    pip install -r requirements.txt
    pytest -v
"""
from __future__ import annotations

import os
import time
import uuid
from dataclasses import dataclass

import psycopg2
import pytest
import requests

from helpers import Api

API_BASE_URL = os.environ.get("API_BASE_URL", "http://127.0.0.1:3000/api/v1")

DB = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": int(os.environ.get("DB_PORT", "5433")),
    "user": os.environ.get("DB_USER", "knitgether"),
    "password": os.environ.get("DB_PASSWORD", "knitgether"),
    "dbname": os.environ.get("DB_NAME", "knitgether_dev"),
}

PASSWORD = "pytest-pass-1234"
_registered_emails: list[str] = []


@dataclass
class Account:
    email: str
    token: str
    user_id: str
    api: Api


@pytest.fixture(scope="session")
def base_url() -> str:
    return API_BASE_URL


@pytest.fixture(scope="session", autouse=True)
def _require_server():
    """서버가 안 떠 있으면 즉시 명확히 실패(환경 문제와 결함을 구분)."""
    try:
        r = requests.get(f"{API_BASE_URL}/health", timeout=5)
        assert r.status_code == 200
    except Exception as exc:  # noqa: BLE001
        pytest.exit(f"서버 무응답 — 먼저 `npm run start:dev` 필요 ({exc})", returncode=2)


@pytest.fixture(scope="session")
def db():
    conn = psycopg2.connect(**DB)
    conn.autocommit = True
    yield conn
    conn.close()


def _register(email: str) -> Account:
    r = requests.post(
        f"{API_BASE_URL}/auth/register",
        json={"email": email, "password": PASSWORD, "displayName": "pytest", "preferredUnits": "cm"},
        timeout=15,
    )
    assert r.status_code in (200, 201), f"register 실패: {r.status_code} {r.text}"
    token = r.json()["accessToken"]
    _registered_emails.append(email)
    me = requests.get(f"{API_BASE_URL}/auth/me", headers={"Authorization": f"Bearer {token}"}, timeout=15)
    assert me.status_code == 200, me.text
    user_id = me.json()["id"]
    return Account(email=email, token=token, user_id=user_id, api=Api(API_BASE_URL, token))


def _new_email() -> str:
    return f"pytest-{int(time.time())}-{uuid.uuid4().hex[:8]}@example.com"


@pytest.fixture(scope="session")
def account_a() -> Account:
    return _register(_new_email())


@pytest.fixture(scope="session")
def account_b() -> Account:
    return _register(_new_email())


@pytest.fixture(scope="session", autouse=True)
def _teardown_accounts():
    """세션 종료 시 이 실행이 만든 계정만 cascade 삭제(수동 QA 데이터 불침해)."""
    yield
    if not _registered_emails:
        return
    conn = psycopg2.connect(**DB)
    conn.autocommit = True
    try:
        with conn.cursor() as cur:
            # UserAccount.id == UserProfile.id, 계정→프로필 onDelete:Cascade.
            # 프로필 삭제가 프로필 소유 데이터 전체를 cascade 제거한다.
            cur.execute(
                'DELETE FROM "UserProfile" WHERE id IN '
                '(SELECT a.id FROM "UserAccount" a WHERE a.email = ANY(%s));',
                (_registered_emails,),
            )
    finally:
        conn.close()
