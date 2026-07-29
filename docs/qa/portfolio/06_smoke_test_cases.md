# 스모크 테스트 케이스 - 2026-07-19

## 설계 기준

| 항목 | 값 |
|---|---|
| 목적 | 앱 사용자가 핵심 기능을 최소 1회 성공적으로 사용할 수 있는지 빠르게 확인 |
| 우선순위 | P0: 사용 시작/저장/동기화, P1: 반복 사용/계정/오프라인, P2: 보조 화면 |
| 설계 기법 태그 | Happy Path, Negative, Boundary, State Transition, Persistence, Offline, API-DB |
| 결과 값 | PASS / FAIL / NEED_SPEC_CONFIRM / ENV_ISSUE / RETRY_REQUIRED / NOT_A_BUG |
| 테스트 계층 배분 | 스모크는 **넓고 얕게**(핵심 흐름을 최소 1회 성공/실패로 확인). syncStatus 충돌·정합성 등 **좁고 깊은** 검증(충돌 감지 조건·양측 데이터 보존·해소 후 상태 복귀)은 API 정합성 테스트 계층(산출물 3)이 담당한다. |
| 근거 조항 컬럼 | 각 TC를 v2.3 스펙 조항에 연결(RTM 원천). 문서 말미 `조항 ↔ TC 역추적(RTM)` 표와 양방향 대응. |

## Smoke 21

> `근거 조항`은 v2.3 스펙 절 번호. 문서 말미 RTM 표와 양방향 대응.

