# iOS 화면 실패 분석과 제출본 재검증

> 후속 결과: 아래 실행 뒤 개별 조회 500과 목록 캐시 보존을 보완했습니다. 359·76 PASS/1 xfail은 당시 이력이며, 최신 회귀는 365·79 PASS/0 xfail입니다. [조회 계약·기기 검증 기록](integrity-device/README.md)

확인 기간: 2026-10-30~31, Asia/Seoul. 최초 CI의 실패 관측값과 시험 준비·판정 보완, 후속 재검증을 연결한 기록입니다. 분석·환경 구성·시험·문서 갱신은 AI가 수행했습니다.

## 최초 실패에서 확인한 사실

[최초 CI, attempt 1](https://github.com/uhaeun/knitgether-app/actions/runs/40893614591/attempts/1)의 제품 기준은 `60c0a708d9f310d1095f99ca1683c83531c0171f`입니다. iPhone 17 Pro, iOS 26.2 시뮬레이터에서 Swift 내부 시험 359개가 통과했고 UI smoke 3개 중 2개 통과·1개 실패였습니다.

실패한 항목은 `testCoreUserFlowRegistersAndSavesCommonRecords`입니다. 온보딩에서 ‘계정 만들기 / 로그인’을 누른 뒤 `AuthPage.expectVisible`이 계정 화면을 찾지 못했습니다. 실패 화면은 로그인 폼이 아닌 온보딩의 계정 단계입니다. 이 실패는 회원가입 API의 성공·실패를 판정하기 전에 발생했습니다.

- 버튼의 관측 프레임: x=40.0, y=260.7, width=322.0, height=51.0.
- 합성 탭 좌표: x=201.0, y≈286.17. 관측 프레임 안입니다.
- 탭 이후에도 계정 폼으로 전환되지 않았습니다. 탭 이벤트 기록만으로 실제 전환 완료를 판단할 수 없었습니다.

[최초 UI 결과](evidence/initial-ui-summary.json) / [Swift 결과](evidence/initial-unit-summary.json) / [실패 화면](evidence/initial-onboarding-failure.png) / [화면 계층](evidence/initial-ui-hierarchy.txt) / [탭 좌표](evidence/initial-tap.json)

## 원인 판단과 보완

확정한 실패 지점은 첫 계정 화면으로의 전환 미완료입니다. 첨부 자료만으로 SwiftUI 내부나 이벤트 전달의 정확한 원인을 확정하지 않았습니다. 최초 실행의 기동 상태를 배제하지 못했으므로, 제품 로직을 추측으로 바꾸지 않고 아래 준비·판정을 보완했습니다.

| 발견한 공백 | 변경 |
|---|---|
| CI가 시뮬레이터를 초기화한 뒤 바로 XCTest를 시작 | `simctl bootstatus -b`로 첫 부팅·데이터 준비 완료를 기다리고 로그 보존 |
| 탭 후 바로 로그아웃 확인·회원가입 단계로 진행 | `goToAuth` 안에서 계정 화면 도착을 즉시 확인 |

기존의 가입·프로젝트·게이지 저장·오프라인 복구 단언을 유지했습니다. 실패를 SKIP으로 바꾸거나, 성공할 때까지 탭·테스트를 자동 반복하는 처리는 추가하지 않았습니다. 보완 커밋은 [`72bfa8d1e3530d7a9ec8241b14e5b70fa042de1d`](https://github.com/uhaeun/knitgether-app/commit/72bfa8d1e3530d7a9ec8241b14e5b70fa042de1d)이며 앱·서버 제품 로직은 이 보완에서 변경하지 않았습니다.

## 로컬 시험의 조건 구분

새 전용 iOS 26.2 시뮬레이터와 별도 PostgreSQL DB `knitgether_qa_sync11_ios_20261030`, API 포트 3317을 사용했습니다. 기존 기기·개발 DB는 초기화하지 않았습니다.

첫 로컬 실행은 계정 화면에 도착했지만 가입 단계에서 실패했습니다. 실행 셸에 지정한 서버 설정이 XCTest 실행기에 전달되지 않아 기본 포트 3000을 참조한 준비 오류였습니다. 전용 DB에는 계정이 만들어지지 않았습니다. 따라서 최초 CI의 화면 전환 실패 재현이나 제품 결함으로 집계하지 않았습니다.

다음 실행에서는 별도 `.xctestrun`의 UI test `EnvironmentVariables`에 `KG_API_BASE_URL=http://127.0.0.1:3317/api/v1`을 명시했습니다. 전용 서버의 health 응답과 전용 DB의 계정·프로젝트 생성도 대조했습니다. 임시 실행 설정은 저장소에 포함하지 않았습니다.

기존 CI의 수정 전 재실행 attempt 2는 새 검증 커밋의 CI가 시작되면서 취소됐습니다. 취소된 재실행을 통과로 판정하거나 최초 실패를 덮어쓰지 않습니다.

## 로컬 재검증 결과

| 실행 | 결과 | 범위 |
|---|---|---|
| 보완 후 UI smoke 전체 | 3 PASS / 0 FAIL / 0 SKIP | 가입·프로젝트·게이지 저장, 오프라인 생성 후 복구, 캐시 조회 |
| 전용 기기 초기화·부팅 완료 후 핵심 흐름 | 1 PASS / 0 FAIL / 0 SKIP | 최초 실패 시나리오를 초기화 후 별도 확인 |

두 번째 1개는 같은 핵심 시나리오의 조건별 재실행이며 독립된 새 TC로 합산하지 않습니다. 실제 기기 전체 검증을 의미하지 않습니다.

[로컬 3개 결과](evidence/local-ui-summary.json) / [초기화 후 핵심 결과](evidence/local-reset-core-summary.json) / [부팅 완료 관측](evidence/local-boot-status.json)

## 원격 CI 재검증 결과

검증 소스: `72bfa8d1e3530d7a9ec8241b14e5b70fa042de1d`.

| 검증 | 결과 | 근거 |
|---|---|---|
| 제품 CI | 4개 job 모두 성공 | 서버, 실제 DB, API, iOS |
| 서버 회귀 | 180 PASS | 13 suites |
| 실제 PostgreSQL·HTTP | 40 PASS | 경합, 롤백, 연관 데이터·파일 |
| API·네트워크·DB | 76 PASS / 1 xfail | 알려진 개별 조회 500 유지 |
| Swift 내부 시험 | 359 PASS | 41 suites |
| iOS UI smoke | 3 PASS / 0 FAIL | 세 시나리오 모두 완료 |
| Windows·Ubuntu 파일 경로 | 두 job 모두 성공 | 각각 경로 33개 |

CI 로그에서 부팅 완료(UTC 15:14:10) 후 UI smoke 시작을 확인했습니다. XCTest의 개별 `passed`, 전체 3개·실패 0, 종료 성공 기록까지 대조했습니다. job의 진행 상태나 종료 정리 단계만으로 통과를 판단하지 않았습니다.

[제품 CI](https://github.com/uhaeun/knitgether-app/actions/runs/41076192341) / [경로 CI](https://github.com/uhaeun/knitgether-app/actions/runs/41076192356) / [완료 상태 스냅샷](evidence/ci-status.json) / [로그의 개별 시험 결과](evidence/ci-log-summary.json)

후속 CI와 로컬 통과는 이번 조건의 결과입니다. 최초 전환 실패의 내부 원인을 확정하거나 모든 환경에서 재발하지 않는다고 판정한 것은 아닙니다.

## 재현 방법

서버와 새 전용 DB를 준비한 뒤, 사용할 시뮬레이터의 부팅 완료를 확인합니다. 실제 CI 절차는 [워크플로](../../../../.github/workflows/ci.yml)에 있습니다.

```sh
xcrun simctl bootstatus YOUR_QA_SIMULATOR_ID -b
xcodebuild test \
  -project KnitGether.xcodeproj \
  -scheme 'KnitGether Local Simulator' \
  -destination 'id=YOUR_QA_SIMULATOR_ID' \
  -only-testing:KnitGetherUITests/KnitGetherUITests/testCoreUserFlowRegistersAndSavesCommonRecords \
  -only-testing:KnitGetherUITests/KnitGetherUITests/testServerOffPendingProjectSyncsAfterServerRecovers \
  -only-testing:KnitGetherUITests/KnitGetherUITests/testServerOffWithCachedProjectShowsCachedProject \
  -parallel-testing-enabled NO
```

기본 API 포트는 3000입니다. 다른 포트를 사용할 때는 실행 셸의 변수만으로 전달됐다고 가정하지 말고, XCTest 실행 설정에 `KG_API_BASE_URL`을 넣고 실제 서버·DB 관측으로 확인합니다.

## 한계와 남은 결함

이 시험은 지정한 세 UI 시나리오와 계층별 회귀 범위입니다. 실제 iPhone, 모든 OS·기기 조합, 장기 경합, 충돌 중 모든 폼의 보존을 보장하지 않습니다. 원래 전환 실패의 내부 원인이 확정되지 않았으므로 최초 실패 자료를 보존합니다.

오류 프로젝트 개별 조회의 500은 기존의 알려진 실패이며 이번 iOS 보완과 별도입니다. [이전 서버·API 결과](../2026-10-29/README.md)에서 해당 범위를 확인할 수 있습니다.

## 제출 자료 검수

최신 결과를 README와 8쪽 포트폴리오에 반영했습니다. 원래 실패와 알려진 500을 유지하고, 계층별 결과와 조건별 재실행을 구분합니다. PDF 전 페이지를 이미지로 확인하고 한글 글꼴·텍스트 추출·증거 링크·로컬 경로를 검사했습니다. [검사 결과](submission-audit.json)
