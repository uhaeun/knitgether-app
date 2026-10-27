# 뜨개더 KnitGether · iOS QA 포트폴리오

도안을 보며 단수를 세고, 작업 기록과 뜨개 재료를 관리하는 SwiftUI iOS 앱입니다. **작업 기록이 화면·API·DB에서 일치하고, 충돌과 앱 종료 후에도 보존되는지**를 중심으로 검증했습니다.

[제출용 읽기 안내](docs/qa/submission/github-guide.md) · [기존 포트폴리오 본문](docs/qa/submission/portfolio.md) · [TC별 최종 결과](qa-runs/2026-10-26-completion/case-results.md)

## 먼저 볼 내용

| 확인할 내용 | 문서 |
|---|---|
| 프로젝트 목적, 역할, 대표 사례와 결과 | [GitHub 제출 안내](docs/qa/submission/github-guide.md) |
| 최신 실행 환경·발견·검증 범위 | [2026-10-26 최종 QA 보고서](qa-runs/2026-10-26-completion/report.md) |
| 요구사항 → 테스트 → 결함 추적 | [기능 기준](docs/qa/portfolio/02_functional_spec.md) · [RTM](docs/qa/portfolio/09_test_case_master.md) · [결함 대장](docs/qa/portfolio/10_defect_catalog.md) |
| 수정과 코드 검토 | [PR #48](https://github.com/uhaeun/knitgether-app/pull/48) · [Codex 리뷰](qa-runs/2026-10-26-completion/code-review.md) |

## 담당 역할

유하은은 앱을 기획하고, 기능별 기대 결과와 QA 우선순위, 동시 수정 시 데이터 보존·직접 재저장 기준, cm 고정 및 계정·프로젝트별 메모 초안 정책을 결정했습니다. 기존 수동 테스트·Postman·Charles·SQL 수행 이력은 [포트폴리오 본문](docs/qa/submission/portfolio.md)에 기록했습니다.

앱·서버 구현에는 AI 도구를 활용했습니다. **2026-10-24~26 후속 검증의 환경 구성·코드 보완·자동화 실행·판정·증거 수집·코드 리뷰·병합은 Codex가 수행했습니다.** 이를 유하은의 직접 실행이나 독립된 사람의 코드 리뷰·배포 승인으로 기록하지 않습니다.

## 대표 검증 사례

| 사례 | QA 판단과 확인 | 증거 |
|---|---|---|
| SYNC-11 · 동일 계정 동시 메모 수정 | 먼저 저장한 값과 다른 기기의 미저장 입력을 보존하고, 409 안내 뒤 직접 재저장해야 함 | [두 기기 실행](qa-runs/2026-10-26-session-fix/report.md) |
| 자식 API · 오래된 전체 저장 | 행 안내·작업 세션·도안 변경도 오래된 전체 저장으로 사라지면 안 됨. 추가 경로 6 FAIL 및 ID 범위 3 FAIL 재현 후 수정 | [최종 발견·조치](qa-runs/2026-10-26-completion/code-review.md) |
| UI-03 · cm 고정 | 단위 선택 제거와 함께 과거 preferredUnits 값이 실제 cm 계산을 바꾸지 않는지 확인 | [두 기기 UI-03 24개 결과](qa-runs/2026-10-26-completion/case-results.md) |

## 최신 완료 상태

제품 병합 기준: **`0d0ba22`**, [PR #48](https://github.com/uhaeun/knitgether-app/pull/48). 아래는 2026-10-26 최종 검증 및 10-27 완료 기록입니다. 이후 문서 변경을 새 제품 실행으로 세지 않습니다.

| 검증 층 | 실행 결과 |
|---|---|
| 실제 HTTP + PostgreSQL 회귀 | 40 PASS / 0 SKIP |
| 서버 경로·파일 회귀 | 147 PASS |
| API·네트워크·DB 회귀 | 75 PASS |
| Swift 내부 기능 | 359 PASS / 41 suites |
| 최종 앱 UI-03 | 독립 시뮬레이터 A12 + B12 = 24 PASS |
| 병합 후 main CI | [4개 job 모두 성공](https://github.com/uhaeun/knitgether-app/actions/runs/40348286022) |

검증 층은 서로 합산하거나 대체하지 않습니다. 기존 SYNC-11 두 기기 19개 확인, 종료 후 초안 3개, 목록 삭제 1개, 오프라인 2개 및 자동 재저장 없음 300초는 **각 당시 빌드의 증거**이며 최종 앱에서 전부 재실행한 결과가 아닙니다. [완료 범위와 병합 후 증거](docs/qa/submission/github-guide.md#완료-범위와-한계)

운영·TestFlight 배포, 실물 iPhone에서의 이번 전체 재검증, 장기 부하/SLA는 미실행입니다. 과거 FAIL과 알려진 한계는 [회차별 기록](qa-runs/README.md)에 보존했습니다.

## 코드와 재현 방법

| 위치 | 내용 |
|---|---|
| [KnitGether/](KnitGether/) | SwiftUI 앱·로컬 저장·동기화 |
| [server/](server/) | NestJS·Prisma·PostgreSQL API |
| [KnitGetherTests/](KnitGetherTests/) | Swift 내부 기능 테스트 |
| [qa/appium/](qa/appium/README.md) | Appium UI 자동화 |
| [qa/api-tests/](qa/api-tests/README.md) | pytest API·네트워크·SQL 검사 |
| [최종 RUNBOOK](qa-runs/2026-10-26-completion/RUNBOOK.md) | 격리 DB·두 시뮬레이터 실행 조건 |
| [개발 모드](docs/dev/modes.md) · [로컬 실행](docs/dev/09_local_device_development.md) | 앱·서버 실행 설정 |

CI 구성은 [.github/workflows/ci.yml](.github/workflows/ci.yml)에서 확인할 수 있습니다. 실제 DB 회귀는 QA 전용 DB를 사용하며, 기존 DB 초기화 명령을 제출 안내의 실행 절차로 사용하지 않습니다.

<details>
<summary>이전 포트폴리오·추가 자료</summary>

- [기존 PDF](output/pdf/knitgether_qa_portfolio.pdf): 10월 초 사례 중심의 기존 판본입니다. 최신 동시성·UI-03·병합 결과는 위 GitHub 안내와 보고서를 함께 확인합니다.
- [QA 설계·수동 수행 상세](docs/qa/portfolio/README.md)
- [2026-10-04 화면 촬영과 빌드 출처의 한계](docs/qa/submission/evidence/2026-10-04/README.md)
- [기획·기능 정의](docs/spec/README.md) · [저장소 검토 기록](docs/qa/repository-review/README.md)

</details>
