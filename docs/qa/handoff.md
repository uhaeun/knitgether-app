# KnitGether — QA 인수용 핸드오프

> 작성: 2026-07-30. 대상: 이 앱을 QA로 인수받는 사람.
> 정본 스펙은 `docs/spec/KnitGether_스펙_v2.3.md`. 이 문서는 그 스펙과 실제 코드를 QA 관점에서 압축한 시스템 안내서다(TC·테스트 코드는 포함하지 않는다).
> **중요**: 기획서 v2.2는 "로컬 전용 · CoreData · 서버/로그인/동기화 없음"이라고 하지만, **실제 구현은 서버 + 인증 + 오프라인 동기화까지 초과 구현**됐다. 항상 코드(v2.3)를 기준으로 판단할 것.

---

## 1. 아키텍처

```
┌─────────────────────────────┐         HTTPS/HTTP (REST, /api/v1)        ┌──────────────────────────┐
│         iOS 앱 (SwiftUI)     │  ────────────────────────────────────▶   │   NestJS 서버 (TypeScript) │
│  - 배포 타겟 iOS 16          │   Authorization: Bearer <JWT>             │  - REST prefix /api/v1     │
│  - MVVM + Repository 계층    │  ◀────────────────────────────────────    │  - ApiAuthGuard (JWT)      │
│                             │         JSON 응답                          │  - 도메인별 모듈           │
│  Repository 3계층 합성:       │                                          └────────────┬─────────────┘
│   Local  (JSON/파일 영속)    │                                                       │ Prisma ORM
│   Remote (APIClient→서버)    │                                                       ▼
│   OfflineFirst (Local+Remote)│                                          ┌──────────────────────────┐
│                             │   ※ 로컬 저장은 CoreData 아님             │  PostgreSQL 16            │
│  Keychain: JWT 세션 저장     │      (JSON/FileManager 기반)              │  - Prisma 마이그레이션 20개│
└─────────────────────────────┘                                          │  - 24 테이블              │
                                                                          │  - docker: knitgether-postgres │
                                                                          └──────────────────────────┘
```

- **클라이언트**: 네이티브 iOS(SwiftUI). UI 자동화는 XCUITest. 로컬 저장은 CoreData가 아니라 **파일/JSON 영속 + Repository 패턴**.
- **서버**: NestJS. 인증 가드 `ApiAuthGuard`(Bearer JWT → userId 매핑). 도메인 모듈(auth/profile/projects/library/patterns/skills/dictionary/gauge-*).
- **DB**: PostgreSQL 16 + Prisma. 소프트 삭제(`deletedAt`), 유저별 격리(`ownerId`).
- **모드 전환**: `AppRepositoryContainer`가 env `KNITGETHER_API_BASE_URL` 유무로 Local 모드 / API 모드를 조립한다. env 없으면 로컬 전용(오프라인), 있으면 offline-first.

---

## 2. 데이터 흐름 — 오프라인 우선(offline-first) 동기화

핵심 규칙: **로컬이 먼저 응답하고, 원격은 뒤따른다.** 각 도메인은 `OfflineFirstXxxRepository`가 `Local`+`Remote`를 합성한다.

### 쓰기(생성/수정/삭제) 흐름
```
사용자 조작
  └─▶ 1) 로컬 저장소에 즉시 반영 (syncStatus = localOnly 또는 pendingUpload)
      └─▶ 2) 원격(서버) 저장 시도
            ├─ 성공 ─▶ syncStatus = synced (UI 배지 숨김)
            └─ 실패 ─▶ pending 상태로 보존 후, 재조회/재시도 시 다시 업로드
                       (부모-자식 관계는 부모를 pending으로 보존: 예 Project→RowCounter/WorkSession)
삭제
  └─▶ 로컬 pendingDelete → 원격 삭제 성공 시 로컬에서 제거
```

### 읽기 흐름 (서버 OFF 대비)
```
목록 조회
  ├─ 서버 ON  ─▶ 원격 조회 → 로컬 캐시 갱신 → 표시
  └─ 서버 OFF ─▶ 원격 실패 → 로컬 캐시로 표시
                 (캐시 없음 + 서버 OFF ─▶ "오프라인 안내" 표시)
```

### syncStatus — 5상태 (단, 1개는 미구현)
| 상태 | 표시 | 의미 |
|---|---|---|
| `localOnly` | 이 기기에만 있음 | 서버 미반영 |
| `pendingUpload` | 업로드 대기 | 원격 반영 대기 |
| `synced` | (배지 숨김) | 서버 저장 완료 |
| `pendingDelete` | 삭제 대기 | 삭제가 원격 미반영 |
| `conflict` | 충돌 | ⚠️ **정의만 존재, 미구현** — 어떤 리포지토리도 이 상태로 전이시키지 않음 |

