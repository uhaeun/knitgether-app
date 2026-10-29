# 뜨개더 KnitGether

도안을 보며 단수를 기록하고, 작업 메모와 뜨개 재료를 관리하는 SwiftUI iOS 앱입니다. 개인 프로젝트로 기획과 AI를 활용한 구현, QA를 진행했습니다.

## QA 포트폴리오

**[기획 배경부터 대표 검증 사례와 회고까지 읽기 →](docs/qa/submission/github-guide.md)**

작업 기록의 보존을 중심으로 검증했습니다. 본문에서는 직접 수행한 검증과 판단, AI를 활용한 구현과 후속 실행을 구분합니다.

| 대표 사례 | 검증 관점 |
|---|---|
| 도안 교체 시 드로잉 유실 | 삭제 안내와 취소 시 기록 보존 |
| 단수 정보 누락으로 전체 목록 조회 실패 | 화면, API, DB를 통한 원인 확인 |
| 두 기기의 동시 수정 | 선행 저장과 미저장 입력 보존 |
| 화면 이동 후 도안 페이지 유지 | 작업을 이어가는 흐름과 보존 범위 |

## 코드와 실행

| 위치 | 내용 |
|---|---|
| [KnitGether/](KnitGether/) | SwiftUI 앱, 로컬 저장과 동기화 |
| [server/](server/) | NestJS, Prisma, PostgreSQL API |
| [KnitGetherTests/](KnitGetherTests/) | Swift 내부 기능 테스트 |
| [Appium](qa/appium/README.md) | UI 자동화 |
| [pytest](qa/api-tests/README.md) | API, 네트워크, DB 자동화 |

[개발 모드](docs/dev/modes.md) / [로컬 개발](docs/dev/09_local_device_development.md) / [QA 재현 환경](qa-runs/2026-10-26-completion/RUNBOOK.md)

## 상세 기록

[기능 기준](docs/qa/portfolio/02_functional_spec.md) / [RTM](docs/qa/portfolio/09_test_case_master.md) / [결함 대장](docs/qa/portfolio/10_defect_catalog.md) / [추가 검증과 실행 결과](docs/qa/submission/technical-summary.md)

검증 결과는 각 기록의 날짜와 환경 기준입니다. [2026-10-28 Windows 검수](docs/qa/validation/2026-10-28/README.md)에는 파일 경로 호환성으로 인한 서버 테스트 실패가 남아 있습니다.
