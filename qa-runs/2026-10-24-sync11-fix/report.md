# SYNC-11 서버 수정 및 재검증 결과

2026-10-24 KST. **1 서버 구현 → 2 실제 DB/API 회귀 → 3 두 iOS 시뮬레이터 → 4 문서 갱신 순서로 완료했다. 검증한 전체 프로젝트 PATCH 경합과 메모 충돌 복구는 PASS다.**

`QA-SYNC11-RACE`는 **로컬 수정·검증 완료(FIXED / VERIFIED locally)**로 판정한다. 과거 커밋의 FAIL 증거는 유지한다. GitHub 이슈 종료·커밋·push·배포·릴리즈 승인은 하지 않았다. 자식 전용 API와 파일 고아화까지 해결한 것으로 확대하지 않는다.

## 기준과 구현

서버는 기준 커밋 `75a9882eb841044aba1067ddbc703a985a4515d2`에 현재 작업 트리 패치를 적용했다. [서버 변경](evidence/server-change.patch), [소스·컴파일 산출물 SHA256](evidence/server-source-identity.json). 새 회귀 테스트/설정도 파일별 해시에 포함한다. 제품 코드 수정 금지 조건은 사용자의 이번 ‘1→2→3→4 진행’ 지시로 서버 수정 범위에서 해제됐다.

- [ProjectsService](../../server/src/projects/projects.service.ts): ownerId·deletedAt·updatedAt을 WHERE에 포함한 updateMany CAS. count=1일 때만 동일 트랜잭션의 자식 저장을 진행한다. 실패는 최신본409 또는 삭제/비공개404다.
- 서버 기준 버전은 밀리초 epoch가 정확히 같아야 한다. 과거뿐 아니라 미래 불일치도409로 거절한다. 누락400·POST 신규 생성의 기준값 불필요 계약을 유지한다.
- 성공 updatedAt은 `max(Date.now(), previous+1ms)`로 증가한다. 동일 ms·뒤로 간 서버 시각에도 버전이 재사용되지 않는다. READ COMMITTED를 해당 트랜잭션에 명시했다. 논리 시각이 벽시계보다 앞설 수 있으며 정수 revision은 별도 후속 설계다.
- [새 실제 DB 테스트](../../server/test/projects-concurrency.real-db-spec.ts), [별도 설정](../../server/test/jest-real-db.json), npm `test:db:projects`를 추가했다. 개발 DB로 fallback하지 않고 명시적 로컬 QA DB URL만 허용한다.

## 단계 2 — 서버·DB·API 결과

| 실행 | 결과 | 증거·해석 |
|---|---|---|
| 서버 빌드 | PASS | [build.log](evidence/build.log) |
| 기존 서버 route 회귀 | 12 suites / 147 PASS | [로그](evidence/server-regression.log). 프로젝트49개를 포함한 수치이며 49를 다시 더하지 않는다. 기존 suite는 주로 Prisma mock 기반이다. |
| 수정 전 기준 커밋의 결정적 경합 대조 | 예상대로 FAIL / 결함 재현 | [로그](evidence/baseline-red-tests.log), [응답·DB](evidence/baseline-red-results.json). 같은 회귀 검사에서 [200,200] 검출. 나머지7개는 이름 필터로 미실행. 수정본을 원복하지 않고 /tmp의 git archive 기준 소스로 실행했다. |
| 수정본 실제 PostgreSQL+HTTP | 8/8 PASS | [로그](evidence/real-db-tests.log), [단계·요청·응답·DB](evidence/real-db-results.json). SQL 결과를 가짜로 반환하지 않는다. |
| 외부 API 서버 직접 경합 | 20/20쌍 PASS | [원본](evidence/api-concurrency-direct.json), [요약](evidence/api-concurrency-direct.log). 전부 정확히200 한 건/409 한 건 및 승자 부모·자식 일치. |
| 기록 프록시 경유 경합 | 20/20쌍 PASS | [원본](evidence/api-concurrency-proxy.json), [요약](evidence/api-concurrency-proxy.log). 직접 연결 대조와 구분한다. |
| 기존 API 회귀 | 18/18 PASS | test_02·03·11·17·19 재사용. [로그](evidence/api-existing.log), [JUnit](evidence/api-existing.xml). iOS 결과로 대체하지 않는다. |

