# QA-SYNC11-RACE 수정 설계안

작성일: 2026-10-24 KST. 기준 커밋: `75a9882eb841044aba1067ddbc703a985a4515d2`.
상태: **설계 제안 완료 / 제품 구현·신규 회귀 테스트 실행 전**. 제품 코드, 스키마, 기존 테스트, 승인된 SPEC는 변경하지 않았다.

## 결론과 수정 범위

`PATCH /projects/:id`의 부모 UPDATE를 **소유자·활성 상태·정확한 기준 버전을 조건으로 하는 단일 조건부 UPDATE**로 바꾸는 안을 권고한다. 갱신 건수가 1일 때만 기존 자식 저장을 실행하고, 실패하면 409를 던져 트랜잭션을 끝낸다. 매 성공 시 `updatedAt`을 이전 값보다 최소 1ms 증가시킨다.

현재 API의 `baseUpdatedAt`, 성공 응답, `409 PROJECT_CONFLICT`/`details.latest` 구조를 유지한다. 정수 version 도입이나 iOS 변경, 자식 전용 API 전체 재설계는 이번 최소 수정 범위에 포함하지 않는다. **동일 프로젝트의 전체 PATCH끼리 충돌을 막는 수정**이며 모든 엔드포인트의 동시성 보장을 승인하는 안은 아니다.

## 기존 증거와 코드 근거

- [최초 결함 보고서](../2026-10-22/DEF-SYNC11-RACE.md): 실제 API+DB 경합에서 19/20회 두 요청 모두 200. 이 설계 작업에서 재실행하지 않았다.
- [두 시뮬레이터 최종 QA](../2026-10-22-ios-retest/report.md): 순차 충돌·입력 보존·수동 복구 및 UI-03 PASS. 서버 경합 FAIL은 별도로 유지한다.
- `server/src/projects/projects.service.ts:238`의 findFirst → `:255` 버전 비교 → `:258` where id UPDATE 사이에 경합 창이 있다. 두 요청이 같은 이전 본을 읽으면 함께 비교를 통과한다.
- `:1476`은 Date로 기준값을 파싱하고 `:1478`은 서버가 더 최신인 경우만 거절한다. 미래 기준값의 정확한 버전 일치는 현재 검사하지 않는다. 미래 값 경로는 이번 설계에서 식별한 계약 보강 후보이며 별도 실행으로 결함 재현을 확정한 것은 아니다.
- `:1567` saveProjectChildren는 RowCounter upsert → RowInstruction 교체 → WorkSession 증분 upsert → ProjectPatternCopy 저장을 수행한다. 모두 동일 transaction 인자를 사용한다.
- `server/prisma/schema.prisma:89`: Project.updatedAt은 DateTime @updatedAt. 정수 version은 없다. 밀리초가 변하지 않는 저장을 배제하려면 명시적 버전 증가가 필요하다.
- 설치된 Prisma Client 6.19.3 생성 타입에서 project.updateMany / BatchPayload.count / ProjectUncheckedUpdateManyInput.updatedAt 지원을 확인했다. 프로젝트가 사용하는 API는 현재 최신 웹 문서의 Prisma 8 API와 다르므로 업그레이드 예제를 그대로 적용하지 않는다.

## 변경 지점

| 위치 | 제안 변경 | 유지할 계약 |
|---|---|---|
| projects.service.ts / updateProject | 부모 update를 updateMany 조건부 갱신으로 대체, count 확인 후 자식 저장 | 소유자·활성 프로젝트만 수정, 성공 200 |
| assertNoSaveConflict 및 충돌 생성 helper | 밀리초 epoch 기준 정확한 일치 검사, CAS 실패에서도 동일 오류 생성 재사용 | code/message/details.latest 형식 |
| 갱신 scalar 입력 helper | updateMany 전용 타입으로 명시하고 nextUpdatedAt 추가 | 부모 scalar 필드 매핑, 자식은 별도 helper |
| project-save.dto.ts 주석 | ‘서버보다 오래됨’에서 ‘마지막 서버 버전과 일치’로 계약 설명 제안 | POST 기준값 불필요, PATCH 누락은 400 |
| 기존 route mock 테스트 | updateMany/count mock 및 실패 후 자식 저장 미호출 검사 보강 | 400·404·409 등 기존 응답 |
| 실제 DB 통합 테스트 | 동시 실행·롤백·버전 경계 검사 신설 | mock 결과를 실제 DB 증거로 대체하지 않음 |

스키마 마이그레이션은 이 안에 필요하지 않다. iOS는 이미 서버 updatedAt을 보존하고 재전송하는 경로가 있어 서버 수정부터 검증한다. iOS 호환성은 수정 후 실제 시뮬레이터 재검증으로 확정한다.

## 제안 처리 순서

