# 뜨개더 QA

PDF에 적은 사례의 테스트 코드와 실행 결과입니다.

| 사례 | 테스트 코드 | 실행 결과 |
|---|---|---|
| 도안 교체·페이지 복귀 | [Appium](qa/appium/capture_portfolio.py) | [화면과 실행 조건](docs/qa/submission/evidence/2026-10-04/README.md) |
| 단수 정보 누락·목록 오류·캐시 유지 | [API·SQL](qa/api-tests/test_13_row_counter_isolation.py) · [기기 캐시](KnitGetherTests/OfflineFirstProjectRepositoryTests.swift) | [조회 오류 재검증](docs/qa/validation/2026-10-31/integrity-device/README.md) |
| 두 기기 동시 수정·미저장 메모 | [두 기기 화면](https://github.com/uhaeun/knitgether-app/blob/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa-runs/2026-10-26-session-fix/run_pure_ui.py) · [메모 초안](KnitGetherTests/ProjectWorkspaceViewModelTests.swift) | [화면·HTTP·DB](docs/qa/submission/evidence/2026-10-26/README.md) |
| 연관 데이터 변경·동시 요청·롤백 | [HTTP·PostgreSQL](server/test/projects-concurrency.real-db-spec.ts) | [수정 전후](https://github.com/uhaeun/knitgether-app/blob/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa-runs/2026-10-26-completion/report.md) · [전용 DB 재실행](docs/qa/validation/2026-10-29/README.md) |
| 가입·저장 등 시뮬레이터 UI | [XCUITest](KnitGetherUITests/KnitGetherUITests.swift) | [온보딩 실패와 재검증](docs/qa/validation/2026-10-31/README.md) |
| 실제 iPhone의 단수 유지·카메라 권한 거부 | [실기기 XCUITest](KnitGetherUITests/DeviceLocalFlowTests.swift) | [실기기 결과 (서버 연결 미완료)](docs/qa/validation/2026-10-31/integrity-device/README.md) |
