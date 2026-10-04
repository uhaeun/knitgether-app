# QA 기록 안내

처음 읽는 분은 [포트폴리오 PDF](../../../output/pdf/knitgether_qa_portfolio.pdf) 또는 [포트폴리오 본문](../submission/portfolio.md)을 먼저 확인해 주세요. 아래 문서는 사례의 설계와 판정 근거를 더 자세히 볼 때 사용합니다.

## 권장 읽기 순서

[05 테스트 설계](05_test_cases.md) → [06 수동 실행](06_manual_execution.md) → [10 결함과 수정](10_defect_catalog.md) → [11 결과](11_execution_results.md)

## 전체 문서

| 문서 | 내용 |
|---|---|
| [00_프로젝트 배경](00_project_background.md) | 프로젝트 배경 |
| [01_테스트 대상 분석](01_test_target_analysis.md) | 상세 QA 기록 |
| [02_기능 동작 정의서](02_functional_spec.md) | 당시 검증 기준과 명세 변경 |
| [03_품질리스크맵](03_quality_risk_map.md) | 상세 QA 기록 |
| [04_테스트전략](04_test_strategy.md) | 상세 QA 기록 |
| [05_테스트케이스](05_test_cases.md) | 상세 QA 기록 |
| [06_수동 실행 로그](06_manual_execution.md) | 상세 QA 기록 |
| [07_API와 네트워크 검증](07_api_and_network.md) | 상세 QA 기록 |
| [08_자동화 도구 비교](08_automation_comparison.md) | 상세 QA 기록 |
| [09_테스트 케이스 마스터](09_test_case_master.md) | 설계 ID와 케이스 목록 |
| [10_결함 카탈로그](10_defect_catalog.md) | 결함 번호, 수정과 근거 |
| [11_실행 결과](11_execution_results.md) | 회차별 결과와 정정 이력 |
| [12_품질 지표 스코어카드](12_quality_metrics.md) | 측정 기준별 수치 |
| [13_자동화 구성과 검증 범위](13_automation_showcase.md) | 현재 자동화 구성 안내 |
| [14_관찰과 개선 제안](14_observations.md) | 상세 QA 기록 |
| [15_릴리즈 판정](15_release_decision.md) | 과거 내부 릴리즈 판단 |
| [16_테스트 차터](16_test_charters.md) | 탐색 기록의 사후 재구성 |

## 기록을 읽는 기준

- 1차 설계는 22건, 수동 수행 기록은 21건입니다. 최초 10 PASS/11 FAIL과 카운터 수정 후 값을 포함한 11 PASS/10 FAIL 집계는 구분합니다.
- DEF는 결함 번호, TC와 UI 및 API 번호는 테스트 항목입니다. 서로 일대일 관계가 아닙니다.
- 대장 30개 항목은 DEF 29개와 명세 항목 1개입니다. 발견 경위, 수정 여부와 실행 검증 여부도 별도입니다.
- 과거 로그, 시트와 이미지는 당시 상태를 보존합니다. 로그가 없는 문서 집계는 이번 실행 결과로 인용하지 않습니다.
- 15의 Go는 과거 개인 프로젝트 내부 판단이며 실제 배포 승인 기록이 아닙니다.
- 16은 수행 뒤 기록을 재구성한 문서입니다. 사전에 차터를 작성해 수행했다는 근거로 사용하지 않습니다.

[이번 저장소 검토](../repository-review/README.md)에서 수정 내용과 확인 범위를 볼 수 있습니다.
