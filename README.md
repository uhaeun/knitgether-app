# 뜨개더 KnitGether | iOS QA 포트폴리오

뜨개더는 도안, 단수, 작업 기록과 뜨개 재료를 한 프로젝트에서 관리하는 SwiftUI 기반 iOS 앱입니다. 앱 화면, API 응답과 DB 저장값을 대조해 기능 동작과 데이터 보존을 검증한 개인 프로젝트입니다.

앱 기획과 테스트 시나리오 설계, 수동 테스트 및 자동화 결과 확인 과정을 정리했습니다. 앱과 API 서버 구현에는 AI 도구를 활용했습니다. 담당 역할과 검증 범위는 포트폴리오 본문에서 확인할 수 있습니다.

## 먼저 읽을 자료

| 자료 | 내용 |
|---|---|
| **[QA 포트폴리오 PDF](output/pdf/knitgether_qa_portfolio.pdf)** | 프로젝트와 역할, 테스트 전략, 상세 사례 5개, 결과와 회고. 총 21쪽 |
| [GitHub에서 본문 읽기](docs/qa/submission/portfolio.md) | PDF와 같은 본문 및 검증 화면 8장. 사진을 누르면 원본 확인 가능 |
| [추가 검증 화면과 실행 기록](docs/qa/submission/evidence/2026-10-04/README.md) | 도안 교체와 페이지 복귀를 Appium으로 다시 확인한 기록 |
| [상세 QA 기록](docs/qa/portfolio/README.md) | 테스트 설계, 수동 실행, 결함 및 수정 후 확인 이력 |

## 주요 검증 사례

| 사례 | 검증 관점 | 주요 도구 또는 방법 |
|---|---|---|
| 도안 교체 시 드로잉 유실 | 취소하면 보존하고 승인하면 삭제하는지 확인 | 수동 확인, Appium |
| 단수 정보 누락으로 목록 조회 실패 | 오류 항목 한 건이 정상 프로젝트 조회에 미치는 영향 확인 | API 응답 비교, PostgreSQL, pytest |
| 다른 탭에서 복귀하면 도안 페이지 초기화 | 이동 경로별 기대 결과를 정하고 같은 페이지로 복귀하는지 확인 | 수동 확인, Appium |
| 계정 변경 후 이전 계정의 프로젝트 노출 | 서버 응답과 앱에 남은 데이터를 비교해 원인 구분 | API와 저장 데이터 대조, Appium, Swift Testing |
| 앱 강제 종료 후 단수 기록 복구 | 저장 응답 전후의 종료 시점을 나누고 최종 기록 보존 확인 | Charles, SQL, 앱 화면과 내부 저장값 확인 |

## 결과를 읽는 기준

- 사용 흐름과 예외 상황을 다룬 설계 묶음은 22건이며, 수동 실행 결과가 기록된 케이스는 21건입니다. 이후 추가한 UI 및 API 자동화 항목은 별도로 관리합니다.
- 과거 실행 결과는 당시 환경과 빌드의 기록입니다. 상세 결과는 [회차별 실행 기록](docs/qa/portfolio/11_execution_results.md)을 참고합니다.
- 2026-10-04 추가 촬영은 설치된 시뮬레이터 앱에서 Codex가 Appium으로 수행했습니다. 사용자의 기존 수행 이력과 구분하며, 검증 범위와 빌드 정보는 [촬영 기록](docs/qa/submission/evidence/2026-10-04/README.md)에 있습니다.

## 저장소 구조

| 경로 | 내용 |
|---|---|
| `docs/qa/submission/` | 포트폴리오 본문과 추가 검증 증거 |
| `output/pdf/` | 포트폴리오 PDF |
| `docs/qa/portfolio/` | 상세 QA 설계, 실행, 결함과 회고 |
| [docs/spec/](docs/spec/README.md) | 기획서와 기능 정의 |
| `docs/dev/` | 앱 구조와 개발 환경 |
| `qa/appium/` | iOS 화면 자동화 |
| `qa/api-tests/` | API 응답과 DB 대조 테스트 |
| `qa/mutation/` | 결함 주입 실험 도구 |
| `KnitGether/` | SwiftUI 앱 |
| `KnitGetherTests/` | 앱 내부 기능 테스트 |
| `KnitGetherQAUITests/` | QA 회귀용 XCUITest |
| `KnitGetherUITests/` | 개발 단계 XCUITest |
| `server/` | NestJS API 서버와 PostgreSQL 데이터 모델 |

실행 방법은 [Appium 안내](qa/appium/README.md)와 [API 테스트 안내](qa/api-tests/README.md)를 참고합니다.

문서와 테스트 도구의 점검 내용은 [저장소 검토 기록](docs/qa/repository-review/README.md), 이후 실제 실행 결과는 [2026-10-04 전체 재검증](docs/qa/validation/2026-10-04/README.md)에 정리했습니다.
