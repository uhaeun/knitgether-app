# QA-SYNC11-RACE 회귀 테스트안

작성일 2026-10-24. 기준 커밋 `75a9882`. **아래 신규 케이스는 모두 미구현·미실행(PLANNED / NOT_RUN)**이다. 기존 증거와 계획을 구분한다. 제품 수정은 [설계안](fix-design.md)을 따른다.

## 기존 자산 재사용과 검증 층

| 자산 | 재사용 | 보완 필요 |
|---|---|---|
| qa/api-tests/test_02_last_write_wins.py | 누락 기준400, 순차 stale409, 최신 재저장200 | 요청은 순차이므로 실제 겹침 검사 추가 |
| qa/api-tests/helpers.py | project_payload와 인증 API wrapper | patch_project는 기준을 자동 재조회하므로 stale 검사는 원시 patch 사용. 생성 시 RowCounter ID를 보존하고 A/B에서 deep copy |
| qa-runs/2026-10-22/probe_race.py | 시작 Barrier + 실제 API/SQL 방식 | 네트워크 시작 동기화만으로 서버 내부 읽기 겹침이 보장되지는 않음. 자식 판정·개별 연결·실패 원인 구분 강화 |
| server/test/projects.e2e-spec.ts | route 응답/검증·오류 매핑 | PrismaService와 $transaction을 mock으로 대체한다. DB 원자성·잠금·rollback의 증거로 사용하지 않음 |
| qa-runs/2026-10-22-ios-retest/run_sync.py, run_pure_ui.py | 동일 계정 두 기기·B 초안·A 저장·409·수동 복구 | 이전 커밋의 PASS 증거. 수정 빌드의 새 실행 폴더·세션·DB로 재실행 |

## P0 케이스와 오라클

| ID | Given / When | 기대 결과와 직접 SQL 오라클 |
|---|---|---|
| RACE-01 | 같은 버전을 읽은 유효한 전체 PATCH A/B를 서버 내부 읽기 후 동시에 진행 | 응답 multiset 정확히 [200,409], PROJECT_CONFLICT. 승자를 응답으로 결정하고 부모+자식이 그 승자의 payload와 일치. 승자 A 고정 금지 |
| RACE-02 | RACE-01에서 A/B의 memo·name·isFavorite·currentRow·행안내·세션·도안사본에 다른 marker 사용 | 패자의 marker/새 child ID가 DB에 하나도 없음. 행안내 삭제/교체, 자식 수, 기존 보존 대상까지 검사 |
| RACE-03 | 원본과 winner에 속하지 않은 기존 세션/프로젝트도 준비 | 관계없는 행은 전체 필드/updatedAt 포함 무변경. 같은 프로젝트의 요청에 없는 기존 세션도 기존 증분 upsert 계약대로 유지 |
| RACE-04 | 409의 최신본을 받은 패자가 명시적으로 재저장 | 최신 base 사용 시200, 새 버전 증가, 실제 최종 DB=수동 retry의 의도한 상태. API 재요청과 UI 직접 누름을 별도로 기록 |
| RACE-05 | 서버시계가 같은 ms인 연속 성공 두 건 및 그 사이의 stale 요청 | 성공마다 updatedAt strictly increases. 첫 기준을 다시 쓰면409. +1ms와 실제 DB TIMESTAMP(3) 직렬화 왕복 검사 |
| RACE-06 | 서버시계가 기존 버전보다 과거인 상태에서 정상 기준 저장 | 200 후 버전이 이전보다 큼. 서버시계 rollback이 stale 허용으로 이어지지 않음 |
| RACE-07 | 부모 CAS 이후 RowCounter/행안내를 쓴 다음 자식 저장 실패 | 요청 실패. 부모 모든 scalar/updatedAt·RowCounter·행안내·세션·도안사본이 실행 전 snapshot과 일치. 부분 commit 금지 |
| RACE-08 | CAS가 0건이 된 후 최신본 조회 | 동일 사용자 최신본을 포함한409. 삭제/소유자 불일치이면404, 타 사용자 정보 미노출. latest 변환 실패라도409 유지 |
| CONTRACT-01 | base 누락/null, 잘못된 ISO 날짜, 과거/미래 기준, 같은 시각의 다른 timezone 표기 | 누락400 BASE_UPDATED_AT_REQUIRED, 날짜400, 불일치409(미래 값은 제안 계약), 동일 epoch는 정상200. UTC Z 값을 원본 기준으로 사용 |
| CONTRACT-02 | route/body ID 불일치·없는 ID·타 사용자·행안내를 포함한 저장 RowCounter ID 불일치 | 기존400/404 계약 유지, 거부 요청의 부모/자식 무변경 |
| CONTRACT-03 | 기존 POST 신규 생성/중복·재전송, 기존 순차 충돌·자식 보존 케이스 | 현재 계약 회귀. POST 생성에 base 강제하지 않음. test_03·11·17·19의 관련 케이스 재사용 |
| IOS-01 | 수정 서버/앱 빌드로 A/B에서 같은 프로젝트. B 초안→A 메모 저장→B 저장 | 실제 B409, DB A 유지, B 초안·안내 유지, 안내 닫은 뒤에도 입력 유지 |
| IOS-02 | IOS-01 후 30초 관찰→B 직접 저장. 중간 A 추가 쓰기로 재충돌도 유도 | 자동 PATCH 없음(관찰 범위 명시), 직접 저장200 및 다른 필드 보존, 재충돌409/초안 유지/명시적 복구 |

