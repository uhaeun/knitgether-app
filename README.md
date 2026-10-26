# 뜨개더 KnitGether

도안을 보며 단수를 세고, 작업 기록과 뜨개 재료를 관리하는 SwiftUI iOS 앱입니다. 앱 화면에 보이는 값이 API 응답, DB 저장값과 맞는지 확인한 QA 기록을 담았습니다.

[포트폴리오 PDF](output/pdf/knitgether_qa_portfolio.pdf) · [본문과 화면](docs/qa/submission/portfolio.md)

앱 기획과 테스트 설계·수행은 유하은이 맡았습니다. 기능별 기대 결과를 정하고, 수동 테스트와 Postman·Charles·SQL을 이용한 확인을 진행했습니다. Appium 자동화 대상과 조건을 정하고 테스트 코드를 보완해 실행했습니다. 앱과 API 서버 구현에는 AI를 사용했습니다.

## 테스트에서 발견한 것

도안을 바꿀 때 안내 없이 드로잉이 지워졌습니다. 삭제 확인창을 추가한 뒤, 취소하면 기존 그림이 남고 승인하면 지워지는지 다시 확인했습니다.

단수 정보가 없는 프로젝트 한 건 때문에 목록 전체가 HTTP 500으로 실패하기도 했습니다. 앱에는 예전 목록이 남아 있어 화면만 보면 알아채기 어려웠습니다. API 응답과 DB를 대조해 원인을 확인했고, 수정 후에는 오류 항목을 제외한 정상 목록이 반환됐습니다. 오류 항목의 개별 조회는 후속 과제로 남았습니다.

이 밖에 탭을 오간 뒤 도안 페이지가 초기화되는 문제, 계정 변경 후 이전 기록이 보이는 문제, 앱 종료 후 단수가 정상 복구되는지도 확인했습니다. [사례별 과정과 결과](docs/qa/submission/portfolio.md)에 재현 조건과 수정 후 확인 내용을 적었습니다.

사용 흐름과 예외 상황별로 묶은 시나리오 22건을 설계하고, 21건의 수동 실행 결과를 남겼습니다. 이후 추가한 UI·API 자동화는 별도 기록이며, 자동화 코드가 있다는 것과 실제 실행을 마친 것은 구분했습니다.

- [테스트 설계와 수행 기록](docs/qa/portfolio/README.md)
- [결함과 수정 이력](docs/qa/portfolio/10_defect_catalog.md)
- [회차별 실행 결과](docs/qa/portfolio/11_execution_results.md)

2026-10-04에는 Codex가 Appium을 실행해 추가 촬영과 재검증을 했습니다. 당시 시뮬레이터에 설치돼 있던 앱을 사용했습니다. 유하은의 기존 수행 이력과는 별도입니다. 설치 앱의 소스 커밋이 저장소 HEAD와 같은지는 확인되지 않았습니다. [촬영 환경과 원본 화면](docs/qa/submission/evidence/2026-10-04/README.md)

## 코드 보기

앱은 `KnitGether/`, API 서버와 PostgreSQL 모델은 `server/`에 있습니다.

- [기획·기능 정의](docs/spec/README.md)
- [Appium 코드와 실행 방법](qa/appium/README.md)
- [API 테스트 코드와 실행 방법](qa/api-tests/README.md)
- [앱 구조와 개발 환경](docs/dev/)

내부 기능 테스트는 `KnitGetherTests/`, QA 회귀용 XCUITest는 `KnitGetherQAUITests/`, 개발 단계 XCUITest는 `KnitGetherUITests/`에 있습니다. 결함 주입 실험은 `qa/mutation/`에 별도로 두었습니다.

[저장소 검토 기록](docs/qa/repository-review/README.md) · [2026-10-04 재검증 결과](docs/qa/validation/2026-10-04/README.md)
