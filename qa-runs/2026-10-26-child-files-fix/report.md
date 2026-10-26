# KnitGether 자식 카운터 갱신 유실·도안 파일 고아화 수정 및 재검증

2026-10-26 KST. 기준 `c0943ca41de4a5bc7fbeff6cb58957f3e4b09626`, 브랜치 `fix/sync11-atomic-save` 위의 로컬 변경. 사용자가 남은 두 결함의 제품 수정과 재검증을 직접 요청했다. 기존 [Draft PR #48](https://github.com/uhaeun/knitgether-app/pull/48)의 후속 로컬 작업이며 이번 변경의 커밋·push·원격 CI·병합·배포는 수행하지 않았다.

## 최종 판정

기존 수용 검사 **CHILD-01/02·FILES-01/02 4개 모두 수정 전 FAIL → 수정 후 PASS**. 새 검사까지 포함한 실제 PostgreSQL+Nest HTTP 검사는 **18 PASS / 0 FAIL / 0 SKIP**, 기존 서버 회귀 **147 PASS**, 별도 실행 서버의 HTTP/API+DB 회귀 **75 PASS**, 서버 빌드 PASS다. 서로 다른 계층의 개수를 독립 요구사항 수로 합산하지 않는다.

| 수용 조건 | 수정 전 | 수정 후 |
|---|---|---|
| CHILD-01: 카운터 저장 뒤 오래된 전체 PATCH | 77단이 0단으로 덮임, 둘 다 200 | 전체 PATCH 409, 77단 보존 |
| CHILD-02: 전체 읽기와 CAS 사이 카운터 저장 | 88단이 0단으로 덮임, 둘 다 200 | 전체 PATCH 409, 88단 보존 |
| FILES-01: SQL rollback 후 새 파일 | 참조 없는 새 PDF 잔존 | SQL rollback 후 새 PDF 보상 삭제 |
| FILES-02: 도안 사본 ID 교체 | 이전 PDF 잔존 | commit 후 이전 PDF 삭제, 새 사본 유지 |

[수정 전 4 FAIL 결과](evidence/before-results.json)·[당시 요청/응답/DB/파일](evidence/before-db.json), [수정 후 18 PASS 결과](evidence/after-results.json)·[요청/응답/DB/파일 및 잠금 관찰](evidence/after-db.json), [서버 147 결과](evidence/server-results.json), [API 75 JUnit](evidence/api-results.xml), [빌드 로그](evidence/build.log)를 보존한다. 테스트용 실패 주입의 500은 자연 발생 제품 오류를 의미하지 않는다.

## 제품 변경

### 자식 카운터

카운터 PATCH가 동일 트랜잭션 안에서 부모 Project의 버전을 조건부 갱신해 부모 행 잠금을 확보한 다음 RowCounter를 저장한다. 버전은 `max(현재 시각, 이전 버전+1ms)`로 증가한다. 다른 쓰기가 먼저 부모 버전을 바꾸면 자식 경로는 최신 버전을 읽어 잠금 확보만 재시도한다. 전체 PATCH는 기존과 같이 오래된 baseline이면 409이며 자동 재저장하지 않는다. 자식 실패 시 부모 버전도 함께 rollback한다.

카운터가 먼저 commit하는 두 순서 외에, 전체 PATCH가 부모 잠금을 잡은 상태에서 자식 HTTP 요청을 보내 PostgreSQL `pg_stat_activity.wait_event_type=Lock`을 관찰했다. 전체 저장 commit 후 자식 저장이 진행되고 최종 메모와 99단, 증가한 버전이 보존됐다. 두 자식 요청 사이의 baseline 충돌 계약을 새로 도입한 것은 아니다. 카운터 전용 API의 기존 응답 형식은 유지한다.

### 도안 파일

전체 프로젝트 생성/갱신에 요청별 파일 목록을 둔다. 새 PDF는 SQL 실패 후 보상 삭제하고, 교체·연결 해제로 참조가 끊기는 이전 PDF/드로잉은 commit 후 삭제한다. 삭제 전 현재 ProjectPatternCopy 참조를 다시 확인하며 soft-delete 참조도 보존한다. 원본 창고 파일은 삭제하지 않는다.

파일 생성 전에 스토리지 `.pattern-cleanup`에 후보 키를 기록하고, 이전 파일도 참조 해제 전에 후보로 기록한다. marker는 임시 파일을 flush한 뒤 rename으로 교체한다. 삭제 실패가 저장 성공을 HTTP 실패로 바꾸지 않도록 marker와 경고를 남긴다. 서비스 시작 및 매 60초에 **기록 후 1시간이 지난** 미참조 후보를 재시도한다. DB나 스토리지 장애 중에는 완료 시간을 보장하지 않는다. 활성 트랜잭션이 생성 중인 파일을 회수하지 않도록 유예한다. 손상 marker는 경고 후 다른 후보 처리를 계속한다. 파일/marker가 삭제되면 작업도 제거된다.

재시도 검사는 실제 unlink 실패를 주입하고 후보 시각을 1시간 전으로 이동한 후 새 서비스/스토리지 인스턴스로 실행했다. 1시간의 벽시계를 실제로 기다리거나 OS 프로세스를 강제 종료한 실험은 아니다. 실패 사본 교체의 기존 PDF/드로잉 보존, 정상 연결 해제의 두 파일 정리, 생성 rollback, 최신 참조 파일·창고 원본 보존을 검증했다.

## 검증 환경과 회귀 변경

기존 격리 PostgreSQL 14.18 클러스터 `/tmp/knitgether-sync11-fix-20261024/pgdata`를 **127.0.0.1:55434**로 명시 기동했다. DB는 `knitgether_qa_sync11_20261024`, API는 전용 3302, API 파일 저장소는 이 실행 폴더의 storage다. 원래 사용자 DB5432/5433과 기존 QA 파일은 초기화하지 않았다. 실제 DB 테스트는 임시 storage와 고유 UUID 계정을 사용하며 테스트 종료 전 상태를 JSON으로 기록하고 자신이 만든 임시 storage만 정리한다. pytest는 자신이 만든 계정만 teardown한다. 실제 DB 검사 UUID 데이터는 남아 있다.

첫 DB 기동은 포트 명시가 없어 기존5432와 충돌해 실패했고, 기존 서비스를 중지하지 않고55434로 재기동했다. 본격 수정 전 4 FAIL은 DB 연결 복구 후 실제 SQL/HTTP로 관찰했다.

API 첫 실행은 **69 PASS / 6 FAIL**이다. 5개는 네트워크 게이트가 기본3000을 향해 새 격리 서버3302에서 발급한 토큰으로401을 받은 테스트 환경 설정 문제였다. `KG_NETGATE_FORWARD_PORT=3302`를 명시해 복구했다. 나머지1개는 과거 API-24가 “교체 후 이전 파일이 남는다”는 결함 동작을 정상으로 고정한 검사였다. 새 수용 기준에 맞춰 이전 PDF·드로잉 삭제와 새 PDF 보존을 단언하도록 바꿨다. 파일 실측에서 `.pattern-cleanup` 메타데이터는 사용자 파일로 세지 않도록 제외했다. [첫 JUnit](evidence/api-first-results.xml)과 api-first.log를 보존하며 이6개를 신규 제품 결함으로 집계하지 않는다.

기존 known-gap opt-in을 제거해 수용 검사4개는 기본 `npm run test:db:projects` 및 기존 CI job에서 항상 실행된다. 이는 **CI 소스의 게이트 승격**이며 이 로컬 작업이 원격에서 이미 실행됐다는 의미가 아니다.

## 재실행

저장소 루트에서, 전용 QA DB55434가 실행 중일 때:

```sh
npm --prefix server run build
npm --prefix server run test:e2e
QA_REAL_DATABASE_URL='postgresql://knitgether@127.0.0.1:55434/knitgether_qa_sync11_20261024?connection_limit=6' npm --prefix server run test:db:projects
```

API 회귀는 동일 DB/파일 저장소의 서버3302를 먼저 띄우고 `API_BASE_URL=http://127.0.0.1:3302/api/v1 KG_NETGATE_FORWARD_PORT=3302 DB_HOST=127.0.0.1 DB_PORT=55434 DB_USER=knitgether DB_PASSWORD=knitgether DB_NAME=knitgether_qa_sync11_20261024 FILE_STORAGE_ROOT=<이 실행 폴더/storage 절대경로>`와 기존 QA venv로 pytest를 실행한다.

## 판정 범위

이번 두 결함의 **재현된4개 수용 조건은 로컬 FIXED / VERIFIED**다. RC-08 전체 저장소의 과거 누적 고아 파일을 일괄 삭제한 것은 아니다. marker가 없는 과거 파일을 임의 추측해 지우지 않는다. soft-delete 참조 파일은 보존하며, 창고·사진·전용 업로드/삭제 등 모든 파일 경로의 수명주기를 일괄 해소했다고 주장하지 않는다. 카운터 이외 자식 전용 API의 버전 규약도 별도 범위다.

iOS 제품 소스는 변경하지 않았고 이번에는 시뮬레이터·실기기·iOS CI를 재실행하지 않았다. [앞선 UI-03 양 기기](../2026-10-22-ios-retest/report.md), [SYNC-11 19항목](../2026-10-24-sync11-fix/report.md), [10/26 iOS CI](../../../qa-delivery/2026-10-26-pr48-ios-retest/report.md)는 당시 범위의 이력으로 유지한다. 앞선 CI PASS를 이번 서버 변경의 E2E PASS로 바꾸지 않는다. 전체 제품 릴리즈 승인도 별도다.

사용자는 두 결함의 수정·재검증을 승인했다. Codex는 원인 분석·설계·제품 구현·테스트 수정·실제 실행과 판정·문서화를 수행했다. 사용자 직접 수동 실행으로 기록하지 않는다.

최종 [소스·증거 점검](evidence/final-audit.json), [변경 패치](evidence/changes.patch), [소스 해시](evidence/source-sha256.json), [환경 종료 기록](evidence/shutdown.txt)을 보존했다. 전용 DB dump도 로컬에 보존한다.


2026-10-26 재현 명령 정정: 위 환경변수명의 커밋 문자열 혼입을 QA_REAL_DATABASE_URL과 API_BASE_URL로 바로잡았다. 당시 실행 결과와 원본 증거는 변경하지 않았다.