### 실제 DB 8개 케이스

| 케이스 | 실행·판정 |
|---|---|
| 같은 버전 읽기 후 경합·자식 일관성·명시적 재저장 | PASS. 5쌍 모두 같은 baseline 읽기를 barrier에서 확인한 뒤 release, 매번1성공/1충돌. 승자에 따라 memo/name/favorite/단수·행안내·세션·도안사본을 직접 조회하고 패자 흔적이 없음을 확인. 요청에 없는 기존 세션도 보존. 패자는 최신 버전으로 명시적 재요청200. |
| 행안내 교체 중 실패 rollback | PASS. 기존 행안내를 미리 저장하고, 부모/카운터 갱신 및 deleteMany 뒤 중복 번호400을 확인. 부모 버전과 삭제된 기존 행안내까지 정확히 복구. 관계없는 프로젝트도 무변경. |
| 늦은 자식 SQL 후 강제 실패 rollback | PASS. 실제 PatternCopy upsert 이후의 실패 주입 이벤트를 단언한 뒤500과 부모·모든 자식의 이전 snapshot 복구를 확인. 정상 사용자 입력의 제품500 결함으로 집계하지 않음. |
| 동일 ms·시각 역전 대응 및 미래 기준 거절 | PASS. DB 버전을 서버 시각보다 앞에 두어 연속 성공이 각각+1ms임을 확인. 이전 기준/임의 미래 기준409, 같은 시각의 다른 ISO 표기200. |
| 읽기와 CAS 사이 다른 쓰기 | PASS. 실제 외부 DB 쓰기를 끼워 넣은 뒤 CAS 0건→최신409/latest, 자식 무변경. |
| 읽기와 CAS 사이 삭제 | PASS. 기존404 계약 유지. |
| 최신본 자식 결손 | PASS. 최신 RowCounter가 없더라도409 유지, latest=null. |
| 검증·권한·카운터 호환 | PASS. 누락/null/잘못된 날짜400, ID/소유자404, 행안내가 있는 카운터 ID 불일치400. 행안내가 없는 기존 호환 경로는200 및 저장된 카운터 ID 유지. |

결정적 검사에서는 테스트 전용 transaction wrapper가 실제 첫 읽기 이후의 진행 시점만 제어한다. 두 결과는 같은 버전을 읽고, mutation과 rollback은 실제 PostgreSQL에서 수행한다. 실제 데이터나 HTTP 성공을 mock하지 않는다. 외부 시작 barrier만으로 내부 읽기 겹침을 단정하지 않고 이 결정적 대조와 함께 해석한다. 외부40쌍과 내부5쌍을 독립된45개 요구사항으로 합산하지 않는다.

## 단계 3 — 두 시뮬레이터 실제 실행

| 구분 | 실행 식별 |
|---|---|
| A | iPhone17 Pro / iOS26.5 / `840CB58F-9AD8-4403-A8C3-3E2D5F93B0C5` |
| B | iPhone17 Pro / iOS26.5 / `311D4B83-D09B-4237-824C-ABCDD09264D1` |
| 동일 사용자 | `7816841c-dc5e-47ac-b6f6-f456eba3e08d` |
| 동일 프로젝트 | `e532dcf6-5338-4bef-a029-d8039a7962b5` |
| 앱 | iOS 제품 코드는 미변경. 기준 커밋의 정상 서명 Debug 앱을 재사용. A/B dylib UUID와 UDID는 installed-app-0/1.txt. 서버는 위 작업 트리 수정본. |
| 제어 환경 | macOS26.5.1 / Xcode26.6 (17F113) / Appium3.1.2 / xcuitest12.3.4. WDA18101/18102 별도 세션. |

