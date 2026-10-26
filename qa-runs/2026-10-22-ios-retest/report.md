# KnitGether 두 iOS 시뮬레이터 QA 최종 보고서

보고일 2026-10-24 (KST). SYNC-11 화면 실행은 10월 22~23일, UI-03 완료 실행은 10월 24일이다. 원본 로그 시각은 UTC이며 KST는 +9시간이다.

**순차 충돌·입력 보존·수동 복구: PASS. UI-03: A PASS, B PASS. 기존 서버 동시 요청 결함: 별도 FAIL 유지. 따라서 SYNC-11 전체를 무조건 PASS로 승인하지 않는다.**

기준 커밋 `75a9882eb841044aba1067ddbc703a985a4515d2`. 제품 코드·기존 자동화·SPEC 원문은 수정하지 않았다. 이 폴더의 QA 실행 코드와 보고서만 작성·보완했다. 이전 [최초 보고서](../2026-10-22/report.md)의 미실행 이력은 유지하고 이번 실행으로 후속 상태를 보완한다.

## 실행 환경과 증거 식별

| 대상 | 실제 실행 환경 |
|---|---|
| A | iPhone 17 Pro / iOS 26.5 / `840CB58F-9AD8-4403-A8C3-3E2D5F93B0C5` |
| B | iPhone 17 Pro / iOS 26.5 / `311D4B83-D09B-4237-824C-ABCDD09264D1` |
| 도구 | macOS 26.5.1 / Xcode 26.6 (17F113) / Appium 3.1.2 / xcuitest 12.3.4 |
| 서버·DB | Nest 3301, 기록 프록시 3300, PostgreSQL 55432 / `knitgether_qa_ios_20261022` |
| 동일 테스트 사용자 | `de7cdb19-ec23-4682-8ce8-0b83b8b56138` |
| 동일 프로젝트 | `04ad05ac-0236-4450-bfce-a4a6d2b0ddbd` |
| 앱 식별 | A/B debug dylib UUID는 installed-app-0/1.txt. 임시 빌드 소스 248개가 기준 커밋과 일치: source-integrity.json |

두 기기의 [로그인 A](evidence/native-A-authenticated.png) / [로그인 B](evidence/native-B-authenticated.png), [같은 프로젝트 A](evidence/sync-01-a-baseline.png) / [B](evidence/sync-01-b-baseline.png)를 확보했다. [환경 복구 기록](ENVIRONMENT.md), 빌드 로그·WDA 상태·시뮬레이터 목록도 evidence에 보존했다. Simulator 실행은 물리 iPhone 실기기 검증과 구분한다.

## 테스트케이스별 최종 판정