1. 기존 route ID/body ID 일치와 자식 참조 검증을 유지한다.
2. interactive transaction 안에서 소유자·활성 조건으로 기존 프로젝트/자식을 읽는다. 없으면 기존대로 404.
3. baseUpdatedAt 누락은 400. 날짜 유효성은 기존 DTO 검증을 유지하고, 파싱 결과가 유한한지도 방어적으로 확인한다. 잘못된 날짜를 충돌 409로 뭉뚱그리지 않는다.
4. `baseMs === existing.updatedAt.getTime()`를 요구한다. 문자열 비교가 아니라 같은 시각을 비교한다. 과거/미래의 불일치는 409 제안이다. **미래 값 거절은 기존보다 엄격한 계약 변경**으로 SPEC/테스트에 명시한다.
5. 저장된 RowCounter identity 검증을 유지한다. 이 검증은 행안내가 있을 때만 ID 일치를 강제한다. 행안내가 없는 요청의 ID 불일치는 저장된 카운터를 갱신하는 기존 호환 동작을 유지한다.
6. `nextUpdatedAt = new Date(max(nowMs, existingMs + 1))`을 계산한다. nowMs는 서버 시각이며 클라이언트 미래값을 사용하지 않는다.
7. 아래 조건부 UPDATE를 실행한다. 갱신 실패 전 자식 mutation은 실행하지 않는다.
8. count가 0이면 같은 transaction에서 소유자·활성 조건으로 최신 프로젝트를 다시 읽는다. 있으면 409/latest, 없으면 기존 비공개·삭제 계약대로 404. 다른 사용자의 최신 데이터를 반환하지 않는다. latest 변환 실패 시 기존처럼 latest=null로 409 자체를 유지한다.
9. count가 1이면 saveProjectChildren를 동일 transaction으로 실행한다. 실패하면 예외를 전파해 부모 버전 갱신까지 롤백한다. 내부에서 오류를 삼키고 성공 응답을 반환하지 않는다.
10. 저장 후 include 조회와 기존 응답 직렬화를 실행한다. callback 성공 및 commit 뒤 200을 반환한다.

설명용 의사 코드이며 적용·컴파일한 제품 패치가 아니다:

```ts
return prisma.$transaction(async (tx) => {
  const existing = await findOwnedActiveProjectWithChildren(tx, ownerId, id);
  requireBaseAndExactVersion(existing, body.baseUpdatedAt);
  assertStoredRowCounterIdentity(existing.rowCounter, body);
  const nextUpdatedAt = nextVersionTime(existing.updatedAt, serverNowMs());

  const changed = await tx.project.updateMany({
    where: {
      id, ownerId, deletedAt: null,
      updatedAt: new Date(body.baseUpdatedAt!),
    },
    data: {
      ...projectScalarUpdateData(ownerId, body), // updateMany 전용 scalar 타입
      updatedAt: nextUpdatedAt,
    },
  });
  if (changed.count !== 1) {
    const latest = await findOwnedActiveProjectWithChildrenOrNull(tx, ownerId, id);
    if (!latest) throw projectNotFound();
    throw projectConflict(latest); // PROJECT_CONFLICT + details.latest
  }
  await saveProjectChildren(tx, ownerId, body);
  return toResponse(await findOwnedActiveProjectWithChildren(tx, ownerId, id));
}, { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted });
```

현재 toProjectUpdateInput은 `ProjectUncheckedUpdateInput` 반환형이므로 단순 복사해 타입 단언으로 밀어 넣지 않는다. scalar 입력을 공유하되 updateMany 전용 반환형 `Prisma.ProjectUncheckedUpdateManyInput`으로 별도 선언한다. 생성용 helper와 자식 relation 입력을 혼합하지 않는다.

## 원자성·버전 보장

