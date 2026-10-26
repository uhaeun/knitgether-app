# 뜨개더 KnitGether

도안, 단수, 작업 기록과 뜨개 재료를 관리하는 SwiftUI 기반 iOS 앱입니다. 앱 화면·API 응답·DB 저장값을 대조해 기능과 데이터 보존을 검증한 개인 프로젝트입니다.

**[QA 포트폴리오 PDF](output/pdf/knitgether_qa_portfolio.pdf)** · [본문과 검증 화면](docs/qa/submission/portfolio.md) · [상세 QA 기록](docs/qa/portfolio/README.md)

## 담당 역할

유하은이 앱 기능과 화면 연결 관계를 기획하고, 테스트 조건과 기대 결과를 정했습니다. 수동 테스트, Postman API 확인, Charles를 이용한 통신 조건 변경, SQL 저장값 대조를 수행했습니다. Appium 자동화 대상과 조건을 정하고 테스트 코드를 보완·실행하며 실패 결과를 확인했습니다.

앱과 API 서버 구현에는 AI 도구를 활용했습니다. AI가 작성한 구현과 테스트도 요구사항에 맞는지 검토했습니다. 역할과 검증 환경은 [포트폴리오 본문](docs/qa/submission/portfolio.md)에 정리했습니다.

## 주요 검증 사례

| 사례 | 문제와 확인 결과 |
|---|---|
| 도안 교체 시 드로잉 유실 | 삭제 확인창 추가 후 취소 시 보존·승인 시 삭제를 확인 |
| 단수 정보 누락으로 목록 조회 실패 | 수정 후 오류 항목을 제외하고 정상 목록 반환 확인. 오류 항목 개별 조회는 후속 과제 |
| 탭 복귀 후 도안 페이지 초기화 | 수정 후 홈·사전 조회에서 돌아왔을 때 같은 페이지 유지 확인 |
| 계정 변경 후 이전 계정 기록 노출 | 캐시 노출과 타 계정 업로드를 구분하고, 수정 후 화면 숨김·계정별 폴더 정리 확인 |
| 앱 강제 종료 후 단수 기록 복구 | 저장 응답 전후에 앱을 종료하고, 재실행·통신 재개 후 화면·로컬·서버의 단수 일치 확인 |

수정 후 Appium 또는 pytest로 다시 확인한 범위와 수동으로 확인한 범위는 [결함·수정 기록](docs/qa/portfolio/10_defect_catalog.md)과 [회차별 실행 기록](docs/qa/portfolio/11_execution_results.md)에 구분했습니다.

## 검증 기록의 범위

사용 흐름과 예외 상황의 설계 묶음 22건 중 21건에 수동 실행 결과를 남겼습니다. 이후 추가한 UI·API 자동화 항목은 별도로 관리합니다. 각 결과는 당시 환경과 빌드에 한정됩니다.

2026-10-04 도안 교체·페이지 복귀 추가 촬영은 Codex가 설치된 시뮬레이터 앱에서 Appium으로 수행했습니다. 유하은의 기존 수행 이력과 구분하며, 당시 설치 앱의 동작을 확인한 자료입니다. 설치 앱의 소스 커밋은 저장소 HEAD와 같다고 확인되지 않았습니다. [촬영 환경·원본 화면](docs/qa/submission/evidence/2026-10-04/README.md)

## 코드와 문서

| 경로 | 내용 |
|---|---|
| [기획·기능 정의](docs/spec/README.md) | 앱 기능과 화면 관계 |
| [제출용 자료](docs/qa/submission/) | 포트폴리오 본문과 화면 증거 |
| [QA 상세 기록](docs/qa/portfolio/README.md) | 설계·수행·결함·자동화·회고 |
| [Appium](qa/appium/README.md) · [API 테스트](qa/api-tests/README.md) | 자동화 코드와 실행 방법 |
| `KnitGether/` · `server/` | SwiftUI 앱, NestJS API 서버와 PostgreSQL 모델 |
| `KnitGetherTests/` · `KnitGetherQAUITests/` · `KnitGetherUITests/` | 내부 기능·QA 회귀·개발 단계 테스트 |
| `qa/mutation/` | 결함 주입 실험 도구 |

[저장소 검토 기록](docs/qa/repository-review/README.md) · [2026-10-04 재검증 결과](docs/qa/validation/2026-10-04/README.md) · [앱 구조·개발 환경](docs/dev/)
