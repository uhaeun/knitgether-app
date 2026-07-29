# API 정합성 테스트 (산출물 3)

실행 중인 KnitGether 서버 + 실 Postgres를 **black-box HTTP + 직접 DB 조회**로
검증하는 pytest 스위트.

## 왜 별도 계층인가
기존 서버 e2e(Jest)는 12개 스펙 중 9개가 mock Prisma(인메모리)라 **실 DB 정합성**
—ownerId 격리, soft delete, cascade, 트랜잭션 원자성, DB 제약—을 검증하지 못한다.
이 스위트가 그 공백을 메운다. 계약(contract)은 Jest, 정합성(integrity)은 pytest.

## 테스트 6종
| 파일 | 검증 | 근거 조항 |
|---|---|---|
| test_01_ownership_isolation | ownerId 격리(A↔B) + DB 무변경 | §C-1 유저 격리 |
| test_02_last_write_wins | 동시수정 충돌 미감지(통과=결함 존재) | §C-1, **Issue #14** |
| test_03_create_idempotency | 동일 id 재생성 멱등(upsert) | §A-3 |
| test_04_delete_cascade | 삭제의 soft-cascade(자식 deletedAt) | §B 프로젝트 CRUD |
| test_05_transaction_atomicity | 자식 실패 시 부모 롤백 | §A-3 $transaction |
| test_06_auth_and_boundaries | 토큰 경계 + currentRow/시간역전 경계값 | §C-2, §B |

## 실행
```bash
cd qa/api-tests
python3 -m venv .venv && ./.venv/bin/pip install -r requirements.txt
# 서버 기동 필요: (server) npm run start:dev
./.venv/bin/pytest -v
```

## 환경 변수(기본값)
- `API_BASE_URL` = http://127.0.0.1:3000/api/v1
- `DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME` = localhost / 5433 / knitgether / knitgether / knitgether_dev

## 데이터 위생
매 실행 유니크 계정(`pytest-<ts>-<uuid>@`)을 만들고, 세션 종료 시 **이 실행이 만든
계정만** cascade 삭제한다(수동 QA 데이터 불침해). `.venv/`는 커밋 대상 아님.

## 결과 해석 규칙
- **FAIL = 결함 후보.** 이 스위트에서 코드를 고치지 않는다 — 결함으로 보고한다.
- test_02는 **PASS 해야 정상**(결함 #14가 그대로 존재한다는 뜻). 훗날 충돌 보호가
  도입되면 test_02가 FAIL로 바뀌며, 그게 회귀 알림이 된다.
