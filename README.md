# 뜨개더 QA

뜨개질을 하면서 도안에 나온 실과 기법을 따로 찾아보는 일이 번거로워, 자료와 단수(뜬 줄 수), 메모를 한곳에 모으는 iOS 앱을 기획했습니다. 아래는 사용자 흐름과 기록 보존을 확인한 테스트 코드, 실행 결과입니다.

[테스트 설계와 주요 사례](docs/qa/submission/github-guide.md)에서 우선순위, 확인 방법과 수정 전후를 읽을 수 있습니다.

## 테스트 코드와 실행 결과

| 확인한 내용 | 설계 또는 테스트 코드 | 실행 결과 |
|---|---|---|
| 첫 사용, 작업 재개, 기법 조회 후 복귀 | [사용자 흐름과 TC](docs/qa/portfolio/05_test_cases.md) | [최초 수동 수행](docs/qa/portfolio/06_manual_execution.md) |
| 일부 항목 오류에도 정상 목록 조회와 메모 보존 | [API와 SQL](qa/api-tests/test_13_row_counter_isolation.py) / [캐시](KnitGetherTests/OfflineFirstProjectRepositoryTests.swift) | [응답과 DB 재검증](docs/qa/validation/2026-10-31/integrity-device/README.md) |
| 도안 교체 취소 시 표시선 보존, 승인 시 교체 | [Appium UI](qa/appium/capture_portfolio.py) | [화면과 실행 조건](docs/qa/submission/evidence/2026-10-04/README.md) |
| 두 기기 충돌 후 미저장 메모 보존과 직접 재저장 | [두 기기 UI](https://github.com/uhaeun/knitgether-app/blob/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa-runs/2026-10-26-session-fix/run_pure_ui.py) / [메모 초안](KnitGetherTests/ProjectWorkspaceViewModelTests.swift) | [화면과 DB 결과](docs/qa/submission/evidence/2026-10-26/README.md) |
| 연관 데이터 변경 후 동시 요청과 롤백 | [HTTP와 PostgreSQL](server/test/projects-concurrency.real-db-spec.ts) | [수정 전후](https://github.com/uhaeun/knitgether-app/blob/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa-runs/2026-10-26-completion/report.md) / [전용 DB 재실행](docs/qa/validation/2026-10-29/README.md) |
| 실제 iPhone의 단수 유지와 카메라 권한 거부 후 복귀 | [실기기 XCUITest](KnitGetherUITests/DeviceLocalFlowTests.swift) | [로컬 2개 최종 통과, 서버 연결 미완료](docs/qa/validation/2026-10-31/integrity-device/README.md) |

## 상세 기록과 실행 방법

[기능 기준](docs/qa/portfolio/02_functional_spec.md) / [우선순위 근거](docs/qa/portfolio/03_quality_risk_map.md) / [결함 대장](docs/qa/portfolio/10_defect_catalog.md)

[Appium 실행](qa/appium/README.md) / [API 테스트 실행](qa/api-tests/README.md) / [기록 목차](docs/qa/README.md)
