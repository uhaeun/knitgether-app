# 뜨개더 KnitGether

도안을 보며 단수를 세고, 작업 기록과 뜨개 재료를 관리하는 SwiftUI iOS 앱입니다. 작업 기록이 화면·API·DB에서 일치하고, 동시 수정과 앱 종료 후에도 보존되는지 검증했습니다.

## QA 포트폴리오

| 제출 자료 | 내용 |
|---|---|
| **[GitHub QA 포트폴리오](docs/qa/submission/github-guide.md)** | 담당 역할, 대표 사례 3개, 실행 증거와 상세 기록 |
| **[PDF 포트폴리오 · 14쪽](output/pdf/knitgether_qa_portfolio.pdf)** | 프로젝트 소개, 테스트 전략, 주요 결함 사례와 후속 검증 |

### 대표 검증 사례

| 사례 | 검증한 위험과 판단 |
|---|---|
| [도안 교체 시 드로잉 유실](docs/qa/submission/portfolio.md#03-1-도안-교체-시-드로잉-유실-def-10) | 교체 성공뿐 아니라 삭제 안내, 취소 시 보존, 승인 후 제거를 구분 |
| [동시 수정과 자식 데이터 보존](docs/qa/submission/github-guide.md#사례-1--sync-11-동시-수정에서-기록-보존) | 409 응답, 미저장 입력 보존, 직접 재저장과 실제 HTTP·SQL 결과를 연결 |
| [과거 단위값과 cm 계산](docs/qa/submission/github-guide.md#사례-3--ui-03-cm-고정과-과거-단위값) | 단위 선택 UI 제거와 별도로 과거 프로필 값의 계산 영향을 검증 |

동시 메모 수정(SYNC-11), 자식 API 변경 보존, cm 고정 정책(UI-03)을 중심으로 요구사항 판단부터 재현·수정 후 확인까지 정리했습니다. 유하은의 기획·QA 기준 결정 및 기존 수행 이력과 Codex의 후속 구현·실행·판정을 구분했습니다.

**담당 역할:** 앱 기획, 테스트 우선순위·기대 결과 결정, 기존 수동·Postman·Charles·SQL·Appium 수행 이력. 후속 구현과 자동 실행은 Codex가 수행했으며, 사례별 원본 기록에서 수행 주체와 검증 범위를 확인할 수 있습니다.

- [TC별 최종 결과](qa-runs/2026-10-26-completion/case-results.md) · [실행 보고서](qa-runs/2026-10-26-completion/report.md)
- [기능 기준](docs/qa/portfolio/02_functional_spec.md) · [RTM](docs/qa/portfolio/09_test_case_master.md) · [결함 대장](docs/qa/portfolio/10_defect_catalog.md)
- [제품 수정 PR #48](https://github.com/uhaeun/knitgether-app/pull/48) · [제품 병합 후 CI](https://github.com/uhaeun/knitgether-app/actions/runs/40348286022)

## 코드와 실행

| 위치 | 내용 |
|---|---|
| [KnitGether/](KnitGether/) | SwiftUI 앱·로컬 저장·동기화 |
| [server/](server/) | NestJS·Prisma·PostgreSQL API |
| [KnitGetherTests/](KnitGetherTests/) | Swift 내부 기능 테스트 |
| [qa/appium/](qa/appium/README.md) | Appium UI 자동화 |
| [qa/api-tests/](qa/api-tests/README.md) | pytest API·네트워크·SQL 검사 |
| [최종 RUNBOOK](qa-runs/2026-10-26-completion/RUNBOOK.md) | 격리 DB·두 시뮬레이터 검증 조건 |

[개발 모드](docs/dev/modes.md) · [로컬 개발](docs/dev/09_local_device_development.md) · [CI 구성](.github/workflows/ci.yml)

상세 실행 기록과 이전 판본은 [QA 포트폴리오](docs/qa/submission/github-guide.md)에서 연결합니다. 검증 결과는 각 기록의 날짜·빌드 기준이며, 문서 변경을 새로운 제품 시험이나 배포로 집계하지 않습니다.