| 확인 | 결과 | 주요 증거 |
|---|---|---|
| 동일 계정 로그인·같은 프로젝트 | PASS | [A 계정](evidence/native-A-authenticated.png) / [B 계정](evidence/native-B-authenticated.png), sync-01-a/b-baseline PNG/XML |
| B 미저장 입력 후 A 먼저 저장 | PASS | sync-02-b-unsaved, sync-03-a-saved-db.json |
| B 저장409·서버 A 메모 유지 | PASS | [실제 팝업](evidence/sync-04-b-conflict.png), [DB](evidence/sync-04-after-conflict-db.json) |
| 안내 닫은 후 B 초안 유지 | PASS | [화면](evidence/sync-04-b-input-after-dismiss.png), sync-results.json |
| 자동 재저장 없음 | PASS (30초 범위) | 대상 프로젝트 PATCH 수3→3. 다른 read 요청을 재저장으로 취급하지 않음. |
| B 직접 저장200·다른 필드 보존 | PASS | [DB](evidence/sync-05-final-db.json): memo=B unsaved memo 20261024, name=SYNC11 preserved name, favorite=true, currentRow=7 |
| 중간 추가 쓰기 이후 재충돌·직접 복구 | PASS | sync-06~08 DB, sync-07 PNG, 409/200 HTTP |
| A/B 화면만으로 수정·재충돌·복구 | 7항목 PASS | [A 폼 저장](evidence/pure-03-A-fields-saved.png), [B 재충돌](evidence/pure-06-B-reconflict.png), [B 복구](evidence/pure-07-B-recovered.png), pure-ui-results.json |

기본 흐름 12항목과 화면 전용 보완7항목이 모두 PASS다. [개별 시각·판정·상세](case-results.md), [전체 JSON](evidence/ios-case-results.json), [대상 프로젝트 HTTP](evidence/ios-project-http.json).

기본 흐름의 다른 필드 변경/중간 쓰기는 API 확장 검사다. 이를 A의 UI 조작이라고 기록하지 않는다. 별도의 run_pure_ui.py는 변경 API를 직접 호출하지 않고 A/B 화면만으로 이름·즐겨찾기 변경, 메모 추가 저장, B의 두409와 최종 수동200을 확인했다.

[최종 SQL](evidence/final-ios-db.json)은 `memo=B pure UI verified draft`, `name=SYNC11 A UI final verified`, `isFavorite=false`, `currentRow=7`이다. 테스트 실행기의 phase actor는 단계 주석이며 네트워크 자체의 기기 인증값이 아니다. 세션/UDID·실제 UI 로그·계정/프로젝트 ID와 함께 대조한다. 물리 iPhone 실기기 검증으로 표현하지 않는다.

## 이전 FAIL과 현재 판정

[최초 결함](../2026-10-22/DEF-SYNC11-RACE.md)은 기준 커밋에서19/20회 재현된 FAIL 이력이다. [이전 두 기기 보고서](../2026-10-22-ios-retest/report.md)는 순차 흐름만 PASS이며 당시 경합 FAIL을 유지했다. 이번에 사용자가 서버 구현을 지시한 뒤 수정했고, 수정 전 기준 코드의 결정적 red와 수정본 green을 분리해 보존했다. 과거 FAIL을 삭제하거나 과거 커밋이 통과한 것으로 바꾸지 않는다.

현재 판정은 **전체 PATCH끼리의 원자적 보호 및 관찰한 iOS 메모 복구 경로에 한해 수정 검증 PASS**다. GitHub #14를 재개/종료하거나 새 이슈를 등록하지 않았다. 로컬 수정 상태이며 병합·배포 상태와 구분한다.

## 환경·실패 분류와 데이터 보존

