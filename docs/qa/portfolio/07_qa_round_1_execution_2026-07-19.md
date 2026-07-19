# QA 1회차 실행 리포트 - 2026-07-19

## 실행 범위

| 항목 | 값 |
|---|---|
| 앱 코드 기준 | SMK-004/005/006 UI 자동화 포함 |
| 브랜치 | `main` |
| 서버 | local API `http://127.0.0.1:3000/api/v1` |
| 시뮬레이터 | iPhone 16 Pro Simulator, iOS 18.5 |
| 테스트 계정 | `ui-flow-<timestamp>@example.com` |
| 실행 방식 | 자동화 smoke + 수동 QA 후보 정리 |

## 자동 검증 결과

| 검증 | 결과 | 비고 |
|---|---|---|
| 서버 build | PASS | `npm run build` |
| 서버 e2e | PASS | 12 suites / 104 tests |
| iOS generic Simulator build | PASS | `KnitGether Local Simulator` scheme |
| iOS unit | PASS | 325 tests |
| iOS UI | PASS | UI test 7개, launch matrix 포함 10 passed runs |
| 공백 검사 | PASS | `git diff --check` |

## Smoke 10 실행 상태

| TC ID | 상태 | 근거 |
|---|---|---|
| SMK-001 신규 회원가입 | PASS | `testCoreUserFlowRegistersAndSavesCommonRecords`에서 회원가입 성공 확인 |
| SMK-002 스킬 테스트 결과 저장 | PASS | 동일 UI smoke에서 403 없이 저장 후 온보딩 단계 복귀 확인 |
| SMK-003 프로젝트 생성 | PASS | 동일 UI smoke에서 성공 메시지 또는 프로젝트명 확인 |
| SMK-004 프로젝트 재실행 유지 | PASS | `testProjectPersistsAfterAppRelaunch`에서 앱 종료/재실행 후 프로젝트명 확인 |
| SMK-005 작업공간 단수 저장 | PASS | `testWorkspaceRowCounterPersistsAfterAppRelaunch`에서 다음 단 저장 및 앱 재실행 후 유지 확인 |
| SMK-006 작업시간 기록 | PASS | `testWorkspaceWorkSessionCanBeRecorded`에서 10초 이상 작업시간 종료 후 세션 내역 진입 확인 |
| SMK-007 게이지 기록 저장 | PASS | 동일 UI smoke에서 `세탁 전 게이지를 저장했어요.` 확인 |
| SMK-008 서버 OFF + cache 있음 | NOT_RUN | 수동 네트워크 조작 필요 |
| SMK-009 서버 OFF pending write 후 복구 | NOT_RUN | 수동 네트워크 조작 또는 API stub POM 필요 |
| SMK-010 계정 전환 cache 분리 | NOT_RUN | 수동 또는 추가 auth/account POM 필요 |

## 발견/재검증 결함

| ID | 제목 | Severity | 상태 | 근거 |
|---|---|---|---|---|
| DEF-001 | Auth email/password accessibility identifier가 입력칸이 아닌 아이콘에 매칭됨 | Important | Retest Passed | `testCoreUserFlowRegistersAndSavesCommonRecords` 통과. 증거: `evidence/0719_DEF-001_auth_FAIL_element-tree.txt` |

## 1회차 판정

| 항목 | 판정 |
|---|---|
| 신규 사용자가 가입 후 주요 저장 흐름을 사용할 수 있는가 | PASS |
| 저장한 프로젝트가 앱 재실행 후 유지되는가 | PASS |
| Smoke 10 기준 P0가 실행됐는가 | YES |
| 앱 사용 가능성 | 제한적 PASS. 회원가입/스킬 테스트/프로젝트 생성/프로젝트 재실행 유지/작업공간 단수/작업시간/게이지 기본 흐름은 자동화로 통과 |
| 릴리즈 판정 | 아직 No-Go. 오프라인 retry, 계정 전환, 프로젝트 수정/삭제 수동 QA가 남음 |

## 다음 실행 우선순위

| 순서 | 대상 | 이유 |
|---|---|---|
| 1 | SMK-008/009 오프라인 cache/pending retry | 이 앱의 offline-first 핵심 리스크 |
| 2 | SMK-010 계정 전환 | cache scope와 개인정보 리스크 |
| 3 | 프로젝트 수정/삭제 | 데이터 변경과 삭제는 결함 영향이 큼 |

## Evidence 규칙

수동 QA에서 FAIL이 나오면 아래 파일명으로 증거를 남긴다.

| 유형 | 파일명 예시 |
|---|---|
| 스크린샷 | `0719_SMK-004_project-relaunch_FAIL.png` |
| 서버 로그 | `0719_SMK-009_pending-retry_server-log.txt` |
| API 응답 | `0719_SMK-008_cache-fallback_response.json` |
| 결함 원인 메모 | `0719_DEF-002_pending-retry.md` |
