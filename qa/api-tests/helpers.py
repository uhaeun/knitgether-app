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

    def patch_project(self, project_id: str, payload: dict) -> requests.Response:
        """수정에 필요한 낙관적 잠금 기준값을 서버에서 읽어 붙여 보낸다(GitHub #14).

        수정(PATCH)은 baseUpdatedAt이 없으면 400이다. 다른 기기가 먼저 고친 것을
        모르고 덮어쓰는 요청을 서버가 통과시키지 않기 위해서다.

        여기서 기준값을 직접 읽는 이유는, 이 헬퍼를 쓰는 케이스들이 충돌을 검증하려는
        것이 아니라 각자의 다른 것을 보려 하기 때문이다. 충돌 자체를 보는 케이스는
        기준값을 손으로 만들어 보낸다(test_17, test_19).
        """
        current = self.get(f"/projects/{project_id}")
        body = dict(payload)

        if current.status_code == 200:
            body["baseUpdatedAt"] = current.json()["updatedAt"]

        return self.patch(f"/projects/{project_id}", json=body)
