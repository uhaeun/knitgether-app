# SYNC-11 후속 검증과 CI 연결

2026-10-24 KST. 기준 `75a9882eb841044aba1067ddbc703a985a4515d2` + fix/sync11-atomic-save 작업 브랜치. 사용자의 “진행해줘” 지시에 따라 PR 준비, 실제 DB CI 연결, 자식 API 경합, 파일 고아화를 진행했다. 운영 배포·병합은 범위 밖이다.

## 결과

| 케이스 | 실제 결과 | 판정 |
|---|---|---|
| 기존 전체 PATCH vs PATCH 원자성·롤백·계약 8개 | 실제 PostgreSQL14.18 + Nest HTTP, 8 PASS. 결정적 경합 5쌍 포함 | PASS |
| 기존 서버 회귀 / 빌드 | 12 suites, 147 PASS / build 성공 | PASS |
| CHILD-01: 자식 카운터 저장 후 오래된 전체 저장 | 자식77단 저장200, 부모 updatedAt 그대로. 이전 baseline 전체 저장200, DB 0단으로 유실 | FAIL · 제품 결함 |
| CHILD-02: 전체 저장의 읽기와 CAS 사이 자식 API 저장 | 실제 요청을 중간에 실행. 자식88단 저장200 후 전체 저장200, DB 0단 | FAIL · 제품 결함 |
| FILES-01: SQL rollback 후 물리 파일 | 실제 원본 fixture를 복사하고 실제 upsert 뒤 실패 주입. 부모·자식 SQL은 완전 rollback, 새 PDF 1개는 파일시스템에 남음 | FAIL · RC-08 재현 |
| FILES-02: 도안 사본 교체 후 이전 파일 | 새 사본 ID·파일 키로 정상200 저장. DB 참조가 끊긴 이전 PDF가 여전히 존재 | FAIL · RC-08 재현 |
| GitHub Actions 실행 | PR 생성 후 원격 실행 결과를 아래 후속 상태에서 기록 | 실행 상태 별도 확인 |

[8개 PASS 원본](evidence/gate-results.json), [PASS HTTP·DB](evidence/gate-db.json), [4개 FAIL 원본](evidence/known-gaps-results.json), [FAIL HTTP·DB·파일목록](evidence/known-gaps-db.json). 테스트 오류나 환경 실패를 제품 FAIL로 대신 집계하지 않았다. FILES-01의500 자체는 테스트 실패 주입의 결과이며 제품에서 자연 발생하는500을 주장하지 않는다. 파일 fixture는 복사 경로 검사용 최소 바이트이며 PDF 렌더러 검증이 아니다. 테스트 종료 시 자신이 만든 임시 파일 저장소만 정리했고, 관찰한 잔존 상태는 JSON에 보존했다. DB UUID fixture는 전용 QA DB에 보존했다.

## 결함 구분과 수정 제안

**QA-SYNC11-CHILD (P1, 신규 재현 증거)**: 이전부터 범위 밖으로 명시한 자식 API 버전 규약의 공백을 실제 요청으로 확인했다. 원인은 row-counter PATCH가 RowCounter만 갱신하고 부모 Project.updatedAt을 갱신하지 않는 점이다. 전체 PATCH의 CAS는 부모 버전 변화가 없어 성공한다. 이는 수정 전 전체 PATCH 두 건이 모두200이던 QA-SYNC11-RACE와 별개다. 그 결함의 검증 PASS를 취소하지 않으며 앱 전체 동시 수정 안전성을 선언하지 않는다.

제안: 프로젝트 aggregate를 바꾸는 모든 쓰기 경로가 동일한 부모 버전 규약과 잠금 순서를 공유하도록 설계한다. 카운터 변경·부모 버전 증가는 한 트랜잭션으로 수행하고, 전체 저장과 같은 부모 행을 먼저 잠그거나 조건부 갱신한다. 자식 API도 baseline을 요구할지, 원자적 증감 명령으로 바꿀지는 제품 판단이 필요하다. 행안내·세션·도안 업로드·삭제·사진·실 사용량 API를 전수 조사한 뒤 확대한다. 이번 실제 재현 범위는 카운터 경로 두 순서다.

**RC-08 (P2, 기존 알려진 범위의 재현)**: DB 트랜잭션은 물리 파일 쓰기를 되돌리지 않는다. 도안 교체 코드도 이전 파일 참조를 끊고 정리를 하지 않는다는 주석이 있다. 롤백과 정상 교체 두 조건 모두 재현했다. 새 결함 두 건으로 중복 계산하지 않는다.