행안내가 없는 RowCounter ID 불일치는 기존에 허용되는 호환 경로이므로 불필요한400을 만들지 않는 정상 대조도 둔다.

행안내는 요청 미포함/빈 배열의 의미가 다르므로 각각 보존/명시적 삭제를 대조한다. 도안사본도 undefined/null/object 의미를 구분한다. 패자 입력에만 있는 새 WorkSession/PatternCopy ID를 넣어 혼합 저장을 검출한다. 유효한 owner/reference를 사용해 권한 검증 오류를 동시성 실패로 오인하지 않는다.

## 결정적인 경합 재현 방법

### 1. 실제 PostgreSQL 통합 테스트

새 `server/test/projects-concurrency.real-db.e2e-spec.ts`를 제안한다. 실제 Nest route·Prisma·PostgreSQL을 연결하고 일반 mock 프로젝트 테스트와 분리해 opt-in 실행한다. 기본 CI mock 테스트가 개발자 DB에 연결되지 않도록 전용 환경변수와 테스트 DB명 allowlist를 먼저 검증한다.

테스트 전용 Prisma wrapper에서 **기존 프로젝트를 읽은 직후, CAS 전** 두 요청을 barrier에 모은다. target project와 처음 두 읽기에만 적용한다. 반환값과 모든 SQL은 실제 transaction client에 위임하고 데이터를 조작하거나 성공 응답을 가짜로 만들지 않는다. 제품 코드에 테스트 sleep/숨은 endpoint/barrier를 추가하지 않는다.

- 두 트랜잭션이 같은 버전을 실제 읽었음을 test event에 기록한 뒤 동시 release한다.
- pool은 API transaction 2개와 검증 연결을 수용하도록 구성한다(예: 최소4). READ COMMITTED를 확인한다.
- barrier 대기는 유한한 시간(예:3초), 테스트 transaction timeout은 더 길게(예:15초) 설정한다. 이 값은 테스트 한정이며 제품 timeout 변경안이 아니다.
- rendezvous 실패·연결 부족·timeout은 환경/하네스 실패로 기록하고 성공 케이스로 재분류하지 않는다. finally에서 대기 release, HTTP 완료 대기, 연결 종료를 보장한다.
- 기존 구현은 양쪽 읽기 후 where id UPDATE이므로 [200,200]을 재현해야 한다. 수정 전 red → 수정 후 green을 같은 케이스로 남긴다. 현재 아직 실행하지 않았다.

선택한 CAS 설계의 테스트 동기화 방식이다. SELECT FOR UPDATE 설계를 채택하면 ‘두 요청 모두 잠금 읽기 완료를 기다림’ barrier는 교착을 만들 수 있으므로 잠금 대기/해제 관찰 방식으로 바꾼다. 테스트가 특정 잠금 방식의 우연한 timing에 의존하지 않게 한다.

### 2. 외부 API + SQL 재현

수정 전후 동일한 시작 barrier probe를 서버 직접 연결과 기록 프록시 경유 각각 실행한다. 각 경로 새 프로젝트로 20쌍을 제안한다. 각 쌍에서 정확히1성공/1충돌, 패자 무변경이 필수다. 단 한 건의 [200,200], [409,409], 예상 밖 오류도 검토 대상이다. timeout을409로 치환하거나 성공할 때까지 반복해 실패를 감추지 않는다.

각 worker는 별도 requests.Session을 사용한다. 같은 세션 객체를 스레드 간 공유하지 않는다. payload는 생성 응답에서 얻은 RowCounter ID를 유지한 deep copy이며 base를 자동 갱신하지 않는다. HTTP 시작/끝 시각은 monotonic timing도 남기고 SQL snapshot은 두 HTTP 작업이 끝난 뒤 별도 연결로 읽는다.

이 반복은 운영 경로의 통합 신뢰도를 높이는 보완 검사다. 시작 barrier만으로 내부 읽기 겹침을 단정하거나 20회 통과를 수학적 증명으로 기록하지 않는다.

## 롤백 및 버전 경계 테스트 구현안