### 충돌 처리 — **현재 없음** (QA가 꼭 알아야 할 약점)
- 클라이언트: `conflict` 상태로 가는 전이 로직이 **없다**.
- 서버: 낙관적 잠금(version)·`If-Match`가 **없다**. 동일 리소스 동시(순차) 수정은 **last-write-wins**로, 선행 변경이 무통보 유실된다(→ Issue #14).
- 즉 "충돌 시 처리"는 설계엔 있으나 **구현되지 않은 영역**이다. 관련 검증은 `qa/api-tests`의 negative test로 현 동작(last-write-wins)을 감시 중.

---

## 3. API 엔드포인트 전체

- 공통 prefix: `/api/v1`. 예: `/api/v1/projects`.
- 인증: `Authorization: Bearer <accessToken>`. **아래 표의 "인증"이 ✅면 토큰 필수**, ⬜면 공개.
- 토큰 발급: `POST /auth/register` 또는 `/auth/login` 응답의 `accessToken`.

| 메서드 | 경로 | 인증 | 설명 |
|---|---|:---:|---|
| GET | `/health` | ⬜ | 헬스체크 |
| POST | `/auth/register` | ⬜ | 회원가입(→ accessToken) |
| POST | `/auth/login` | ⬜ | 로그인(→ accessToken) |
| GET | `/auth/me` | ✅ | 현재 계정/프로필 |
| GET | `/profile` | ✅ | 프로필 조회 |
| PATCH | `/profile` | ✅ | 프로필 수정 |
| GET | `/projects` | ✅ | 프로젝트 목록 |
| POST | `/projects` | ✅ | 프로젝트 생성(upsert, client UUID) |
| GET | `/projects/:id` | ✅ | 프로젝트 상세 |
| PATCH | `/projects/:id` | ✅ | 프로젝트 수정(전체 객체) |
| DELETE | `/projects/:id` | ✅ | 프로젝트 삭제(soft) |
| PATCH | `/projects/:id/row-counter` | ✅ | 단수 카운터 |
| POST/PATCH/DELETE | `/projects/:id/row-instructions[/:instructionId]` | ✅ | 행안내 CRUD |
| GET/POST/PATCH/DELETE | `/projects/:id/work-sessions[/:sessionId]` | ✅ | 작업 세션 |
| GET/POST/PATCH/DELETE | `/projects/:id/yarn-usages[/:usageId]` | ✅ | 실 사용 기록 |
| GET/POST/PATCH/DELETE | `/projects/:id/progress-photos[/:photoId]` | ✅ | 진행 사진(+ `/file`) |
| GET/POST/DELETE | `/projects/:id/pattern-copy/file`·`/drawing` | ✅ | 도안 사본/그림 |
| GET | `/skills`, `/skills/:id` | ✅ | 스킬 목록/상세(시스템+개인 병합) |
| POST | `/skills` | ✅ | 개인 스킬 생성 |
| PATCH | `/skills/:id/level` | ✅ | 스킬 이해도 저장 |
| PATCH/DELETE | `/skills/:id` | ✅ | 개인 스킬 수정/삭제(시스템 스킬은 403) |
| GET | `/skill-animations` | ✅ | 뜨개 애니메이션 데이터 |
| GET | `/dictionary-terms`, `/dictionary-terms/:id` | ✅ | 사전 목록/상세(시스템+개인 병합) |
| POST/PATCH/DELETE | `/dictionary-terms[/:id]` | ✅ | 개인 용어 CRUD(시스템 용어는 403) |
| GET/POST/PATCH/DELETE | `/library/yarns[/:id]` (+ `/yarns/:id/usages`) | ✅ | 실 창고 |
| GET/POST/PATCH/DELETE | `/library/needles[/:id]` | ✅ | 바늘 창고 |
| GET/POST/PATCH/DELETE | `/library/tools[/:id]` | ✅ | 도구 창고 |
| GET/POST/DELETE | `/library/projects/:projectId/tools[/:toolId]` | ✅ | 프로젝트-도구 연결 |
| GET/POST/PATCH/DELETE | `/patterns[/:id]` (+ `/:id/file`) | ✅ | 도안 문서 |
| GET/POST/PATCH/DELETE | `/gauge-records[/:id]` | ✅ | 게이지 기록 |
| GET/POST/PATCH/DELETE | `/gauge-targets[/:id]` | ✅ | 게이지 목표(+스와치/측정) |

> 인증 정책: `/health`와 `/auth/register`·`/auth/login`을 제외한 **모든 라우트가 클래스 레벨 `ApiAuthGuard`로 보호**된다. `/auth/me`만 auth 컨트롤러 내 메서드 레벨 인증.
> 전체 계약(요청 DTO 필드)은 `docs/qa/postman/knitgether-local.postman_collection.json` 및 각 `*.dto.ts` 참조.

---

## 4. 기능별 구현 상태

### 핵심 기능 (기획 유지분, 구현 완료)
| 기능 | 상태 | 비고 |
|---|:---:|---|
| 온보딩(계정→스킬테스트→단위→완료) | ✅ 완료 | |
| 프로젝트 CRUD (CO/WIP/UFO/FO) | ✅ 완료 | |
| 작업 공간(2탭: 뜨는 중/정보), 단수 카운터, 행안내 | ✅ 완료 | |
| 창고(실/바늘/도구/도안/스킬) | ✅ 완료 | |
| 뜨개 사전(조회·검색·상세, 읽기 전용) | ✅ 완료 | 시스템 용어 §23 18종 seed |
| 스킬(CRUD, 이해도 몰라요/헷갈려요/잘알아요) | ✅ 완료 | 시스템 스킬 41종(§22 15 필수 포함) |

### v2.3 §C — 초과 구현 8건 (기획 초과, 스펙으로 인정됨)
| # | 기능 | 상태 | 비고 |
|---|---|:---:|---|
| C-1 | 오프라인 동기화(syncStatus) | 🟡 부분 | 4상태 순환은 동작. **conflict 상태 미구현**(§2, #14) |
| C-2 | 계정 인증(JWT register/login/me) | ✅ 완료 | Keychain 세션 |
| C-3 | 데이터 백업(JSON 내보내기/가져오기) | ✅ 완료 | 실기기 공유시트 의존 |
| C-4 | 작업시간 통계 | 🟡 부분 | 집계는 동작하나 시간 역전 세션에 취약(#15) |
| C-5 | 뜨개 애니메이션 재생 | ✅ 완료 | 스킬별 프레임 플레이어 |
| C-6 | 진행 사진 | 🟡 부분 | Remote 직접 연결, offline-first는 알려진 제한 |
| C-7 | 게이지 측정 도구 | 🟡 부분 | 계산기·기록·측정 있음. §21 "도안 vs 내 게이지 비교·조언"은 미구현 |
| C-8 | OCR 행안내 | ✅ 완료 | 작업 공간 행안내에 편입 |

### 미구현 (v2.3 §E — 범위 외)
뜨개 레벨(사용자 등급), 프로젝트 썸네일, **§21 게이지 도안-비교·조언**, 소셜 로그인, 온보딩 건너뛰기, 정렬/즐겨찾기 필터, CO 세부 단계, JPG/PNG 도안(PDF/스캔만), 햅틱 피드백, **syncStatus conflict 처리**.

---

## 5. 실행 방법

### 5-1. 백엔드 서버
```bash
cd server
docker compose up -d                 # PostgreSQL 16 (컨테이너 knitgether-postgres, 포트 5433)
cp .env.example .env                  # 최초 1회. 값 확인/설정
npx prisma migrate deploy             # 마이그레이션 20개 적용
npm run seed                          # 시스템 스킬/사전 seed (멱등)
npm run start:dev                     # 서버 기동 → http://127.0.0.1:3000/api/v1
# 헬스체크: curl http://127.0.0.1:3000/api/v1/health  → 200
```

### 5-2. iOS 앱 빌드/실행
```bash
# 시뮬레이터 (API 모드로 로컬 서버 연결)
xcodebuild build \
  -project KnitGether.xcodeproj \
  -scheme "KnitGether Local Simulator" \
  -destination "platform=iOS Simulator,id=<iPhone 16 Pro UDID>"
```
- 스킴: `KnitGether Local Simulator`(시뮬레이터+API), `KnitGether Local Device`(실기기), `KnitGether Local Offline`(로컬 전용), `KnitGether`(기본).
- 검증 환경: iPhone 16 Pro 시뮬레이터, iOS 18.5. 실기기는 iPhone 16 Pro / iOS 26.5(로컬 네트워크 API).
- 앱이 서버에 붙으려면 스킴이 `KNITGETHER_API_BASE_URL`을 설정한다(Local Simulator/Device 스킴).

### 5-3. 테스트 계정 / 인증
- **회원가입으로 즉석 생성**(권장): `POST /auth/register` `{ "email", "password"(≥8자), "displayName"?, "preferredUnits"? }` → `accessToken`.
- UI 자동화 관례: `ui-flow-<timestamp>@example.com`, 비밀번호 `password-1234`.
- 정적/개발 토큰: `KNITGETHER_API_TOKENS`(정적), `DEV_AUTH_TOKEN`/`DEV_AUTH_USER_ID`(개발/테스트 전용).

### 5-4. DB 접속 (로컬 개발)
```
Host: localhost   Port: 5433   DB: knitgether_dev
User: knitgether  Password: knitgether
URL: postgresql://knitgether:knitgether@localhost:5433/knitgether_dev
psql: docker exec -it knitgether-postgres psql -U knitgether -d knitgether_dev
리셋: npm run db:reset-test   (system 프로필 제외 사용자 데이터 초기화)
```

### 5-5. 기존 테스트 자산 (참고 — QA가 TC를 새로 설계할 대상)
- 서버 e2e(Jest): `cd server && npm test` — ⚠️ 현재 `dictionary.e2e-spec` 5/7 red(#17, 선행 결함). **green 게이트로 쓰지 말 것.**
- API 정합성(pytest): `cd qa/api-tests && pytest` — 실 Postgres 대상. 현재 10 passed / 1 skipped.
- iOS XCUITest: `KnitGether Local Simulator` 스킴으로 `xcodebuild test`. 현재 전체 355/355 통과(워커 2 권장 — 클론 flake 회피).

---

## 6. 알려진 이슈 · 미완성 영역 (개발자가 아는 약점)

### GitHub Issues (열림)
| # | 심각도 | 요약 |
|---|---|---|
| #9 | high | 백그라운드 진입/강제 종료 시 진행 중 작업 세션 유실 |
| #14 | high | 동시 수정 충돌 감지 없음 — last-write-wins 무통보 유실(서버 version 없음) |
| #10 | medium | 작업 타이머 수동 정지 후 재진입 시 자동 재시작(원 기획 §13 위반) |
| #15 | medium | 서버가 시간 역전 WorkSession(`endedAt < startedAt`) 수용 → 작업시간 통계 오염(음수/과소집계) |
| #16 | low | PATCH 수정이 부분 수정 미지원 — 전체 객체 요구(full-replace), 스펙 미정의 |
| #17 | low | `dictionary.e2e-spec` 5/7 실패 — dev-token이 `DEV_AUTH_USER_ID` 미반영, `dev-user`로 매핑(선행, 테스트 하네스) |

> #11(seed)·#12(DEF-006 프로필 401)·#13(DEF-007 테스트 격리)은 해결·verified·Close 완료.
> #1~#7은 초기 기획 단계의 feature 스텁 티켓(라벨 없음) — 현행 상태와 무관할 수 있으니 트리아지 필요.

### 구조적 약점 / 주의점
- **동시성/충돌 보호 없음**: `syncStatus.conflict`는 정의만 있고 클라이언트·서버 모두 전이 로직이 없다. 다중 기기/오프라인 복구 시 last-write-wins로 데이터가 조용히 덮인다(#14).
- **교차 필드 검증 공백**: WorkSession 시간 구간 유효성(#15) 등 서버 입력 검증에 빈틈. `PATCH`가 실제로는 full-replace(#16).
- **소프트 삭제 + 수동 cascade**: 삭제는 hard delete가 아니라 서비스가 `deletedAt`을 부모·자식에 수동 전파. cascade 누락 여부는 테스트 대상.
- **iOS 로컬 저장은 CoreData 아님**: 기획서(v2.2)와 달리 JSON/파일 기반. 스펙 기준 테스트 시 v2.3을 따를 것.
- **진행 사진**은 완전한 offline-first가 아님(Remote 직접 연결, 알려진 제한).
- **테스트 위생**: 일부 자동화 테스트가 데이터를 seed만 하고 teardown이 없어 DB에 잔재가 쌓인다(예: 사전 UI 테스트의 `TERM*` 용어). QA 실행 시 `db:reset-test`로 클린 슬레이트 확보 권장.
- **서버 e2e의 태반이 mock Prisma**: 12개 중 9개가 인메모리 mock이라 실 DB 정합성은 pytest 계층(`qa/api-tests`)이 담당한다.

---

_이 문서는 시스템 이해를 돕는 사실 정리다. 리스크 우선순위·테스트 범위·릴리즈 판정은 QA가 결정한다._