| TC | 실제 확인 | 판정 | 주요 증거 |
|---|---|---|---|
| TC-SYNC11-01.a | A/B 동일 계정·서버·프로젝트 조회 | PASS | native-*-authenticated, sync-01-*-baseline PNG/XML, HTTP 사용자/프로젝트 ID |
| TC-SYNC11-01.b | B 초안 미저장, A 먼저 저장, B 저장 409 | PASS | sync-02/03/04, sync-results, HTTP |
| TC-SYNC11-01.c | 409 후 DB A 메모 보존 | PASS | sync-04-after-conflict-db.json |
| TC-SYNC11-02.a | B 입력 유지·충돌 안내·안내 닫은 뒤 입력 유지 | PASS | sync-04-b-conflict / input-after-dismiss PNG/XML |
| TC-SYNC11-02.b | 충돌 후 자동 재저장 없음 | PASS (30초 관찰) | PATCH 3건→3건, sync-results 및 이벤트·HTTP 시각 |
| TC-SYNC11-03.a | B가 저장 버튼을 직접 다시 눌러 성공 | PASS | sync-05-final-db.json, native PATCH 200 |
| TC-SYNC11-03.b | 재저장 시 다른 필드 보존 | PASS (검사한 필드) | 이름·즐겨찾기·단수7 유지, pure-07-final-db.json |
| TC-SYNC11-04 | 중간 쓰기 후 재충돌, 초안 유지, 수동 복구 | PASS | sync-06~08 + pure-04~07, 409→409→200 |
| TC-SYNC11-05 | 같은 기준의 실제 겹친 서버 저장 | FAIL (기존 결함) | 아래 별도 결함 절·최초 실행 19/20회 재현 |
| TC-UNIT-01 | 온보딩 5단계 단위 선택 부재 | A PASS / B PASS | A/B-ui03-onboarding-0~4 PNG/XML |
| TC-UNIT-02 | 회원가입 단위 선택 부재 | A PASS / B PASS | A/B-ui03-03-signup PNG/XML |
| TC-UNIT-03 | 프로필 단위 선택 부재 | A PASS / B PASS | A/B-ui03-02-profile PNG/XML |
| TC-UNIT-04 | 설정에 잘못된 단위 안내 없음 | A PASS / B PASS | A/B-ui03-01-settings PNG/XML |
| TC-UNIT-05 | cm 입력·게이지 산술 결과 | A PASS / B PASS | A/B-ui03-gauge-* PNG/XML 및 실제 입력값 |
| TC-UNIT-06 | 과거 preferredUnits 4종 무영향 | A PASS / B PASS | DB UPDATE 반환값, 단위별 앱 GET /profile, 게이지 화면 |

최종 실행의 세부 assertion은 SYNC 기본 12개, UI만 쓰는 보완 흐름 7개, UI-03 A/B 각 12개다. **총 43개 assertion을 서로 다른 43개 독립 요구사항으로 과장하지 않는다.** [개별 시각·PASS/FAIL](case-results.md), [기계 판독 결과](evidence/final-case-results.json). 초기 하네스 실패를 삭제하거나 최종 통과 건수에 중복 합산하지 않았다.

## SYNC-11 요청·DB 결과와 화면 증거

A/B의 최초 `baseUpdatedAt`는 모두 `2026-10-22T14:45:16.316Z`였다. B의 초안은 서버에 반영되지 않았으며, A가 UI 저장한 `A first saved memo 20261022`가 DB에 들어간 뒤 B의 UI 저장은 409가 됐다. 팝업에는 입력 보존과 직접 재저장 안내가 표시됐고 초안 `B unsaved memo 20261022`가 유지됐다. [충돌 화면](evidence/sync-04-b-conflict.png), [안내 닫은 후](evidence/sync-04-b-input-after-dismiss.png).

기본 흐름의 이름·즐겨찾기·단수 변경과 추가 중간 쓰기는 **API 확장 검사**로 실행했다. 이 부분을 모두 A 기기의 UI 수정이라고 기록하지 않는다. B의 실제 UI 재저장 뒤 SQL 값은 `memo=B unsaved memo 20261022`, `name=SYNC11 preserved name`, `isFavorite=true`, `currentRow=7`이었다. [DB](evidence/sync-05-final-db.json).

이를 보완해 `run_pure_ui.py`에서는 API 변경 요청 없이 A/B의 화면만 조작했다. A의 이름 저장 200 → B 409 → A의 메모 저장 200 → B 재충돌 409 → B 직접 재저장 200을 확인했다. [최종 SQL 재확인](evidence/final-db-state.json)에서 단수7과 프로필 preferredUnits=cm도 확인했다. 보완 흐름의 최종 SQL은 `memo=B pure UI verified draft`, `name=SYNC11 A UI final verified`, `isFavorite=false`다. 즐겨찾기 false는 앞선 A UI 조작으로 바뀐 값이며, 최종 보완 흐름의 시작 시점에도 이미 false였다. 최종 흐름에서 새로 false로 전환했다고 과장하지 않는다. [A 변경](evidence/pure-03-A-fields-saved.png), [재충돌](evidence/pure-06-B-reconflict.png), [B 복구](evidence/pure-07-B-recovered.png), [최종 DB](evidence/pure-07-final-db.json).