제안: staging 파일 + commit 후 참조 전환/실패 시 보상 삭제, 삭제 작업 outbox 및 재시도, 일정 유예 후 참조 기반 고아 파일 수집기를 설계한다. 롤백 직후나 교체 직후 삭제가 제품 요구인지, 정해진 시간 내 비동기 정리가 허용되는지 SPEC에 명시한다. 동시 요청 중 사용 중인 파일을 삭제하지 않는 검증도 필요하다. 이번에는 제품 파일 정리 코드나 기존 데이터를 수정·삭제하지 않았다.

## CI와 재현

`.github/workflows/ci.yml`에 독립 `project-concurrency` 잡을 추가했다. PostgreSQL14 service와 전용 DB `knitgether_qa_sync11_ci`, Node22, npm ci·Prisma generate·migrate deploy 후 실제 DB 테스트를 실행한다. job별 PostgreSQL 컨테이너를 사용하며 기존 API job DB와 공유하지 않는다. 성공/실패 모두 JSON 결과·요청·응답·DB snapshot을 artifact로 업로드한다. iOS E2E를 대체하는 잡이 아니다.

4개 알려진 결함 수용 검사는 `QA_RUN_KNOWN_GAPS=1`로만 실행한다. 기본 CI는 8 PASS / 4 SKIPPED이며 SKIPPED를 PASS에 더하지 않는다. 알려진 결함을 올바른 기대값(409·데이터 보존·파일 정리)으로 검사하므로 명시 실행 시 현재 4 FAIL이다. 이 검사를 CI 게이트에서 제외했다는 한계를 PR에 공개한다. 결함 수정 후 opt-in 조건을 제거해 게이트로 승격해야 한다.

```sh
QA_REAL_DATABASE_URL='postgresql://knitgether@127.0.0.1:55434/knitgether_qa_sync11_20261024?connection_limit=6' npm --prefix server run test:db:projects
QA_RUN_KNOWN_GAPS=1 QA_REAL_DATABASE_URL='postgresql://knitgether@127.0.0.1:55434/knitgether_qa_sync11_20261024?connection_limit=6' npm --prefix server run test:db:projects -- --testNamePattern='KNOWN GAP'
```

로컬 DB는 기존 격리 클러스터 `/tmp/knitgether-sync11-fix-20261024/pgdata`, port55434다. 사용자 DB5432/5433과 이전 QA 자료는 보존했다. 환경과 원본 로그는 이 evidence 폴더에 별도 보관해 이전 SHA256 목록을 바꾸지 않았다.

## SPEC·RTM·포트폴리오 반영 제안

SYNC-11에는 “전체 PATCH 간 버전 검사”와 “모든 자식 쓰기를 포함한 aggregate 보호”를 별도 수용 조건으로 둔다. 전자는 이번 수정본 PASS, 후자는 카운터 경로 FAIL이다. RTM에 CHILD-01/02를 추가하고, FILES-01/02는 RC-08 하위 재현으로 연결한다. 파일 정리의 허용 지연·실패 재시도·동시 참조 보존 기준을 추가한다. UI-03은 [이전 양 기기 실행 PASS](../2026-10-22-ios-retest/report.md)를 유지하며 이번 후속 작업에서 재실행하지 않았다. [수정 후 두 iOS 실행 19항목 PASS](../2026-10-24-sync11-fix/report.md)도 별도 증거다.

사용자는 데이터 보존·수동 재저장·cm 고정과 검증 기준을 직접 지정하고 후속 진행을 지시했다. Codex는 CAS 설계·구현, CI 구성, 실제 SQL/HTTP 테스트와 이전 두 시뮬레이터 조작, 증거 수집·판정을 수행했다. 사용자가 이 테스트를 직접 수동 실행했다고 표현하지 않는다.

포트폴리오 요약: 요구사항과 수용 기준을 정하고 Codex의 실행 결과를 검토하는 방식으로 QA를 진행했다. 전체 저장 간 경합 수정은 실제 DB와 두 iOS 시뮬레이터로 확인했고, 후속 경계 검사에서는 자식 API의 갱신 유실과 파일 고아화를 별도 재현했다. 범위별 PASS·FAIL 및 자동화의 미실행 범위를 공개하고 실제 DB 회귀를 CI에 연결했다.
