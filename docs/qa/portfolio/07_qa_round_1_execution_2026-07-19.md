# QA 1회차 실행 리포트 - 2026-07-19

## 실행 범위

| 항목 | 값 |
|---|---|
| 앱 코드 기준 | SMK-004/005/006/008/009/010/011/012/013/014/015/016, 프로젝트 수정/삭제, 서버 OFF cache 없음, RowInstruction UI 자동화 포함 |
| 브랜치 | `main` |
| 서버 | local API `http://127.0.0.1:3000/api/v1` |
| 시뮬레이터 | iPhone 16 Pro Simulator, iOS 18.5 |
| 테스트 계정 | `ui-flow-<timestamp>@example.com` |
| 실행 방식 | 자동화 smoke + 수동 QA 후보 정리 |

## 자동 검증 결과

| 검증 | 결과 | 비고 |
|---|---|---|
| 서버 build | PASS | `npm run build` |
| 서버 e2e | PASS | 12 suites / 105 tests |
| iOS generic Simulator build | PASS | `KnitGether Local Simulator` scheme |
| iOS unit | PASS | 328 tests |
| iOS UI | PASS | UI test function 19개, xcresult totalTestCount 19, device passed 22, failures/errors/skipped 0 |
| 공백 검사 | PASS | `git diff --check` |

## Smoke 실행 상태

| TC ID | 상태 | 근거 |
|---|---|---|
| SMK-001 신규 회원가입 | PASS | `testCoreUserFlowRegistersAndSavesCommonRecords`에서 회원가입 성공 확인 |
| SMK-002 스킬 테스트 결과 저장 | PASS | 동일 UI smoke에서 403 없이 저장 후 온보딩 단계 복귀 확인 |
| SMK-003 프로젝트 생성 | PASS | 동일 UI smoke에서 성공 메시지 또는 프로젝트명 확인 |
| SMK-004 프로젝트 재실행 유지 | PASS | `testProjectPersistsAfterAppRelaunch`에서 앱 종료/재실행 후 프로젝트명 확인 |
| SMK-005 작업공간 단수 저장 | PASS | `testWorkspaceRowCounterPersistsAfterAppRelaunch`에서 다음 단 저장 및 앱 재실행 후 유지 확인 |
| SMK-006 작업시간 기록 | PASS | `testWorkspaceWorkSessionCanBeRecorded`에서 10초 이상 작업시간 종료 후 세션 내역 진입 확인 |
| SMK-007 게이지 기록 저장 | PASS | 동일 UI smoke에서 `세탁 전 게이지를 저장했어요.` 확인 |
| SMK-008 서버 OFF + cache 있음 | PASS | `testServerOffWithCachedProjectShowsCachedProject`에서 서버 OFF URL 재실행 후 cached 프로젝트 표시 확인 |
| SMK-009 서버 OFF pending write 후 복구 | PASS | `testServerOffPendingProjectSyncsAfterServerRecovers`에서 offline 저장, 서버 복구, 빈 cache 원격 재조회 확인 |
| SMK-010 계정 전환 cache 분리 | PASS | `testAccountSwitchKeepsProjectCacheSeparatedByUser`에서 A 계정 프로젝트 생성 후 B 계정에서 미노출 확인 |
| SMK-011 기존 계정 로그인 재진입 | PASS | `testExistingAccountCanLogInAndReachMainTabs`에서 로그아웃 후 같은 계정 로그인과 메인 탭 진입 확인 |
| SMK-012 로그아웃 후 프로필 오류 미노출 | PASS | `testLogoutDoesNotShowProfileLoadError`와 `authenticatedProfileLoadAfterSignOutKeepsEditableDefaultsWithoutError`에서 로그아웃 상태를 프로필 로드 오류로 표시하지 않음을 확인 |
| SMK-013 WorkSession 삭제 후 미복구 | PASS | `testWorkspaceWorkSessionCanBeDeletedAndStaysDeletedAfterRelaunch`에서 세션 삭제 후 앱 재실행 시 세션 내역 비활성 확인 |
| SMK-014 GaugeTarget 수정/삭제 후 미복구 | PASS | `testGaugeTargetCanBeEditedDeletedAndStayDeletedAfterRelaunch`에서 목표 게이지 수정 유지, 삭제, 앱 재실행 후 미노출 확인 |
| SMK-015 잘못된 비밀번호 로그인 | PASS | `testWrongPasswordLoginShowsErrorAndDoesNotPersistSession`에서 실패 메시지와 재실행 후 signed-out 상태 확인 |
| SMK-016 GaugeTarget 스와치/수동 측정 재실행 유지 | PASS | `testGaugeSwatchAndManualMeasurementPersistAfterRelaunch`에서 스와치 추가, 수동 측정 저장/수정, 앱 재실행 후 수정값 유지 확인 |
| 프로젝트 수정/삭제 | PASS | `testProjectCanBeEditedDeletedAndStayDeletedAfterRelaunch`에서 이름 수정, 재실행 유지, 삭제, 재실행 후 미노출 확인 |
| 서버 OFF cache 없음 안내 | PASS | `testServerOffWithoutProjectCacheShowsOfflineNotice`에서 빈 cache + 서버 OFF 재실행 시 서버 연결 안내 확인 |
| RowInstruction 저장/수정/삭제 | PASS | `testWorkspaceRowInstructionCanBeSavedEditedDeletedAndStayDeletedAfterRelaunch`에서 행안내 추가, 수정, 재실행 유지, 삭제, 재실행 후 미노출 확인 |