요청/응답은 [성공 완료 흐름 선별본](evidence/sync-successful-flows-http.json)과 전체 [http.jsonl](evidence/http.jsonl)을 대조한다. 선별본은 성공한 실행 구간의 409 실패 응답도 포함한다. phase actor는 테스트 실행기가 붙인 단계 주석이며 네트워크 자체의 기기 인증 정보는 아니다. 세션·UDID·UI 조작 로그와 사용자/프로젝트 ID를 함께 연결했다. UI-03은 호스트 부담을 줄이기 위해 A 완료 후 B를 실행했으며, SYNC-11 두 기기 편집은 양쪽을 함께 실행했다. 자동 재저장 검증은 관찰한 30초 범위이며 모든 백그라운드 조건을 승인한 것은 아니다.

## UI-03 양 기기 결과

A/B 각각 과거 값 `Metric`, `Imperial`, `US`, `cm`를 전용 프로필에 SQL로 주입했다. 매번 앱을 재시작하고 실제 프로필 조회 응답의 값을 확인한 뒤 게이지에 6개 값을 직접 입력했다. DB 변경은 레거시 데이터 준비이고 계산은 iOS 화면에서 실행했다. API 테스트를 계산 E2E로 대체하지 않았다.

입력은 샘플 가로8cm·세로10cm·20코·30단, 목표40×55cm다. 기대 계산은 `20÷8×10=25코`, `30÷10×10=30단`, `20÷8×40=100코`, `30÷10×55=165단`이다. 단위별 actualInputValues와 실제 화면 출력은 [A 결과](evidence/ui03-results-A.json), [B 결과](evidence/ui03-results-B.json)에 있다. DB 준비값과 실제 프로필 GET을 연결한 [단위별 증명](evidence/ui03-profile-db-http-proof.json)도 보존했다. [A Metric](evidence/A-ui03-gauge-Metric.png), [A Imperial](evidence/A-ui03-gauge-Imperial.png), [B Metric](evidence/B-ui03-gauge-Metric.png), [B Imperial](evidence/B-ui03-gauge-Imperial.png). US/cm 화면도 같은 명명으로 보존했다.

온보딩은 정상 5단계의 양성 문구와 현재 단계 식별자를 확인하고 단위 UI가 없음을 대조했다. 회원가입은 실제 이름 입력란이 존재하는 화면, 프로필은 실제 이름 편집 화면, 설정은 실제 메뉴를 확인했다. 빈 화면의 문자열 부재만으로 통과시키지 않았다. [A 가입](evidence/A-ui03-03-signup.png) / [B 가입](evidence/B-ui03-03-signup.png), [A 온보딩](evidence/A-ui03-onboarding-2.png) / [B 온보딩](evidence/B-ui03-onboarding-2.png), [A 설정](evidence/A-ui03-01-settings.png) / [B 설정](evidence/B-ui03-01-settings.png).

## 기존 동시 요청 결함 — 별도 FAIL

**QA-SYNC11-RACE**는 이전 동일 커밋의 격리 서버/API+SQL 실험에서 같은 기준의 겹친 두 PATCH가 모두 200이 되는 현상이다. 프록시 경유10/10, 서버 직접9/10으로 총19/20회 재현했다. 양쪽 모두 성공 응답을 받지만 최종 DB에는 한 메모만 남는다. 이번 UI 재검증에서 이 동시 요청 실험을 재실행했다고 주장하지 않는다.

원인은 기존 버전 읽기·비교와 `where: {id}` 갱신이 원자적 조건으로 묶이지 않은 서버 경합으로 분석했다. 조건부 UPDATE나 행 잠금 후 비교와 자식 변경 롤백 회귀 검사를 제안한다. [결함 상세](../2026-10-22/DEF-SYNC11-RACE.md), [프록시 경유 결과](../2026-10-22/evidence/api-concurrency.json), [직접 연결](../2026-10-22/evidence/api-concurrency-direct.json). UI 순차 충돌 통과로 이 결함을 종료하지 않는다. 신규 이슈 생성·재개·제품 수정은 하지 않았다.

