# 뜨개더 최종 QA 및 병합 검증

로컬 검증 완료: 실제DB40·서버147·API75·Swift359 및 최종 앱 UI-03 24개 모두 PASS. 이 파일은 제품 c4e9282/테스트38b903c의 실행 기록이다. 원격 CI와 실제 병합 이벤트는 [PR48](https://github.com/uhaeun/knitgether-app/pull/48)의 최종 head·Checks·merge commit으로 추적하고, 병합 후 로컬 결과는 최종 전달 묶음 RESULTS.md에 정확한 SHA와 함께 기록한다.

## 사용자 판단과 Codex 수행

사용자는 SYNC-11 충돌 시 서버 기존값·미저장 입력 보존과 직접 재저장, UI-03 cm 고정을 수용 기준으로 정했다. 초안은 계정·프로젝트별 기기에 보존하고 저장 성공·명시적 삭제 시 제거하는 정책을 직접 선택했다. 이번에는 UI-03 최종 재검증, 남은 자식 API 점검·수정, PR 리뷰·병합을 모두 진행하도록 지시했고 배포 범위를 **main 병합과 로컬 검증까지**로 확정했다.

Codex는 코드/기존 TC 분석, 재현·수정, 격리 환경 구성, 실제 실행, 증거 수집과 PASS/FAIL 판정, SPEC/RTM 보완 및 코드 리뷰·병합 실행을 담당한다. 사용자가 직접 테스트·코드 리뷰·운영 릴리즈 승인을 했다고 표현하지 않는다. 운영 서버·TestFlight 배포는 이번 범위에 없다.

## 기준과 환경

- 시작 head626baf6, 최신 main6df5c4e. 제품 변경 c4e9282, 계정 격리 테스트38b903c. 문서 커밋은 제품 소스를 바꾸지 않으며 최종 문서/병합 SHA는 PR48과 전달 결과에서 확인한다.
- macOS26.5.1, Xcode26.6(17F113), iOS26.5. 독립 QA A840CB58F-9AD8-4403-A8C3-3E2D5F93B0C5 / B311D4B83-D09B-4237-824C-ABCDD09264D1. 실제 설치 앱 UUID는 installed-app-0/1.txt를 따른다.
- PostgreSQL14의 전용 로컬 클러스터, 127.0.0.1:55439, 새 DB knitgether_qa_sync11_completion_20261026. 이전 QA DB·사용자 데이터는 reset/drop하지 않았다. synthetic 계정만 사용한다.
- API3301, 마스킹 기록 프록시3300. API 독립 회귀는3301에 직접 연결한다. 중간 검증용3302 서버와 최종 서버의 실행 로그를 구분한다.
- Appium3.1.2/xcuitest12.3.4. Python3.14 전용 venv는 /tmp/knitgether-completion-python. 문서 폴더의 모듈 mmap 지연을 피해 임시 경로를 사용했다. Git object 접근 지연으로 원격 저장소를 별도 /tmp 체크아웃에 복제해 커밋/리뷰했으며 build source 해시 대조를 남겼다.

## 실행 결과

| 층 | 결과 | 근거 |
|---|---|---|
| 수정 전 추가 충돌 재현 | 6 FAIL / 기존24 PASS | child-red.log/json. 행 안내3 + 도안3에서 오래된 전체 PATCH200 |
| 수정 전 자식 ID 재사용 | 3 FAIL | scope-red.log/json. 서로 다른 프로젝트 데이터 변경 |
| 수정 후 실제 HTTP + PostgreSQL | 40 PASS, SKIP0 | child-verified.log, child-jest-results.json, child-verified.json |
| 서버 경로/파일 회귀 | 147 PASS | server-final.log |
| 별도 API/네트워크/DB 회귀 | 75 PASS | api-verified.log |
| Swift | 359 PASS / 41 suites | swift-results.log, 로컬 xcresult |
| 최종 앱 UI-03 | A12 + B12 =24 PASS | ui03-results-A/B.json, PNG/XML, completion-audit.json |
| 원격 CI / main | PR48 최종 head의4 jobs 통과 후 병합 | PR48 Checks·merge event 및 최종 전달 RESULTS.md |

실제DB TC별 결과는 evidence/child-case-results.json에 기록했다. HTTP 요청·409 응답·SQL 전후 값은 child-verified.json에 있다. 기존24개와 신규16개의 최종40을 합산하며 중간30/33/34/37회 실행 횟수를 더하지 않는다. 단위/API 통과를 E2E로 표현하지 않는다.

## 발견과 조치

코드 리뷰와 근거는 [code-review.md](code-review.md)를 따른다. 행 안내와 도안 전용 API에도 부모 버전 잠금을 적용했다. 드로잉은 불변 UUID 파일과 커밋/롤백 보상 정리로 이전 바이트를 보존한다. 자식 ID의 owner/project 범위를 검사한다. 클라이언트는 온라인 드로잉 저장 뒤 중복 전체 저장을 생략하고 메모 저장 시 동기화된 캐시 파일을 다시 업로드하지 않는다. 로컬·오프라인 새 드로잉과 삭제는 필요한 업로드/DELETE를 유지한다.

기존 SYNC-11 두 시뮬레이터12개 혼합 UI/API, 화면 전용7개, 초안 종료 복구3개, 목록 삭제1개 및 오프라인2개는 session-fix/draft-delete-fix 보고서의 각 당시 SHA 근거다. 이번 최종 앱에서 그 전체를 재실행한 것으로 바꾸지 않는다. 자동 재저장300초 없음의 이전 증거도 그대로 보존한다.

## 실행 중 문제 구분

- iOS 암호 저장 팝업이 B의 계정 화면 이동을 막은 것은 자동화 환경 문제다. 스크린샷 setup-B-failure와 조치 기록을 남기고 팝업을 닫았다.
- 서버 목 테스트2개는 부모 잠금 뒤 추가 조회/조건을 반영하도록 보완했다. 일시적 socket hang up1건은 별도 로그를 보존하고 전체 재실행147 PASS로 확인했다.
- Swift 병렬 실행의 QA 시뮬레이터 컨테이너 지연은 환경 문제로 중단·격리 장치 서비스 복구 후 병렬 실행을 끄고 전체359 PASS를 확인했다. 개인 장치나 데이터 초기화는 하지 않았다.
- pre-final-ui03는 이전626 앱 일부 실행 기록이며 최종 앱의 TC 수에 합산하지 않는다.

## SPEC / RTM 보완

SYNC-11에는 전체 저장과 겹치는 카운터·행 안내·작업 세션·도안 파일/드로잉의 성공이 부모 버전을 진전시킨다는 불변 조건, 검증 실패 시 버전 롤백, 수동 재시도 전까지 자동 PATCH 없음, 다른 owner/project의 ID 재사용 거부를 명시한다. 파일 성공·실패는 SQL뿐 아니라 이전/새 파일 바이트와 참조로 추적한다. UI-03에는 legacy Metric/Imperial/US/cm를 실제 DB에 주입해도 8×10cm/20코30단/목표40×55cm에서25코·30단·100코·165단이 동일한 기준을 연결한다.

포트폴리오에서는 사용자 요구·정책 결정, Codex 실행/구현/판정을 구분하고 재현 FAIL→수정→층별 PASS와 미실행 범위를 함께 보여 준다. 전체 앱 동시성·실물 iPhone·장기 SLA·운영 배포까지 완료했다고 확대하지 않는다.

## 증거 보존

공개 목록은 완료 시 manifest로 고정한다. 마스킹 HTTP, SQL snapshot, TC JSON, 화면 PNG/XML, 정제한 실행 로그, 소스 해시를 포함한다. 토큰/비밀번호, Appium 세션, 원본 Appium/서버 로그, DB dump/빌드/xcresult는 Git과 공유 ZIP에서 제외한다. 실제DB suite의 임시 파일 저장소는 fixture 종료 시 정리하며 각 검사 당시 파일 검증 결과는 JSON에 남는다. 전용 QA DB 자체는 보존한다.

UI-03의 두 기기별12개는 설정·프로필2 + legacy4 + 회원가입1 + 온보딩5다. 계정의 preferredUnits를 SQL로 주입한 뒤 네이티브 GET/profile 응답이 같은 값인지 확인했고8개 계산 화면 모두25코/30단/100코/165단이 viewport 안에 표시됨을 XML 좌표와 PNG로 확인했다. completion-audit의81개 대조는 추가 TC81개를 뜻하지 않는다. pre-final-ui03 일부 기록과 반복 회귀 실행은24개에 합산하지 않았다.
