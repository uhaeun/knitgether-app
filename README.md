# 뜨개더 · KnitGether

도안을 보며 단수를 세고, 작업 메모와 재료를 관리하는 SwiftUI iOS 앱입니다.

DB 기능과 버그 수정을 주로 검증해 왔습니다. 앱의 화면 흐름과 API·저장 데이터까지 연결해 테스트해 보고 싶어 뜨개더를 만들었습니다.

**[QA 포트폴리오 (PDF)](output/pdf/knitgether_qa_portfolio.pdf) · [주요 QA 사례와 검증 결과](docs/qa/submission/github-guide.md)**

| 사례 | 검증 초점 |
|---|---|
| 도안 교체 시 드로잉 유실 | 사용자 기록을 기준으로 정상·취소 조건 정의 |
| 한 항목의 오류로 목록 전체 실패 | 화면·API·DB를 연결한 원인 분석 |
| 두 기기의 동시 수정 | 선행 저장과 미저장 입력 보존, 복구 경로 검증 |

앱 기획과 테스트 우선순위, 기대 결과를 정하고 수동·Postman·Charles·SQL로 확인했습니다. 구현과 후속 자동화에는 AI를 활용했습니다. 직접 맡은 일과 실행 조건은 [본문](docs/qa/submission/github-guide.md)에 정리했습니다.

## 테스트와 결과

2026-10-31 전용 환경과 원격 CI에서 서버 회귀 **180 PASS**, 실제 HTTP·PostgreSQL 동시성 **40 PASS**, API·네트워크·DB **79 PASS / 0 xfail**, **Swift 365 PASS·시뮬레이터 UI smoke 3 PASS**를 확인했습니다. 개별 조회의 알려진 500은 구분 가능한 409 응답으로 보완했고, 목록에서 제외된 오류 항목의 기기 캐시도 보존하도록 했습니다.

iPhone 16 Pro에서는 비로그인 상태의 종료·복귀 기록 보존과 카메라 권한 거부 후 안내·복귀, 고유 흐름 **2개를 최종 PASS**로 확인했습니다. 계정·서버 동기화는 로컬 네트워크 차단으로 미완료이며 원인은 미확정입니다.

계층별 수치는 겹칠 수 있어 전체 E2E 건수로 합산하지 않습니다. 과거 실패와 후속 통과, 실기기 조건과 미검증 범위는 실행 기록에 구분했습니다.

- [최신 조회 정책·캐시 보존·기기 검증](docs/qa/validation/2026-10-31/integrity-device/README.md)
- [앞선 iOS 화면 실패 분석·재검증](docs/qa/validation/2026-10-31/README.md)
- [QA 문서 목차](docs/qa/README.md): 기능 기준, 리스크·전략, 테스트·RTM, 결함 대장

## 코드와 실행

| 위치 | 내용 |
|---|---|
| [KnitGether/](KnitGether/) | SwiftUI 앱과 로컬 저장·동기화 |
| [server/](server/) | NestJS·Prisma·PostgreSQL API |
| [qa/appium/](qa/appium/README.md) | 화면 자동화 |
| [qa/api-tests/](qa/api-tests/README.md) | API·네트워크·SQL 검증 |
| [KnitGetherTests/](KnitGetherTests/) | 앱 내부 기능과 저장 상태 검증 |
| [KnitGetherUITests/](KnitGetherUITests/) | XCUITest 화면·실기기 검증 |
| [KnitGetherQAUITests/](KnitGetherQAUITests/) | 별도 QA 타깃의 결함 회귀 |
| [docs/qa/](docs/qa/README.md) | 포트폴리오, 테스트 설계와 실행 근거 |
| [output/pdf/](output/pdf/) | 본문과 같은 내용의 PDF |

[개발 환경](docs/dev/modes.md) · [기기 연결과 로컬 개발](docs/dev/09_local_device_development.md) · [과거 실행 원본](docs/qa/history.md)
