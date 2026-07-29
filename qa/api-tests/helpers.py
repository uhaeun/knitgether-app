"""
공용 헬퍼: API 래퍼 + 유효한 Project 페이로드 빌더.

서버 계약(2026-07-29 소스 확인):
- 생성/수정 엔드포인트는 `SaveProjectDto`(client-provided UUID) 사용.
- 전역 ValidationPipe: whitelist + forbidNonWhitelisted → 미지 필드는 400.
  따라서 페이로드는 DTO 필드만 담는다.
- POST /projects → 201, PATCH /projects/:id → 200, DELETE → 204.
"""
from __future__ import annotations

import uuid
from typing import Any

import requests

DEFAULT_START = "2026-07-29T00:00:00.000Z"


def uid() -> str:
    return str(uuid.uuid4())


def bearer(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def project_payload(
    project_id: str | None = None,
    *,
    name: str = "pytest-project",
    current_row: int = 0,
    work_sessions: list[dict] | None = None,
) -> dict[str, Any]:
    """유효한 최소 SaveProjectDto. rowCounter는 필수(1:1)."""
    pid = project_id or uid()
    return {
        "id": pid,
        "name": name,
        "status": "WIP",
        "isFavorite": False,
        "memo": "",
        "startDate": DEFAULT_START,
        "relatedSkillIds": [],
        "rowCounter": {
            "id": uid(),
            "projectId": pid,
            "name": "메인",
            "currentRow": current_row,
        },
        "workSessions": work_sessions or [],
    }


def work_session(project_id: str, *, session_id: str | None = None,
                 started_at: str = "2026-07-29T01:00:00.000Z",
                 ended_at: str | None = "2026-07-29T01:10:00.000Z") -> dict:
    return {
        "id": session_id or uid(),
        "projectId": project_id,
        "startedAt": started_at,
        "endedAt": ended_at,
        "memo": None,
    }


class Api:
    """토큰 고정 API 클라이언트."""

    def __init__(self, base_url: str, token: str):
        self.base = base_url.rstrip("/")
        self.token = token
        self.s = requests.Session()

    def _url(self, path: str) -> str:
        return f"{self.base}{path}"

    def get(self, path: str, **kw) -> requests.Response:
        return self.s.get(self._url(path), headers=bearer(self.token), timeout=15, **kw)

    def post(self, path: str, json: Any, **kw) -> requests.Response:
        return self.s.post(self._url(path), headers=bearer(self.token), json=json, timeout=15, **kw)

    def patch(self, path: str, json: Any, **kw) -> requests.Response:
        return self.s.patch(self._url(path), headers=bearer(self.token), json=json, timeout=15, **kw)

    def delete(self, path: str, **kw) -> requests.Response:
        return self.s.delete(self._url(path), headers=bearer(self.token), timeout=15, **kw)

    # 편의: 프로젝트 생성 후 응답 반환
    def create_project(self, payload: dict) -> requests.Response:
        return self.post("/projects", json=payload)
