# 뜨개더 · KnitGether

뜨개 도안을 보면서 단수를 세고, 메모와 재료를 관리하는 iOS 앱입니다. 도안과 용어 검색, 작업 기록을 한곳에서 이어 쓸 수 있도록 만들었습니다.

DB QA에서는 기능과 버그 수정 결과를 주로 테스트했습니다. 모바일 앱에서는 화면을 조작한 뒤 API와 저장 데이터까지 어떻게 바뀌는지 확인해 보고 싶었습니다.

[QA 포트폴리오 (PDF)](output/pdf/knitgether_qa_portfolio.pdf) · [테스트 과정과 결과](docs/qa/submission/github-guide.md)

## 테스트하면서 발견한 문제

- **도안을 바꾸면 그려 둔 선이 사라졌습니다.** 교체를 취소하면 기존 도안과 선이 남고, 삭제 안내에 동의했을 때만 바뀌어야 한다고 정했습니다.
- **목록은 보이는데 새 값이 반영되지 않았습니다.** DB의 단수는 99인데 화면은 계속 22였습니다. 프로젝트 하나의 단수 정보가 빠져 목록 API 전체가 500으로 실패하고, 앱에는 이전 목록만 남아 있었습니다.
- **두 기기에서 같은 메모를 수정하면 충돌했습니다.** 먼저 저장한 값이 DB에 남는지, 나중 기기의 미저장 메모도 남는지, 사용자가 다시 저장할 수 있는지를 나눠 확인했습니다.

각 문제의 재현 조건, 화면과 SQL, 수정 후 결과는 [본문](docs/qa/submission/github-guide.md)에 정리했습니다.

앱 기획과 테스트 우선순위·기대 결과를 정하고, 초기 수동 검증에 Postman·Charles·SQL을 사용했습니다. 앱·서버 구현과 후속 자동화의 코드 작성·실행·증거 수집에는 AI를 활용했습니다.

## 현재 확인한 범위

[10월 31일 실행 기록](docs/qa/validation/2026-10-31/integrity-device/README.md)에 서버·DB·API·Swift·화면 테스트 결과가 있습니다. 목록에서 제외된 오류 항목의 캐시가 지워지는 문제와, 개별 조회의 500 응답도 후속 수정·재검증에 포함했습니다.

iPhone 16 Pro에서는 비로그인 상태의 단수 기록이 앱 종료·복귀 뒤 유지되는지, 카메라 권한을 거부했을 때 안내를 보고 작업 화면으로 돌아올 수 있는지 확인했습니다. 두 흐름은 각각 최종 재실행에서 통과했습니다. 가입·서버 동기화는 로컬 네트워크 차단으로 끝내지 못했고, 원인은 아직 확인하지 못했습니다.

[테스트 설계·케이스·결함 대장](docs/qa/README.md) · [앞선 iOS 실패와 재검증](docs/qa/validation/2026-10-31/README.md)

## 소스와 실행

| 위치 | 내용 |
|---|---|
| [KnitGether/](KnitGether/) · [server/](server/) | SwiftUI 앱, NestJS·Prisma·PostgreSQL API |
| [KnitGetherTests/](KnitGetherTests/) | 앱 내부 기능과 저장 상태 테스트 |
| [KnitGetherUITests/](KnitGetherUITests/) · [KnitGetherQAUITests/](KnitGetherQAUITests/) | XCUITest 화면·실기기·결함 회귀 테스트 |
| [qa/appium/](qa/appium/README.md) · [qa/api-tests/](qa/api-tests/README.md) | Appium 화면 테스트, API·네트워크·SQL 테스트 |
| [docs/qa/](docs/qa/README.md) · [output/pdf/](output/pdf/) | QA 문서와 포트폴리오 PDF |

[개발 환경](docs/dev/modes.md) · [기기 연결](docs/dev/09_local_device_development.md) · [과거 실행 원본](docs/qa/history.md)