| TC ID | 우선순위 | 시나리오 | 사전조건 | 절차 | 기대 UI 결과 | API/DB 확인 | 설계 태그 | 근거 조항(v2.3) | 자동화 |
|---|---|---|---|---|---|---|---|---|---|
| SMK-001 | P0 | 신규 회원가입 | 서버 ON, 신규 email | 온보딩 -> 로그인/회원가입 -> email/name/password 입력 -> 회원가입 | `회원가입이 완료됐어요.` 또는 로그인 상태 | `POST /auth/register`, `UserAccount`, `UserProfile` 생성 | Happy Path, API-DB | §C-2, §B(온보딩) | XCUITest 일부 |
| SMK-002 | P0 | 스킬 테스트 결과 저장 | 로그인 상태 | 온보딩 스킬 테스트 -> 첫 스킬 레벨 선택 -> 저장 | 스킬 테스트 단계로 복귀, 403 미노출 | `PATCH /skills/:id/level`, `UserSkillLevel` 저장 | Regression, API-DB | §B(스킬) | XCUITest 일부 |
| SMK-003 | P0 | 프로젝트 생성 | 로그인 상태 | 내 뜨개 -> 추가 -> 프로젝트명 입력 -> 저장 | 성공 메시지 또는 프로젝트명 표시 | `POST /projects`, `Project` 생성 | Happy Path, API-DB | §B(프로젝트 CRUD) | XCUITest 일부 |
| SMK-004 | P0 | 프로젝트 재실행 유지 | SMK-003 완료 | 앱 종료/재실행 -> 내 뜨개 확인 | 생성한 프로젝트가 다시 보임 | `GET /projects`, cache fallback 가능 | Persistence | §C-1(오프라인 지속) | XCUITest |
| SMK-005 | P0 | 작업공간 단수 저장 | 프로젝트 있음 | 프로젝트 진입 -> current row 변경 -> 저장/반영 | 현재 단수가 변경값으로 표시 | `PATCH /projects/:id/row-counter`, `RowCounter` 갱신 | State Transition, API-DB | §B(단수 카운터) | XCUITest |
| SMK-006 | P0 | 작업시간 기록 | 프로젝트 있음 | 작업공간 진입 -> 10초 이상 경과 -> 종료 | 작업시간 기록이 세션 내역으로 접근 가능 | `POST /projects/:id/work-sessions`, `WorkSession` 생성 | Boundary, API-DB | §B(작업 공간) | XCUITest |
| SMK-007 | P1 | 게이지 기록 저장 | 로그인 상태 | 도구 -> 게이지 계산기 -> 필수 수치 입력 -> 세탁 전 저장 | `세탁 전 게이지를 저장했어요.` | `POST /gauge-records`, `GaugeRecord` 생성 | Happy Path, API-DB | §C-7 | XCUITest 일부 |
| SMK-008 | P1 | 서버 OFF + cache 있음 | 서버 ON에서 프로젝트 조회 완료 | 서버 OFF URL로 앱 재실행/목록 조회 | 기존 프로젝트가 cache로 보임 | remote 실패 후 local cache read | Offline, Persistence | §C-1 | XCUITest |
| SMK-009 | P1 | 서버 OFF pending write 후 복구 | 로그인 완료 | 서버 OFF URL로 프로젝트 생성 -> 서버 ON URL 복구 -> 빈 cache 재조회 | pending 프로젝트가 서버 복구 후 새 cache에서도 보임 | pending Project 재시도, `Project` 원격 반영 | Offline, Retry, API-DB | §C-1(pendingUpload→synced) | XCUITest |
| SMK-010 | P1 | 계정 전환 cache 분리 | 서버 ON, 신규 A/B email | A에서 프로젝트 생성 -> 로그아웃 -> B 가입/온보딩 | B 계정에서 A 프로젝트가 보이지 않음 | ownerId별 데이터 분리 | Security, Persistence | §C-1(유저 격리), §C-2 | XCUITest |
| SMK-011 | P0 | 기존 계정 로그인 재진입 | 서버 ON, 가입된 email/password | 기존 계정 생성 -> 로그아웃 -> 앱 재실행 -> 같은 계정으로 로그인 -> 온보딩 완료 | `로그인했어요.` 또는 로그인 상태, 이후 메인 탭 진입 | `POST /auth/login`, session/profile 조회 | Happy Path, State Transition, API-DB | §C-2 | XCUITest |
| SMK-012 | P0 | 로그아웃 후 프로필 오류 미노출 | 로그인 상태 | 설정 -> 계정 연동 -> 로그아웃 -> 프로필 편집 진입 | `프로필을 불러오지 못했어요.` 미노출 | session clear 후 인증 필요 profile fetch 미수행 | Regression, State Transition | §C-2, §D CR-4(DEF-006) | XCUITest + Unit |
| SMK-013 | P0 | WorkSession 삭제 후 미복구 | 프로젝트 있음, 10초 이상 작업 세션 기록 | 작업공간 -> 세션 내역 -> 첫 세션 삭제 -> 앱 재실행 -> 작업공간 확인 | 세션 기록이 없고, 재실행 후 세션 내역 버튼이 비활성 | `DELETE /projects/:id/work-sessions/:sessionId`, `WorkSession` 삭제 유지 | Persistence, State Transition, API-DB | §B(작업 공간), §D CR-1 | XCUITest |
| SMK-014 | P1 | GaugeTarget 수정/삭제 후 미복구 | 로그인 상태, GaugeTarget 생성 완료 | 도구 -> 게이지 계산기 -> 목표 게이지 목록 -> 기존 목표 수정 -> 앱 재실행 -> 삭제 -> 앱 재실행 | 수정값이 유지되고 삭제한 목표 게이지가 다시 보이지 않음 | `PATCH /gauge-targets/:id`, `DELETE /gauge-targets/:id`, local cache 삭제 유지 | Persistence, State Transition, API-DB | §C-7 | XCUITest |
| SMK-015 | P0 | 잘못된 비밀번호 로그인 | 서버 ON, 가입된 email/password, 로그아웃 상태 | 기존 email + 틀린 password 입력 -> 로그인 -> 앱 재실행 | `이메일 또는 비밀번호가 맞지 않아요.` 표시, 재실행 후 signed-out 상태 유지 | `POST /auth/login` 401 `INVALID_CREDENTIALS`, auth session 미저장 | Negative, Security, State Transition | §C-2 | XCUITest |
| SMK-016 | P1 | GaugeTarget 스와치/수동 측정 재실행 유지 | 로그인 상태, GaugeTarget 생성 완료 | 목표 게이지 상세 -> 스와치 추가 -> 수동 측정 저장 -> 측정 수정 -> 앱 재실행 | 스와치와 수정된 측정값이 다시 보임 | `PATCH /gauge-targets/:id`, `GaugeSwatch`, `GaugeMeasurement` upsert 및 cache 유지 | Persistence, State Transition, API-DB | §C-7 | XCUITest |
| SMK-017 | P1 | syncStatus conflict 상태 진입 확인 | 서버 ON, 동일 레코드 로컬/원격 불일치 유발 시도 | 로컬 수정 후 원격에서 동일 레코드가 다르게 변경된 상황 재현 -> 목록/배지 확인 | **BLOCKED — 구현 부재.** `.conflict`는 정의만 존재하고 클라이언트·서버 모두 전이 로직 미구현이라 재현 불가. 서버측 공백은 last-write-wins 결함([Issue #14](https://github.com/uhaeun/knitgether-app/issues/14), severity/high)로 발행. 본 스모크는 실행 대상에서 제외(Blocked), 대신 산출물 3이 last-write-wins를 negative test로 감시 | 코드상 `.conflict` 대입 지점 없음, 서버 `version` 필드 없음(§C-1) | State Transition, Offline | §C-1(conflict 미구현), Issue #14 | Blocked(실행 제외) |
| SMK-018 | P2 | 홈 대시보드 표시 | 로그인 + 프로젝트 1개 이상 | 홈 탭 진입 | 프로젝트 통계·이어서 뜨기·최근 작업이 표시됨 | `GET /projects` 집계 표시 | Happy Path | §A-2(홈 대시보드) | 미자동화 후보 |
| SMK-019 | P2 | 뜨개 사전 조회/검색 | 로그인 상태 | 도구 -> 뜨개 사전 -> 용어 검색 -> 상세 진입 | 용어 목록·검색 결과·상세(읽기 전용)가 표시됨 | `GET /dictionary-terms` | Happy Path | §B(사전) | 미자동화 후보 |
| SMK-020 | P1 | 창고 실/바늘/도구 CRUD | 로그인 상태 | 창고 -> 실 추가 -> 수정 -> 삭제 -> 앱 재실행 | 생성·수정·삭제가 반영되고 재실행 후 삭제가 유지됨 | `POST/PATCH/DELETE /library/*`, `Yarn`/`Needle`/`ToolItem` | Happy Path, Persistence, API-DB | §B(창고) | 미자동화 후보 |
| SMK-021 | P0 | 데이터 백업 내보내기/가져오기 | 로그인 + 데이터 있음, **실기기** | 설정 -> 데이터 백업 -> 내보내기(JSON) -> 가져오기 | 내보낸 JSON으로 데이터가 복원됨 (⚠️ 실기기 공유시트/파일 피커 의존) | JSON export/import (로컬 파일) | Persistence, Happy Path | §C-3(데이터 백업) | 미자동화 후보(실기기 수동) |

## syncStatus 5상태 전이 매트릭스 (상태 × 이벤트)

> 상태전이 TC의 모체. 셀 값은 **전이 후 상태** 또는 `불허`/`미정의`. 코드 근거는 각 `OfflineFirst*Repository` + `SyncStatus.swift`(2026-07-29 소스 확인).

| 현재 상태 \ 이벤트 | 로컬 생성/수정 | 업로드 동기화 성공 | 로컬 삭제 요청 | 삭제 동기화 성공 | 로컬/원격 충돌 감지 |
|---|---|---|---|---|---|
| **localOnly** | localOnly (허용) | synced (허용) | 즉시 제거 (허용) | 미정의 | **미정의 — 진입 이벤트 없음** |
| **pendingUpload** | pendingUpload (허용) | synced (허용) | pendingDelete (허용) | 미정의 | **미정의 — 진입 이벤트 없음** |
| **synced** | pendingUpload (허용) | 변화 없음 | pendingDelete (허용) | 미정의 | **미정의 — 진입 이벤트 없음** |
| **pendingDelete** | 불허(삭제 대기 중) | — | 이미 삭제 대기 | 레코드 제거 (허용) | **미정의 — 진입 이벤트 없음** |
| **conflict** | N/A — **도달 불가 상태** | N/A | N/A | N/A | N/A |

**핵심 발견 (상태전이 분석)**: `.conflict`는 `SyncStatus` enum에 정의되고 `SyncStatusBadgeView`에서 표시 케이스로 렌더되지만, **어떤 리포지토리·동기화 경로도 `.conflict`를 대입하지 않는다** — 즉 현 구현에서 도달 불가능한(dead) 상태다. 서버의 `ConflictException`도 sync 충돌이 아니라 회원가입 중복 이메일(409)용. 따라서:
- 스모크(SMK-017)는 "충돌 배지 노출"을 단정하지 않고 **진입 경로 부재를 확인**하는 형태로 설계한다.
- 서버 역시 `version`/`syncStatus` 필드가 없고 `updateProject`는 last-write-wins이므로 **충돌을 주입할 API 경로조차 없다**. 이 서버측 공백은 **[Issue #14](https://github.com/uhaeun/knitgether-app/issues/14)**(severity/high)로 발행. 산출물 3(API 정합성)은 충돌을 재현하는 대신 **last-write-wins가 실제로 일어남을 통과하는 negative test**로 상시 감시한다.

## 화면별 상세 TC 후보

| 영역 | TC 후보 | 우선순위 | 확인 포인트 |
|---|---|---|---|
| 인증 | 중복 이메일 회원가입 | P0 | 사용자에게 중복/실패 메시지가 표시되고 앱이 멈추지 않는다. |
| 인증 | 기존 계정 로그인 | P0 | `POST /auth/login` 성공 후 세션이 저장되고 메인 탭으로 진입한다. XCUITest `testExistingAccountCanLogInAndReachMainTabs`로 확인. |
| 인증 | 로그아웃 후 프로필 오류 미노출 | P0 | 로그아웃 상태를 프로필 로드 실패로 표시하지 않는다. XCUITest `testLogoutDoesNotShowProfileLoadError`와 unit `authenticatedProfileLoadAfterSignOutKeepsEditableDefaultsWithoutError`로 확인. |
| 인증 | 잘못된 비밀번호 로그인 | P0 | 세션이 저장되지 않고 실패 메시지가 표시된다. XCUITest `testWrongPasswordLoginShowsErrorAndDoesNotPersistSession`으로 확인. |
| 온보딩 | 완료 후 재실행 | P0 | 다시 온보딩 첫 화면으로 돌아가지 않는다. |
| 프로젝트 | 이름 없는 프로젝트 저장 | P0 | validation 메시지 또는 저장 비활성 정책이 동작한다. |
| 프로젝트 | 프로젝트 수정 | P0 | `PATCH /projects/:id`, 수정값 유지. XCUITest `testProjectCanBeEditedDeletedAndStayDeletedAfterRelaunch`로 UI/재실행 확인. |
| 프로젝트 | 프로젝트 삭제 | P0 | `DELETE /projects/:id`, 목록에서 제거, 재실행 후 부활하지 않음. XCUITest `testProjectCanBeEditedDeletedAndStayDeletedAfterRelaunch`로 UI/재실행 확인. |
| 작업공간 | RowInstruction 추가/수정/삭제 | P0 | child pending retry와 삭제 재시도 유지. XCUITest `testWorkspaceRowInstructionCanBeSavedEditedDeletedAndStayDeletedAfterRelaunch`로 UI/재실행 확인. |
| 작업공간 | 10초 미만 WorkSession | P0 | 저장하지 않는 정책 유지. |
| 작업공간 | WorkSession 삭제 | P0 | 삭제 후 앱 재실행 시 부활하지 않는다. XCUITest `testWorkspaceWorkSessionCanBeDeletedAndStaysDeletedAfterRelaunch`로 확인. |
| 게이지 | 기존 GaugeTarget 수정 | P1 | 기존 ID 수정은 POST가 아니라 PATCH. XCUITest `testGaugeTargetCanBeEditedDeletedAndStayDeletedAfterRelaunch`로 UI/재실행 확인. |
| 게이지 | GaugeTarget 삭제 | P1 | 삭제 후 앱 재실행 시 부활하지 않는다. XCUITest `testGaugeTargetCanBeEditedDeletedAndStayDeletedAfterRelaunch`로 확인. |
| 게이지 | 스와치/수동 측정 저장/수정 | P1 | 기존 GaugeTarget 하위 스와치와 측정값이 저장/수정되고 재실행 후 유지된다. XCUITest `testGaugeSwatchAndManualMeasurementPersistAfterRelaunch`로 확인. |
| 라이브러리 | 실/바늘/도구 CRUD | P1 | 프로젝트 연결 후 수정/삭제 영향 확인. |
| 도안 | PDF 업로드/프로젝트 연결 | P1 | 파일 cache와 project copy 유지. |
| 설정 | 로그아웃 | P1 | 로그아웃 후 프로필 로드 실패 toast가 뜨지 않는다. |
| 서버 OFF | cache 없음 프로젝트 목록 | P1 | 빈 cache에서 remote 조회 실패 시 빈 프로젝트 목록이 아니라 서버 연결 안내가 표시된다. XCUITest `testServerOffWithoutProjectCacheShowsOfflineNotice`로 확인. |
| 설정 | 작업시간 통계 | **P2 — 스모크 제외** | 사유: 읽기 전용 집계 화면. 실패해도 저장 데이터·인증에 영향 없음(데이터 유실/노출 리스크 없음). 회귀 발생 시에만 후보 승격. |
| 도구 | 뜨개 애니메이션 재생 | **P2 — 스모크 제외** | 사유: 재생 UI. 실패해도 저장 데이터·인증에 영향 없음. 리스크 기반으로 스모크 제외. |
| 작업공간 | 진행 사진 추가 | **P2 — 스모크 제외** | 사유: Remote 직접 연결의 알려진 offline 제한 존재하나 핵심 데이터/인증 경로 아님. 실패 시 데이터·인증 무영향. 실기기 미디어 피커 의존이라 자동화 부적합. |

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
| SMK-008 | `KnitGetherUITestCase`, `MainTabBarPage`, `MyKnittingPage`, `ProjectFormPage` |
| SMK-009 | `KnitGetherUITestCase`, `MainTabBarPage`, `MyKnittingPage`, `ProjectFormPage` |
| SMK-010 | `KnitGetherUITestCase`, `MainTabBarPage`, `SettingsPage`, `AuthPage`, `MyKnittingPage` |
| SMK-011 | `KnitGetherUITestCase`, `OnboardingPage`, `AuthPage`, `MainTabBarPage`, `MyKnittingPage` |
| SMK-012 | `KnitGetherUITestCase`, `MainTabBarPage`, `SettingsPage`, `AuthPage` |
| SMK-013 | `KnitGetherUITestCase`, `MainTabBarPage`, `MyKnittingPage`, `WorkspacePage` |
| SMK-014 | `KnitGetherUITestCase`, `MainTabBarPage`, `ToolPage`, `GaugeCalculatorPage` |
| SMK-015 | `KnitGetherUITestCase`, `OnboardingPage`, `AuthPage`, `MainTabBarPage`, `SettingsPage` |
| SMK-016 | `KnitGetherUITestCase`, `MainTabBarPage`, `ToolPage`, `GaugeCalculatorPage` |
| 프로젝트 수정/삭제 | `KnitGetherUITestCase`, `MainTabBarPage`, `MyKnittingPage`, `WorkspacePage`, `ProjectFormPage` |
| 서버 OFF cache 없음 | `KnitGetherUITestCase`, `MainTabBarPage`, `MyKnittingPage` |
| RowInstruction 저장/수정/삭제 | `KnitGetherUITestCase`, `MainTabBarPage`, `MyKnittingPage`, `WorkspacePage` |
| SMK-017 | POM 미작성 — 충돌 주입이 데이터 계층 필요, 산출물 3 담당 |
| SMK-018 | POM 미작성 — `HomePage` 자동화 후보 |
| SMK-019 | POM 미작성 — `ToolPage`, `DictionaryPage` 자동화 후보 |
| SMK-020 | POM 미작성 — `LibraryPage` 자동화 후보 |
| SMK-021 | POM 미작성 — 실기기 공유시트 의존, 수동 검증 |

## 데이터 정합성 확인 컬럼 정의

| 컬럼 | 의미 |
|---|---|
| UI 결과 | 사용자가 보는 메시지/목록/상태 |
| API 결과 | 어떤 endpoint가 어떤 method로 호출되어야 하는지 |
| DB 결과 | Prisma 모델 기준 어떤 row가 생성/수정/삭제되어야 하는지 |
| 재실행 결과 | 앱 또는 repository 재생성 후 데이터가 유지되는지 |
| 계정 결과 | owner/user scope가 올바르게 분리되는지 |

## 요구사항 추적 매트릭스 (RTM) — v2.3 조항 ↔ TC 역추적

> 스펙 조항에서 TC로 역방향 추적. 조항별 커버 TC와 공백을 한눈에 본다. (TC→조항은 위 Smoke 표 `근거 조항` 컬럼.)

| v2.3 조항 | 요구사항 | 커버 TC | 상태 |
|---|---|---|---|
| §A-2 (홈) | 홈 대시보드 표시 | SMK-018 | 스모크 커버 |
| §B (온보딩) | 온보딩 → 프로필 저장 | SMK-001, SMK-011 | 커버 |
| §B (프로젝트 CRUD) | 생성·수정·삭제 | SMK-003, SMK-004, 후보(수정/삭제) | 커버 |
| §B (단수 카운터) | 현재/목표 단수 | SMK-005 | 커버 |
| §B (행안내) | 단별 지시 CRUD | 후보(RowInstruction) | 후보만 — 자동화됨 |
| §B (작업 공간) | 작업 타이머·세션 | SMK-006, SMK-013 | 커버 |
| §B (창고) | 실·바늘·도구 CRUD | SMK-020 | 스모크 커버 |
| §B (도안) | PDF 가져오기/스캔 | 후보(PDF 업로드) | 후보만 |
| §B (사전) | 용어 조회·검색 | SMK-019 | 스모크 커버 |
| §B (스킬) | 스킬 레벨 저장 | SMK-002 | 커버 |
| §C-1 (동기화) | 오프라인·pending·격리 | SMK-004, 008, 009, 010 | 커버 |
| §C-1 (conflict 상태) | 충돌 상태 | SMK-017(Blocked — 구현 부재) | **미구현 — Issue #14(서버 last-write-wins), 산출물 3이 negative test로 감시** |
| §C-2 (인증) | 회원가입·로그인·세션 | SMK-001, 011, 012, 015 | 커버 |
| §C-3 (데이터 백업) | JSON 내보내기/가져오기 | SMK-021 | 스모크 커버(실기기 수동) |
| §C-4 (작업시간 통계) | 집계 화면 | — | P2 제외(사유 기재) |
| §C-5 (뜨개 애니메이션) | 재생 | — | P2 제외(사유 기재) |
| §C-6 (진행 사진) | 사진 추가 | — | P2 제외(사유 기재) |
| §C-7 (게이지 도구) | 계산기·기록·측정 | SMK-007, 014, 016 | 커버 |
| §D CR-1 (세션 지속성) | 백그라운드/종료 유실 방지 | SMK-013 부분 | Issue #9 추적 |
| §D CR-4 (인증 지속성) | DEF-006 회귀 | SMK-012 | 커버(Issue #12) |
