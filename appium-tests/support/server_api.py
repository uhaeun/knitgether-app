"""서버 케이스가 쓰는 계정 유틸.

qa/api-tests 의 방식을 그대로 따른다. 실행마다 고유 이메일을 만들어 기존 수동 QA 데이터를
건드리지 않는다. npm run db:reset-test 는 모든 사용자 데이터를 지우므로 쓰지 않는다.
"""
import os
import time
import uuid
from datetime import datetime, timezone

import requests

BASE_URL = os.environ.get("KG_API_BASE_URL", "http://127.0.0.1:3000/api/v1")
PASSWORD = "appium-pass-1234"


def new_email():
    return f"appium-{int(time.time())}-{uuid.uuid4().hex[:8]}@example.com"


def register(email=None, password=PASSWORD, display_name="자동화계정"):
    """서버에 계정을 미리 만들어 둔다. 로그인 케이스의 Given 용."""
    email = email or new_email()
    res = requests.post(f"{BASE_URL}/auth/register",
                        json={"email": email, "password": password, "displayName": display_name},
                        timeout=15)
    res.raise_for_status()
    return {"email": email, "password": password, "displayName": display_name,
            "token": res.json()["accessToken"]}


def create_project(token, name):
    """다른 계정 소유의 프로젝트를 서버에 만들어 둔다. 계정 격리 검증의 Given."""
    # 필드 구성은 qa/api-tests/helpers.py 의 검증된 빌더를 따른다.
    # 서버가 forbidNonWhitelisted 라 정의에 없는 필드를 넣으면 400 이다.
    project_id = str(uuid.uuid4())
    body = {
        "id": project_id, "name": name, "status": "WIP",
        "isFavorite": False, "memo": "",
        "startDate": datetime.now(timezone.utc).replace(microsecond=0)
                            .isoformat().replace("+00:00", "Z"),
        "relatedSkillIds": [],
        "rowCounter": {"id": str(uuid.uuid4()), "projectId": project_id,
                       "name": "메인", "currentRow": 0},
        "workSessions": [],
    }
    res = requests.post(f"{BASE_URL}/projects", json=body,
                        headers={"Authorization": f"Bearer {token}"}, timeout=15)
    res.raise_for_status()
    return project_id


def create_skill(token, name):
    """스킬을 서버에 만들어 둔다. 캐시 프루닝(DEF-09/API-22) 검증의 Given.

    필드 구성은 서버 DTO(SaveSkillDto: name/abbreviation/description 필수)를 따른다.
    """
    skill_id = str(uuid.uuid4())
    body = {
        "id": skill_id, "name": name,
        "abbreviation": name[:4], "description": f"{name} 설명",
    }
    res = requests.post(f"{BASE_URL}/skills", json=body,
                        headers={"Authorization": f"Bearer {token}"}, timeout=15)
    res.raise_for_status()
    return res.json()["id"]


def delete_skill(token, skill_id):
    """스킬을 서버에서 소프트 삭제한다."""
    res = requests.delete(f"{BASE_URL}/skills/{skill_id}",
                          headers={"Authorization": f"Bearer {token}"}, timeout=15)
    res.raise_for_status()


def health_ok(base_url=None):
    try:
        return requests.get(f"{base_url or BASE_URL}/health", timeout=5).status_code == 200
    except requests.RequestException:
        return False