PostgreSQL Read Committed에서는 대기 중이던 UPDATE가 선행 트랜잭션 commit 후 변경된 행에 WHERE를 재평가한다. 정확한 updatedAt 조건이 있고 선행 성공이 반드시 버전을 바꾸면, 같은 기준 버전의 후행 요청은 count=0이 된다. 이 문서의 설계 추론이며 실제 제품 수정 후 검증이 필요하다. [PostgreSQL 14 공식 설명](https://www.postgresql.org/docs/14/transaction-iso.html#XACT-READ-COMMITTED).

트랜잭션 격리 수준은 이 경로에 ReadCommitted를 명시하는 안이다. 전역 DB 설정을 바꾸거나 Serializable 충돌을 무조건 재시도하는 변경은 하지 않는다. 실제 통합 테스트에서 격리 수준과 connection 수를 확인한다.

`@updatedAt` 자동 시각만으로는 같은 밀리초의 연속 쓰기를 구분한다고 가정하지 않는다. 명시적 +1ms는 이 PATCH 경로의 성공 버전을 단조 증가시키기 위한 것이다. 서버 시계가 뒤로 이동하거나 현재시각이 동일해도 증가해야 한다. 초당 1,000회 이상 연속 쓰기 등으로 논리 시각이 실제 시각보다 앞설 수 있으므로 updatedAt은 이 경로에서 순수한 벽시계 시각만은 아니다. 장기적으로는 정수 revision이 더 명확하다. 날짜 표현 가능 범위를 넘는 경우 잘못된 날짜 저장이나 부분 commit 대신 오류·전체 롤백으로 처리한다.

## 자식 데이터 및 범위 경계

거부된 요청이 RowCounter 값을 바꾸거나 RowInstruction을 삭제/재생성하거나 WorkSession/PatternCopy를 남기면 실패다. 부모 상태만 맞는 것으로 통과시키지 않는다. 성공 응답도 서로 다른 요청의 부모·자식이 섞인 상태여서는 안 된다.

자식 저장 중 오류가 나면 부모 scalar/updatedAt, 이미 변경된 RowCounter와 RowInstruction, WorkSession/PatternCopy가 모두 이전 상태로 복구돼야 한다. DB sequence 번호의 간격처럼 롤백을 보장하지 않는 부수값을 데이터 유실로 판정하지 않는다.

**남는 경계:** `updateProjectRowCounter`(:352)는 부모 버전을 올리지 않고 자식을 직접 수정한다. 다른 자식 전용 API와 deleteProject 역시 동일 잠금/버전 규약을 공유하는지 별도 대조가 필요하다. 이번 최소 패치로 ‘자식 전용 쓰기 vs 전체 PATCH’ 전체를 보호한다고 기록하지 않는다. 이를 포함하려면 모든 aggregate 쓰기에 부모 버전 증가·조건 검사 및 부모→자식 잠금 순서를 도입하는 별도 설계가 필요하다. 모든 쓰기를 강제하는 정수 revision 도입도 그 단계에서 검토한다.

**DB 밖의 부수효과:** saveProjectPatternCopy(:1763~)는 원본 PDF를 읽고 FileStorage에 새 파일을 쓴 뒤 DB 메타데이터를 저장한다. 이 물리 파일은 PostgreSQL rollback으로 되돌아가지 않는다. CAS 거절은 자식 helper 앞에서 끝내 파일 복사를 시작하지 않도록 하되, CAS 성공 후 늦은 오류의 파일 고아화까지 이 수정으로 해결됐다고 주장하지 않는다. 소스에도 RC-08 파일 고아화의 별도 범위가 명시돼 있다. 테스트 파일은 전용 저장 경로에 두고 파일 목록·참조를 별도로 기록하며, 보상 삭제/staging 처리는 후속 설계로 분리한다. 새 파일 유출을 이번에 실행으로 재현·확정한 것은 아니다.

기존 서버 오류를 모두 409로 바꾸지 않는다. 연결 실패·제약 위반·timeout/deadlock/serialization 오류는 해당 원인으로 관찰하고, 최신 버전을 가져와 사용자 요청을 자동 재저장하지 않는다.

## 대안 비교

| 대안 | 장점 | 비용·주의 | 결정 제안 |
|---|---|---|---|
| 정확한 updatedAt CAS + 명시적 증가 | 현재 API/스키마 유지, 조건과 성공 개수 관찰 가능 | 모든 쓰기의 통합 보장은 별도, 논리 시각 한계 | 이번 PATCH 결함 수정의 우선안 |
| 부모 SELECT FOR UPDATE + 비교 + 증가 | 같은 행의 전체 PATCH를 직렬화 가능 | 잠금 순서·대기 관리 필요, 시각 증가 없으면 같은 ms 문제 유지 | 대안 |
| 정수 revision CAS | 시간 해석과 분리된 버전 | DB migration, API·iOS 호환 및 모든 writer 갱신 필요 | 후속 구조 개선 |
| Serializable만 적용 | 일부 경합을 DB가 거절 | 40001 처리 필요, 곧바로 409/latest 계약이 되지 않음 | 단독 처방으로 채택하지 않음 |

Prisma의 현행 웹 문서는 Prisma 8로 연결되므로 이 저장소의 6.19.3 구현 근거로 사용하지 않았다. API 사용 가능성은 로컬 생성 타입과 설치 버전으로 대조했다. 최신 문서 URL: [Prisma transactions](https://www.prisma.io/docs/orm/fundamentals/transactions).

## 구현 이후 완료 기준

[회귀 테스트안](regression-plan.md)의 P0 실제 DB 검사 및 기존 계약 회귀 통과 → A/B 실제 시뮬레이터 충돌 재검증 → 요청·SQL·화면 증거로 보고서 추가가 완료 기준이다. 서버 API 통과를 iOS E2E 통과로 확대하지 않는다. 현재 결함은 **FAIL/Open 유지**하며 수정 완료나 릴리즈 승인을 선언하지 않는다.

## 판단·실행 구분

- 사용자: 입력 보존·선행 데이터 보호·직접 재저장·제품 코드 임의 수정 금지와 후속 설계 진행을 지정했다.
- Codex: 현재 코드/생성 타입/기존 QA를 분석하고 CAS·단조 버전 증가를 기술 대안으로 제안했다. 이 설계의 선택과 신규 테스트 기준은 Codex 제안이며 사용자 확정 명세로 기록하지 않는다.
- 이번에 수행하지 않은 것: 제품 패치, migration, 신규 테스트 구현/실행, 이슈 등록·재개, 릴리즈. 기존 PASS/FAIL 증거를 재실행한 것으로 집계하지 않았다.