- 최초 PostgreSQL 재기동이 기본5432에 붙으려다 기존 서비스와 충돌했다. 기존5432는 건드리지 않고 QA 전용 포트를 명시했다. initial real-db-environment-failure.log의 연결 실패는 기능 FAIL로 집계하지 않는다.
- Documents의 이전 QA 클러스터에서 DB 생성이 CopyFileRead 대기로 지연됐다가 완료됐다. 그 클러스터는 보존·종료했다. 최종 검증은 별도 `/tmp/knitgether-sync11-fix-20261024/pgdata` / PostgreSQL14.18 / port55434 / `knitgether_qa_sync11_20261024`를 사용했다. [DB 식별](evidence/database-identity.txt). 임시 클러스터와 별개로 [덤프](evidence/isolated-fixed-db.dump)·[목록 검증](evidence/isolated-fixed-db.contents.txt)을 남겼다.
- A의 앱 컨테이너 조회 지연 및 B의 기본 부팅 timeout을 복구했다. QA 기기의 launchd_sim 부모를 확인한 뒤 그 아래 컨테이너 서비스만 재시작하고, B startup timeout을 늘렸다. 기존 데이터·앱 컨테이너는 삭제하지 않았다. session-restore-first-attempt.log, simulator-A/B-recovery.json에 근거를 남겼다.
- 기록 프록시3300→수정 Nest3301. 전용 FILE_STORAGE_ROOT 사용. 토큰·비밀번호는 HTTP 로그에서 마스킹하고 인증 헤더를 수집하지 않았다. Appium 원본·세션 ID·덤프는 Git 제외한다. 기존 사용자 DB·계정·다른 시뮬레이터는 초기화하지 않았다.

## 문서와 남는 범위

SPEC의 SYNC-11/UI-03·메모 초안 공백, MVP 충돌 절, RTM, 포트폴리오에 날짜와 실행 근거를 반영했다. [SPEC](../../docs/qa/portfolio/02_functional_spec.md), [MVP](../../docs/spec/기능정의서_MVP.md), [도구·설정](../../docs/spec/기능정의서_도구_설정_홈.md), [RTM](../../docs/qa/portfolio/09_test_case_master.md), [포트폴리오](../../docs/qa/submission/portfolio.md).

UI-03은 앞선2026-10-24 양 기기 검증의 PASS 이력을 연결했다. 이번 서버 PATCH 수정 후 UI-03 전체를 재실행한 것은 아니다. iOS·계산·프로필 코드는 변경하지 않았다.

남는 범위는 자식 전용 API와 전체 PATCH 사이의 통합 버전 규약, RC-08 도안 파일 고아화, 오프라인/앱 종료 후 초안 수명, 장시간 자동 저장·물리 기기·부하 SLA다. DB rollback이 물리 파일을 복구한다고 주장하지 않는다. 같은 앱의 모든 입력·모든 엔드포인트를 승인하지 않는다.

## 사용자 판단과 Codex 작업

| 주체 | 실제 역할 |
|---|---|
| 사용자 | 선행 데이터·초안 보존, 수동 재저장, cm 고정, E2E/API 구분·격리·보존 기준을 직접 지정. 이번에 서버 구현→DB 검사→두 기기→문서 갱신을 승인·지시. |
| Codex | CAS·단조 버전과 회귀 설계를 제안하고 승인 범위에서 서버/테스트 구현, 환경 복구, 실제 테스트·UI 조작·DB/HTTP/화면 증거 수집, 결과 판정 및 문서 갱신을 수행. |
| 미수행 | 사용자의 직접 수동 테스트로 기록하지 않음. GitHub 이슈 처리·commit/push·운영 배포·릴리즈 승인 없음. |

포트폴리오 요약: 나는 요구사항과 수용 기준을 정하고 단계별 수정·검증을 지시했다. Codex는 서버의 같은 버전 동시 저장 결함을 조건부 갱신으로 수정하고 실제 PostgreSQL의 경합·자식 원자성·롤백을 검증했다. 수정 전 두200과 수정 후1성공/1충돌을 대조하고, 두 iOS 시뮬레이터에서 입력 보존과 수동 재저장·재충돌을 실제로 확인했다. 기존 FAIL과 수정 후 PASS, 사용자 판단과 Codex 실행을 구분해 남겼다.

최종 [증거·소스 무결성 점검](evidence/final-audit.json), [SHA256 목록](evidence/SHA256SUMS.txt), [문서 변경](evidence/documentation-change.patch), [환경 종료 기록](evidence/shutdown.txt)을 보존했다.
