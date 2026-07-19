# 스모크 테스트 케이스 - 2026-07-19

## 설계 기준

| 항목 | 값 |
|---|---|
| 목적 | 앱 사용자가 핵심 기능을 최소 1회 성공적으로 사용할 수 있는지 빠르게 확인 |
| 우선순위 | P0: 사용 시작/저장/동기화, P1: 반복 사용/계정/오프라인, P2: 보조 화면 |
| 설계 기법 태그 | Happy Path, Negative, Boundary, State Transition, Persistence, Offline, API-DB |
| 결과 값 | PASS / FAIL / NEED_SPEC_CONFIRM / ENV_ISSUE / RETRY_REQUIRED / NOT_A_BUG |

## Smoke 10

| TC ID | 우선순위 | 시나리오 | 사전조건 | 절차 | 기대 UI 결과 | API/DB 확인 | 설계 태그 | 자동화 |
|---|---|---|---|---|---|---|---|---|
| SMK-001 | P0 | 신규 회원가입 | 서버 ON, 신규 email | 온보딩 -> 로그인/회원가입 -> email/name/password 입력 -> 회원가입 | `회원가입이 완료됐어요.` 또는 로그인 상태 | `POST /auth/register`, `UserAccount`, `UserProfile` 생성 | Happy Path, API-DB | XCUITest 일부 |
| SMK-002 | P0 | 스킬 테스트 결과 저장 | 로그인 상태 | 온보딩 스킬 테스트 -> 첫 스킬 레벨 선택 -> 저장 | 스킬 테스트 단계로 복귀, 403 미노출 | `PATCH /skills/:id/level`, `UserSkillLevel` 저장 | Regression, API-DB | XCUITest 일부 |
| SMK-003 | P0 | 프로젝트 생성 | 로그인 상태 | 내 뜨개 -> 추가 -> 프로젝트명 입력 -> 저장 | 성공 메시지 또는 프로젝트명 표시 | `POST /projects`, `Project` 생성 | Happy Path, API-DB | XCUITest 일부 |
| SMK-004 | P0 | 프로젝트 재실행 유지 | SMK-003 완료 | 앱 종료/재실행 -> 내 뜨개 확인 | 생성한 프로젝트가 다시 보임 | `GET /projects`, cache fallback 가능 | Persistence | XCUITest |
| SMK-005 | P0 | 작업공간 단수 저장 | 프로젝트 있음 | 프로젝트 진입 -> current row 변경 -> 저장/반영 | 현재 단수가 변경값으로 표시 | `PATCH /projects/:id/row-counter`, `RowCounter` 갱신 | State Transition, API-DB | XCUITest |
| SMK-006 | P0 | 작업시간 기록 | 프로젝트 있음 | 작업공간 진입 -> 10초 이상 경과 -> 종료 | 작업시간 기록이 세션 내역으로 접근 가능 | `POST /projects/:id/work-sessions`, `WorkSession` 생성 | Boundary, API-DB | XCUITest |
| SMK-007 | P1 | 게이지 기록 저장 | 로그인 상태 | 도구 -> 게이지 계산기 -> 필수 수치 입력 -> 세탁 전 저장 | `세탁 전 게이지를 저장했어요.` | `POST /gauge-records`, `GaugeRecord` 생성 | Happy Path, API-DB | XCUITest 일부 |
| SMK-008 | P1 | 서버 OFF + cache 있음 | 서버 ON에서 프로젝트 조회 완료 | 서버 중단 -> 앱 재실행/목록 조회 | 기존 프로젝트가 cache로 보이거나 오프라인 안내가 정책대로 표시 | remote 실패 후 local cache read | Offline, Persistence | 수동 |
| SMK-009 | P1 | 서버 OFF pending write 후 복구 | 로그인+프로젝트 있음 | 서버 중단 -> 프로젝트/자식 데이터 변경 -> 서버 복구 -> sync | pending 표시 후 복구 시 동기화 완료 | pending Project 재시도, 관련 모델 반영 | Offline, Retry, API-DB | 수동 |
| SMK-010 | P1 | 계정 전환 cache 분리 | A/B 계정 준비 | A에서 프로젝트 생성 -> 로그아웃 -> B 로그인 | B 계정에서 A 프로젝트가 보이지 않음 | ownerId별 데이터 분리 | Security, Persistence | 수동 |

## 화면별 상세 TC 후보

| 영역 | TC 후보 | 우선순위 | 확인 포인트 |
|---|---|---|---|
| 인증 | 중복 이메일 회원가입 | P0 | 사용자에게 중복/실패 메시지가 표시되고 앱이 멈추지 않는다. |
| 인증 | 잘못된 비밀번호 로그인 | P0 | 세션이 저장되지 않고 실패 메시지가 표시된다. |
| 온보딩 | 완료 후 재실행 | P0 | 다시 온보딩 첫 화면으로 돌아가지 않는다. |
| 프로젝트 | 이름 없는 프로젝트 저장 | P0 | validation 메시지 또는 저장 비활성 정책이 동작한다. |
| 프로젝트 | 프로젝트 수정 | P0 | `PATCH /projects/:id`, 수정값 유지. |
| 프로젝트 | 프로젝트 삭제 | P0 | `DELETE /projects/:id`, 목록에서 제거, 재실행 후 부활하지 않음. |
| 작업공간 | RowInstruction 추가/수정/삭제 | P0 | child pending retry와 삭제 재시도 유지. |
| 작업공간 | 10초 미만 WorkSession | P0 | 저장하지 않는 정책 유지. |
| 게이지 | 기존 GaugeTarget 수정 | P1 | 기존 ID 수정은 POST가 아니라 PATCH. |
| 라이브러리 | 실/바늘/도구 CRUD | P1 | 프로젝트 연결 후 수정/삭제 영향 확인. |
| 도안 | PDF 업로드/프로젝트 연결 | P1 | 파일 cache와 project copy 유지. |
| 설정 | 로그아웃 | P1 | 로그아웃 후 프로필 로드 실패 toast가 뜨지 않는다. |

## XCUITest POM 매핑

| TC ID | 현재 POM |
|---|---|
| SMK-001 | `OnboardingPage`, `AuthPage` |
| SMK-002 | `OnboardingPage`, `SkillTestPage` |
| SMK-003 | `MainTabBarPage`, `MyKnittingPage`, `ProjectFormPage` |
| SMK-007 | `MainTabBarPage`, `ToolPage`, `GaugeCalculatorPage` |
| SMK-004 | `KnitGetherUITestCase`, `MainTabBarPage`, `MyKnittingPage` |
| SMK-005 | `MyKnittingPage`, `WorkspacePage` |
| SMK-006 | `MyKnittingPage`, `WorkspacePage` |
| SMK-008/009/010 | 신규 POM 또는 수동 네트워크 조작 필요 |

## 데이터 정합성 확인 컬럼 정의

| 컬럼 | 의미 |
|---|---|
| UI 결과 | 사용자가 보는 메시지/목록/상태 |
| API 결과 | 어떤 endpoint가 어떤 method로 호출되어야 하는지 |
| DB 결과 | Prisma 모델 기준 어떤 row가 생성/수정/삭제되어야 하는지 |
| 재실행 결과 | 앱 또는 repository 재생성 후 데이터가 유지되는지 |
| 계정 결과 | owner/user scope가 올바르게 분리되는지 |
