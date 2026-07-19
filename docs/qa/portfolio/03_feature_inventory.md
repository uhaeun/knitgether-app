# 기능 목록과 화면-API-DB 연결 구조 - 2026-07-19

> 기준 자료: iOS View/POM, 서버 Controller, Prisma schema, `docs/qa/postman/knitgether-local.postman_collection.json`

## 기능 목록 + 리스크 등급

| # | 기능 영역 | 화면 | 데이터 변경 | 리스크 | 우선순위 |
|---|---|---|---|---|---|
| 1 | 온보딩 | OnboardingView | 온보딩 완료 상태 | 신규 사용자가 앱을 시작하지 못함 | P0 |
| 2 | 회원가입/로그인 | AuthAccountView | 계정 생성 | 高 | P0 |
| 3 | 홈 | HomeView | - | 핵심 데이터 진입점 누락 | P2 |
| 4 | 프로젝트 생성/수정/삭제 | AddProjectView, EditProjectView, MyKnittingView | CRUD+동기화 | 高 | P0 |
| 5 | Workspace (단수·행·작업시간) | WorkspaceView | 세션 기록 | 高 | P0 |
| 6 | PDF·PencilKit | PatternLibraryView, ProjectPatternPanelView | PDF/그림 파일 저장 | 파일 유실 또는 프로젝트 연결 실패 | P1 |
| 7 | 게이지 계산기/측정 | GaugeCalculatorView, GaugeMeasureHubView | 기록/목표 저장 | 게이지 계산값 또는 기록 유실 | P1 |
| 8 | 스킬 테스트 | SkillTestView, SkillTestResultView | 사용자 스킬 레벨 저장 | 온보딩 저장 실패, 시스템 스킬 수정 오류 | P0 |
| 9 | 창고 (실/바늘/도구/도안/스킬) | LibraryView 하위 화면 | CRUD | 프로젝트 연결 데이터 불일치 | P1 |
| 10 | Offline·Sync·Cache | (횡단) | 동기화·충돌 | 高 | P0 |
| 11 | 설정/계정 | Settings, ProfileSettingsView | 로그아웃·프로필 수정 | 계정 전환 후 cache 오염 | P1 |

<!-- 우선순위 기준: 데이터가 바뀌는 흐름(생성/수정/삭제/동기화/계정) = P0 -->

## 화면 ↔ API ↔ DB 매핑

| 화면 액션 | API 엔드포인트 | DB 모델 | 오프라인 동작 |
|---|---|---|---|
| 회원가입 | `POST /auth/register` | `UserAccount`, `UserProfile` | Remote 전용. 서버 OFF 시 계정 생성 불가. |
| 로그인/세션 확인 | `POST /auth/login`, `GET /auth/me` | `UserAccount`, `UserProfile` | Remote 전용. 저장된 세션 token 우선 사용. |
| 프로필 조회/수정 | `GET /profile`, `PATCH /profile` | `UserProfile` | API 모드에서 offline-first cache 대상. |
| 프로젝트 목록/생성/수정/삭제 | `GET /projects`, `POST /projects`, `PATCH /projects/:id`, `DELETE /projects/:id` | `Project` | API 모드에서 local cache + pending retry. |
| 단수 카운터 저장 | `PATCH /projects/:id/row-counter` | `RowCounter` | retryable 실패 시 부모 Project pending으로 재시도. |
| 행 지시 생성/수정/삭제 | `POST/PATCH/DELETE /projects/:id/row-instructions...` | `RowInstruction` | retryable 실패와 삭제 실패를 pending Project로 보존. |
| 작업시간 생성/수정/삭제 | `POST/PATCH/DELETE /projects/:id/work-sessions...` | `WorkSession` | 신규 session은 POST, 기존 session은 PATCH, 삭제 실패는 재시도. |
| 프로젝트 패턴 파일/그림 | `/projects/:id/pattern-copy/file`, `/drawing` | `ProjectPatternCopy`, `StoredFile` | 파일 cache 사용. 네트워크 실패 시 파일 동기화 확인 필요. |
| 진척 사진 | `/projects/:id/progress-photos...` | `ProjectProgressPhoto` | Remote 직접 연결. 완전한 offline-first는 알려진 제한. |
| 도안 라이브러리 | `GET/POST/PATCH/DELETE /patterns` | `PatternDocument`, `StoredFile` | API 모드에서 offline-first cache 대상. |
| 게이지 기록 | `GET/POST/PATCH/DELETE /gauge-records` | `GaugeRecord` | API 모드에서 offline-first cache 대상. |
| 게이지 목표 | `GET/POST/PATCH/DELETE /gauge-targets` | `GaugeTarget`, `GaugeSwatch`, `GaugeMeasurement` | local 저장은 JSON 영속화. API 모드는 Remote 직접 연결로 알려진 제한. |
| 스킬/스킬 레벨 | `GET /skills`, `PATCH /skills/:id/level` | `Skill`, `UserSkillLevel` | API 모드에서 offline-first 대상. 시스템 스킬 자체 수정은 차단. |
| 사전 | `GET/POST/PATCH/DELETE /dictionary-terms` | `DictionaryTerm` | API 모드에서 offline-first cache 대상. |
| 실/바늘/도구 | `/library/yarns`, `/needles`, `/tools` | `Yarn`, `Needle`, `ToolItem`, `ProjectToolLink`, `ProjectYarnUsage` | API 모드에서 offline-first cache 대상. |

## 테스트 환경표

| 항목 | 값 |
|---|---|
| 앱 빌드 (커밋) | `main` 현재 HEAD |
| iOS 시뮬레이터 | iPhone 16 Pro Simulator, iOS 18.5 |
| 실기기 | iPhone 16 Pro, iOS 26.5, local network API |
| 서버 | `http://127.0.0.1:3000/api/v1` 또는 실기기용 `http://<Mac IP>:3000/api/v1` |
| DB | PostgreSQL + Prisma |
| 테스트 계정 | 매 실행마다 `ui-flow-<timestamp>@example.com` 형태 사용 |
| 네트워크 상태 조작 방법 | 서버 중단, API URL 오입력, Mac/iPhone 동일 Wi-Fi 확인 |