- 자식 identity/소유권 위반을 이용한 조기400만으로 rollback을 검증하지 않는다. `saveRowInstructions`는 deleteMany 뒤 중복 rowNumber 검사에서 예외를 던지므로, 유효한 참조를 가진 중복 번호 payload를 사용해 부모 CAS 및 RowCounter 변경 후의 실제 rollback을 검증할 수 있다. 실제 실행 trace에서 실패 지점을 확인한다.
- 추가로 테스트 전용 transaction wrapper에서 WorkSession/PatternCopy 저장의 특정 SQL을 수행한 **후** 예외를 발생시켜 늦은 실패도 검증한다. 이는 강제 실패 rollback 테스트이며 정상 사용자 입력 재현 결함으로 보고하지 않는다. 필요할 때만 사용하고 기존 child 실패 케이스가 커버하는 범위는 중복하지 않는다.
- 같은 ms/뒤로 간 시계는 버전 계산에 주입할 서버 clock seam 또는 계산 helper에 대한 좁은 spy를 제안한다. 전역 fake timer로 Prisma/network/event-loop를 멈추지 않는다. 최종 저장 시각과 409는 실제 DB에서 검증한다.
- rollback 비교는 대상 프로젝트뿐 아니라 관련 자식 목록 전체를 ID로 정렬해 비교한다. 조회 순서·시간대 표시 차이를 실제 변경으로 오인하지 않는다. timestamp는 API Z 표현과 SQL timezone 없는 표시를 혼합해 요청하지 않는다.

## P1 파일 저장 부수효과 관찰

FILES-01(PLANNED / NOT_RUN): 소유한 테스트 PDF를 가진 A/B payload로 충돌시켜 CAS 패자가 도안 파일 복사를 실행하지 않음을 전용 저장 경로 전후 목록과 trace로 확인한다. CAS 성공 뒤 늦은 실패에서는 DB 참조와 파일 목록을 별도로 관찰한다. 물리 파일은 DB rollback 대상이 아니므로 파일 고아화를 DB 원자성 통과로 감추지 않고, 기존 RC-08 범위의 별도 관찰로 보고한다. 이 문서에서 파일 고아화를 새로 재현했다고 기록하지 않는다. 파일 cleanup은 전용 경로에서 증거/덤프 보존 이후 실시한다.

## 환경·증거·결함 분류

이번 설계만으로 새 서버나 DB를 띄우지 않았다. 구현 후에는 신규 전용 DB·저장 경로·실행 폴더를 만든다. 기존 QA DB/덤프는 역사적 증거로 보존하고 db:reset-test를 사용하지 않는다. 테스트 계정은 가짜 이메일, 삭제는 해당 실행이 생성한 UUID에 한정하거나 전용 DB를 보존한 뒤 종료한다.

필수 산출물: 기준 커밋과 dirty diff, 서버/DB/Prisma 버전·격리 수준·pool 설정, A/B 원본 payload(비밀값 제외), HTTP status/body·타이밍, barrier 도달/release 이벤트, winner 판별, 부모/자식 SQL 전후 snapshot, 반복별 PASS/FAIL, 수정 후 iOS UDID·설치 UUID·스크린샷/XML, 테스트 DB 덤프·해시.

| 관찰 | 분류 |
|---|---|
| 유효한 같은 기준에서 두200, 패자 자식 흔적, 부모/자식 혼합 | 제품 결함 |
| 정상 기준 저장도 모두409, 미래 버전 생성, rollback 부분 잔존 | 제품 결함 |
| 공유 payload/ID 오류, base 자동 재조회, wrapper가 실제 SQL 대신 가짜 결과 반환 | 테스트 코드 문제 |
| pool 고갈, barrier 미도달, WDA 미연결, DB 기동 실패 | 환경/하네스 문제; 기능 PASS 금지 |

## 실행·판정 순서와 문서 반영

1. 현재 commit에서 RACE-01/02 red 증거를 보존한다.
2. 서버 최소 수정 후 실제 DB P0 검사와 기존 API/route 계약 회귀를 실행한다. route mock 통과만으로 원자성 승인 금지.
3. 직접 API/프록시 반복을 실행하고 실제 부모·자식 상태를 대조한다.
4. 수정 빌드의 두 iOS 시뮬레이터 IOS-01/02를 실행한다. 이번 수정에 UI 코드 변경이 없다면 UI-03 전체 반복은 필수로 추가하지 않고 기존 cm 정책 증거를 회귀 범위 판단 근거로 남긴다.
5. 새 실행 보고서에서 이전 19/20 재현 FAIL과 수정 후 결과를 분리한다. 기존 이력을 덮어쓰지 않는다.
6. RACE-01~08을 SYNC-11 원자적 보호 하위 TC에, IOS-01/02를 사용자 복구 하위 TC에 매핑한다. 미래 기준 거절·논리 updatedAt 설명은 SPEC 개정 제안으로 제출한다.

완료 판정은 모든 필수 항목의 실제 실행 증거가 있어야 한다. 미실행·환경 차단은 그대로 남긴다. 이 문서는 테스트안이므로 PASS를 부여하지 않는다. 사용자 판단은 기존 수용 기준·우선순위이며, CAS 선택·추가 경계 케이스·반복 횟수·완료 기준의 세부 설계는 Codex 제안이다.