이번 최종 완료 흐름에서는 추가 제품 결함을 확인하지 않았다. 복구 중 실패는 WDA·호스트 부하·키보드/좌표/초안 준비 오류로 구분했다. 수정한 것은 QA 하네스이며 근거와 실패 원본은 [환경 기록](ENVIRONMENT.md), `recovery-attempts`에 남겼다. 키보드 툴바에 완료 버튼이 여러 개 표시되는 관찰은 별도 UX 점검 후보이며 cm 정책/계산 실패로 판정하지 않는다.

## 보존·추적과 제한

원래 DB·계정·프로젝트·시뮬레이터는 초기화하지 않았다. 이 실행 전용 DB와 프로필만 조작했다. [전용 DB 덤프](evidence/isolated-ios-db.dump)는 로컬 보존 자료이며 세션 식별자·Appium 원본 로그와 함께 Git 제외 대상이다. HTTP의 인증 헤더를 수집하지 않았고 토큰/비밀번호는 마스킹했다. 스크린샷·UI XML·SQL JSON·요청 응답·실행 시각 및 [해시 목록](evidence/SHA256SUMS.txt)으로 증거를 연결한다. [최종 무결성 점검](evidence/final-integrity.json)에서 증거 링크와 기준 커밋·tracked diff 부재를 확인했다.

범위 밖은 물리 기기·다른 OS·앱 종료 후 초안 수명·오프라인·장시간 자동 저장·게이지 전체 경계값이다. 확인한 메모/필드를 모든 편집 화면으로 확대하지 않는다. 기존 API 회귀18 PASS는 최초 실행 결과이며 이번 재실행 건수에 포함하지 않는다.

## SPEC·RTM 제안과 역할 구분

[개정 제안](SPEC-RTM-proposal.md)은 순차 충돌 보호와 원자적 동시 보호를 분리하고 TC-UNIT-01~06을 실제 A/B 증거에 연결한다. SPEC 원문은 승인 없이 덮어쓰지 않았다.

| 주체 | 실제 역할 |
|---|---|
| 사용자 직접 판단 | SYNC-11 최우선, 선행 서버값·초안 보존, 직접 재저장, 다른 필드 보호, cm 고정·과거 단위 무영향, E2E와 API 구분, 데이터 보존, 제품 수정 금지를 수용 기준으로 지정 |
| Codex 실행·구현 | 기존 QA/코드 분석, 격리 환경·WDA/서명/빌드 복구, 기존 페이지 객체 재사용, 추가 QA 스크립트 구현·수정·실행, 시뮬레이터 조작·HTTP/DB/스크린샷 수집, 결과 판정과 명세/수정안 제안 |
| 사용자 승인으로 남는 것 | 제품 수정·결함 우선순위 확정·릴리즈·SPEC 원문 반영. 사용자 본인이 수동 테스트를 수행했다고 기록하지 않음 |

## 포트폴리오용 요약

> 나는 동시 수정에서 선행 데이터와 미저장 입력을 보존해야 한다는 기준, 수동 재저장 및 cm 고정 정책의 수용 기준과 검증 우선순위를 정했다. Codex는 자동화 환경을 복구하고 동일 계정의 독립 iOS 시뮬레이터 두 대에서 충돌·입력 유지·재충돌·직접 복구를 실제 실행했다. UI-03은 양 기기의 온보딩·가입·프로필·설정과 과거 단위4종의 cm 계산을 화면·요청·DB로 검증했다. 순차 흐름과 단위 정책의 통과 결과를 기존 서버 동시 요청 경합 결함의 FAIL과 분리했고, 요구사항 판단과 Codex의 실행·구현을 구분해 기록했다.
