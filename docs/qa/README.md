# QA 문서

[QA 포트폴리오](submission/github-guide.md)는 대표 사례의 문제, 판단 기준, 수정 후 결과를 정리한 본문입니다. [PDF](../../output/pdf/knitgether_qa_portfolio.pdf)도 같은 내용을 담습니다.

## 테스트 설계와 추적

| 문서 | 확인할 내용 |
|---|---|
| [기능 기준](portfolio/02_functional_spec.md) | 화면별 기대 동작과 후속 정책 |
| [리스크](portfolio/03_quality_risk_map.md) · [검증 전략](portfolio/04_test_strategy.md) | 데이터 유실·동기화 중심의 우선순위 |
| [테스트 설계](portfolio/05_test_cases.md) · [케이스·RTM](portfolio/09_test_case_master.md) | 정상·실패·복구 조건과 요구사항 추적 |
| [수동 수행](portfolio/06_manual_execution.md) · [API·네트워크](portfolio/07_api_and_network.md) | 최초 판정과 화면·HTTP·SQL 대조 |
| [결함 대장](portfolio/10_defect_catalog.md) | 재현 조건, 기대·실제 결과, 후속 조치 |
| [자동화 코드 안내](portfolio/13_automation_showcase.md) | 실행 가능한 테스트와 확인 범위 |

설계 수와 실행 수, 최초 실패와 수정 후 통과를 구분했습니다. 각 문서의 날짜와 제품 커밋이 그 기록의 기준입니다.

## 실행 결과

| 기록 | 범위 |
|---|---|
| [10월 31일 조회 계약·캐시·실기기](validation/2026-10-31/integrity-device/README.md) | 최신 결과. 실제 iPhone의 로컬 흐름 2개 PASS, 서버 연결은 미완료 |
| [10월 31일 iOS 실패 분석·재검증](validation/2026-10-31/README.md) | 온보딩 실패, 시험 준비 보완과 후속 결과 |
| [10월 29일 서버·DB](validation/2026-10-29/README.md) | 전용 DB 재실행과 경로 호환성. 당시 개별 조회 500은 후속 기록에서 보완 |

## 폴더 구성

- `submission/`: 포트폴리오 본문, 대표 화면·DB 근거, PDF 생성 도구와 글꼴
- `portfolio/`: 기능·리스크·전략·테스트·결함 문서와 최초 수행 근거
- `validation/`: 회차별 조건, 결과 요약과 선별한 증거

이전 실행 원본과 중복 문서는 [보존 이력](history.md)에서 확인할 수 있습니다. 당시 실패와 환경 제약도 원본 그대로 남겼습니다.
