# 뜨개더 QA

도안을 보며 단수를 세고 메모·재료를 관리하는 개인 iOS 앱입니다. 화면 조작 후 API 응답, DB 저장값과 기기 캐시를 대조해 테스트했습니다.

앱 기획과 테스트 우선순위·기대 결과를 정하고, 초기 수동 검증에 Postman·Charles·SQL을 사용했습니다. 구현과 후속 자동화의 코드 작성·실행·증거 수집에는 AI를 활용했습니다.

## 검증 범위

- 저장·동기화: 두 기기 충돌, 미저장 입력 유지와 직접 재저장
- 도안·작업 화면: 교체 취소·승인과 화면 복귀
- 종료·오프라인·계정: 재실행 뒤 기록, 서버 복구 후 저장과 계정별 분리

## 대표 테스트와 결과

| 사례 | 테스트 코드 | 실행 결과 |
|---|---|---|
| 도안 교체 | [Appium](qa/appium/capture_portfolio.py) | [화면과 실행 조건](docs/qa/submission/evidence/2026-10-04/README.md) |
| 단수 정보 누락·목록 오류·캐시 유지 | [API·SQL](qa/api-tests/test_13_row_counter_isolation.py) · [기기 캐시](KnitGetherTests/OfflineFirstProjectRepositoryTests.swift) | [조회 오류 재검증](docs/qa/validation/2026-10-31/integrity-device/README.md) |
| 두 기기 동시 수정·미저장 메모 | [두 기기 화면](https://github.com/uhaeun/knitgether-app/blob/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa-runs/2026-10-26-session-fix/run_pure_ui.py) · [메모 초안](KnitGetherTests/ProjectWorkspaceViewModelTests.swift) | [화면·HTTP·DB](docs/qa/submission/evidence/2026-10-26/README.md) |
| 연관 데이터 변경·동시 요청·롤백 | [HTTP·PostgreSQL](server/test/projects-concurrency.real-db-spec.ts) | [수정 전후](https://github.com/uhaeun/knitgether-app/blob/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa-runs/2026-10-26-completion/report.md) · [전용 DB 재실행](docs/qa/validation/2026-10-29/README.md) |
| 실제 iPhone의 단수 유지·카메라 권한 거부 | [실기기 XCUITest](KnitGetherUITests/DeviceLocalFlowTests.swift) | [실기기 결과 (서버 연결 미완료)](docs/qa/validation/2026-10-31/integrity-device/README.md) |

## 설계와 실행 방법

[기능별 기대 동작](docs/qa/portfolio/02_functional_spec.md) · [테스트 설계](docs/qa/portfolio/05_test_cases.md) · [수동 수행](docs/qa/portfolio/06_manual_execution.md) · [결함 대장](docs/qa/portfolio/10_defect_catalog.md)

[Appium 실행](qa/appium/README.md) · [API 테스트 실행](qa/api-tests/README.md)
