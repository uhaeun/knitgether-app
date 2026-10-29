# 뜨개더 · KnitGether

도안을 보며 단수를 세고, 작업 메모와 재료를 관리하는 SwiftUI iOS 앱입니다. Tibero DB QA 5년차인 유하은이 서비스 QA 경험을 넓히기 위해 기획하고 검증한 개인 프로젝트입니다.

**[제출용 포트폴리오 PDF](output/pdf/knitgether_qa_portfolio.pdf) · [GitHub에서 본문 읽기](docs/qa/submission/github-guide.md)**

| 사례 | 확인할 수 있는 QA 역량 |
|---|---|
| 도안 교체 시 드로잉 유실 | 사용자 기록을 기준으로 정상·취소 조건 정의 |
| 한 항목의 오류로 목록 전체 실패 | 화면·API·DB를 연결한 원인 분석 |
| 두 기기의 동시 수정 | 선행 저장과 미저장 입력 보존, 복구 경로 검증 |

본인은 기획, 검증 우선순위와 기대 결과를 정하고 수동·Postman·Charles·SQL 검증을 수행했습니다. AI는 구현과 후속 자동화에 활용했습니다. 역할과 각 실행의 조건은 [본문](docs/qa/submission/github-guide.md)에 설명합니다.

## 테스트와 결과

2026-10-29 서버 회귀 **180 PASS**, 실제 HTTP·PostgreSQL 동시성 **40 PASS**, API·네트워크·DB **76 PASS / 알려진 실패 1개**를 확인했습니다. 오류 프로젝트의 개별 조회 500은 열린 과제입니다. 계층별 수치는 중복될 수 있으며 전체 E2E 건수로 합산하지 않습니다. iOS 화면은 본문의 과거 실행 증거를 사용합니다.

- [이번 결과·항목별 근거·재현 방법](docs/qa/validation/2026-10-29/README.md)
- [기능 기준](docs/qa/portfolio/02_functional_spec.md) · [테스트·RTM](docs/qa/portfolio/09_test_case_master.md) · [결함 대장](docs/qa/portfolio/10_defect_catalog.md)

## 코드와 실행

| 위치 | 내용 |
|---|---|
| [KnitGether/](KnitGether/) | SwiftUI 앱과 로컬 저장·동기화 |
| [server/](server/) | NestJS·Prisma·PostgreSQL API |
| [qa/appium/](qa/appium/README.md) | 화면 자동화 |
| [qa/api-tests/](qa/api-tests/README.md) | API·네트워크·SQL 검증 |
| [KnitGetherTests/](KnitGetherTests/) | 앱 내부 기능과 저장 상태 검증 |

[개발 환경](docs/dev/modes.md) · [기기 연결과 로컬 개발](docs/dev/09_local_device_development.md) · [실행 기록 목차](qa-runs/README.md)