## 발견/재검증 결함

| ID | 제목 | Severity | 상태 | 근거 |
|---|---|---|---|---|
| DEF-001 | Auth email/password accessibility identifier가 입력칸이 아닌 아이콘에 매칭됨 | Important | Retest Passed | `testCoreUserFlowRegistersAndSavesCommonRecords` 통과. 증거: `evidence/0719_DEF-001_auth_FAIL_element-tree.txt` |
| DEF-002 | 기존 GaugeTarget에 스와치/측정값을 PATCH하면 기존 ID create 재사용으로 저장 실패 가능 | Important | Retest Passed | 서버 e2e `updates existing swatches and measurements within the owner scope without duplicate creates`와 UI `testGaugeSwatchAndManualMeasurementPersistAfterRelaunch` 통과 |

## 1회차 판정

| 항목 | 판정 |
|---|---|
| 신규 사용자가 가입 후 주요 저장 흐름을 사용할 수 있는가 | PASS |
| 저장한 프로젝트가 앱 재실행 후 유지되는가 | PASS |
| Smoke 16 기준 P0/P1 핵심이 실행됐는가 | YES |
| 앱 사용 가능성 | PASS. 회원가입/기존 계정 로그인/잘못된 비밀번호/로그아웃 후 프로필 오류 미노출/스킬 테스트/프로젝트 생성/수정/삭제/재실행 유지/작업공간 단수/작업시간/작업시간 삭제/행안내/게이지 기록/GaugeTarget 수정·삭제, 스와치/수동 측정 저장·수정·재실행 유지, 오프라인 cache/pending 복구/cache 없음 안내, 계정 cache 분리는 자동화로 통과 |
| 릴리즈 판정 | 조건부 Go. Smoke 16 자동화 범위는 통과했으며 GaugeTarget·ProgressPhoto의 완전한 OfflineFirst 미지원은 알려진 제한으로 별도 관리한다. |

## 다음 실행 우선순위

| 순서 | 대상 | 이유 |
|---|---|---|
| 1 | 라이브러리 실/바늘/도구 CRUD | 프로젝트 연결과 삭제 영향 확인이 남은 P1 범위 |

## Evidence 규칙

수동 QA에서 FAIL이 나오면 아래 파일명으로 증거를 남긴다.

| 유형 | 파일명 예시 |
|---|---|
| 스크린샷 | `0719_SMK-004_project-relaunch_FAIL.png` |
| 서버 로그 | `0719_SMK-009_pending-retry_server-log.txt` |
| API 응답 | `0719_SMK-008_cache-fallback_response.json` |
| 결함 원인 메모 | `0719_DEF-002_pending-retry.md` |
