# KnitGether 스펙 v2.3

> **이 문서가 스펙의 정본(正本)이다.** 포트폴리오 리뷰어는 Notion에 접근하지 못하므로, 리포 내 이 파일이 요구사항의 기준 문서가 된다.
>
> **정본 근거 주의**: 본 v2.3은 (a) 실제 구현 코드, (b) QA 전수 감사 결과(`docs/qa/portfolio/PROJECT_HISTORY.md`, `03_feature_inventory.md`, `docs/superpowers/specs/*`), (c) 판정 1a에 따른 개정 지시를 근거로 재구성했다. Notion 기획서 v2.2 원문은 이 리포에 포함되어 있지 않으므로, v2.2와의 1:1 조항 번호 대응이 필요한 경우 작성자(유하)가 Notion v2.2와 교차 확인한다.

---

## 변경 이력

| 버전 | 일자 | 변경 내용 | 근거 |
|---|---|---|---|
| v2.2 | (Notion) | 이전 기획 기준선 | — |
| **v2.3** | **2026-07-29** | **QA 전수 감사 결과를 반영해 "코드를 현실로 인정, 기획서 개정"(판정 1a) 적용** | 아래 |

### v2.3에서 무엇이 왜 바뀌었나 (포트폴리오 증거)
- **판정**: 기획서 v2.2 대비 구현 감사 결과, 구현이 기획을 상당 부분 초과·변형했음이 확인됨. "코드를 되돌려 기획에 맞추기"가 아니라 **"구현 현실을 스펙으로 인정하고 v2.3으로 개정"(1a)**으로 확정.
- **아키텍처 현행화**: 서버+PostgreSQL+오프라인 동기화 구조와 5탭 구성을 실제 구현대로 기술(§A).
- **초과 구현 8건 공식 편입**: 계정 인증, 오프라인 동기화, 백업, 작업시간 통계, 애니메이션 재생, 진행 사진, 게이지 측정 도구, OCR 행안내(§C). 이 중 동기화·인증은 테스트 근거 조항이 되므로 상세 기술.
- **미구현 항목 명시화**: 기획엔 있으나 미구현인 항목을 "v2.3 범위 외"로 항목별 확정(§E).
- **감사 중 발견된 완료기준 위반**은 별도 GitHub Issue로 이관(§D + 이슈 트래커).
- **불일치 정정 예시**: 기획서상 동기화 상태 "4상태" 언급 → 실제 구현은 **5상태**(§C-1). 코드=현실 원칙에 따라 5상태로 확정.

---

## A. 아키텍처 (현행화)

### A-1. 서버 + PostgreSQL + 오프라인 동기화 구조
- **클라이언트**: 네이티브 iOS 앱(SwiftUI, 배포 타겟 iOS 16). UI 자동화는 XCUITest.
- **서버**: NestJS(TypeScript). REST API 프리픽스 `/api/v1`. 인증 가드 `ApiAuthGuard`(Bearer 토큰 → userId 매핑).
- **DB**: PostgreSQL 16 + Prisma ORM. 마이그레이션 19개(`server/prisma/migrations/`). 스키마 24 테이블.
- **동기화 모델**: 오프라인 우선(offline-first). 각 로컬 저장소가 먼저 응답하고 원격을 시도하며, 실패 시 pending 상태로 보존 후 재시도. 데이터는 `ownerId`로 유저별 격리.

### A-2. 5탭 TabView
`ContentView`의 `TabView`가 5개 탭을 구성한다.
1. **홈** — 대시보드(프로젝트 통계·이어서 뜨기·최근 작업)
2. **내 뜨개** — 프로젝트 목록 + 작업 공간(Workspace)
3. **창고** — 실·바늘·도구·도안·스킬 라이브러리
4. **도구** — 게이지 계산기·스킬 테스트·뜨개니게이션·뜨개 사전·뜨개 애니메이션
5. **설정** — 계정 연동·프로필 편집·작업시간 통계·작업 세션 목록·데이터 백업·데이터 관리

### A-3. 저장소(Repository) 계층
프로토콜 기반 3계층 합성:
- `LocalXXXRepository` — 파일/CoreData 기반 오프라인 저장
- `RemoteXXXRepository` — `APIClient`로 서버 호출
- `OfflineFirstXXXRepository` — Local+Remote 합성(로컬 저장 → 원격 시도 → 실패 시 pending·롤백)
`AppRepositoryContainer`가 환경변수(`KNITGETHER_API_BASE_URL`)로 Local/API 모드를 결정해 조립한다.

### A-4. 인증 / 세션
- 회원가입·로그인은 서버 전용(`POST /auth/register`·`/auth/login`) → AccessToken(JWT) 발급.
- 토큰은 Keychain(`AuthSessionStore`)에 저장, `APIClient.authTokenProvider`가 요청마다 주입.
- 정적/개발 토큰 폴백: `KNITGETHER_API_TOKENS`(정적), `DEV_AUTH_TOKEN`(개발/테스트 전용, `NODE_ENV` 조건).
- 실기기 단독 실행(아이콘 탭) 시 스킴 env가 없어 서버 주소 폴백 로직 존재(`AppRepositoryContainer.apiBaseURL`, 시뮬레이터는 env-only 유지).

### A-5. 동기화 실행 메커니즘
- 401(인증 실패) 응답 시 `authFailureHandler`가 세션을 정리(단, 최신 세션 보호는 이슈 참고).
- pending 상태 데이터는 재조회/재시도 시 원격 반영. 부모-자식(예: Project→RowCounter/WorkSession) 실패는 부모 pending으로 보존.
- 서버 저장 상태를 `syncStatus`(§C-1, 5상태)로 표현하고 UI 배지로 노출(동기화 완료 시 배지 숨김).

---

## B. 핵심 기능 스펙 (기존 기획 유지분)

| 기능 | 화면 | 주요 동작 | API / DB |
|---|---|---|---|
| 온보딩 | OnboardingView | 계정 단계 → 스킬 테스트 → 단위 → 완료(프로필 저장) | `PATCH /profile` |
| 프로젝트 CRUD | MyKnittingView, Add/EditProject | 생성·수정·삭제·상태(CO/WIP/UFO/FO) | `/projects` / `Project` |
| 작업 공간 | ProjectWorkspaceView (2탭: 뜨는 중/정보) | 단수 카운터, 행안내, 도안 뷰, 작업 타이머 | 하위 API 다수 |
| 단수 카운터 | Workspace | 현재/목표 단수, 간편/행안내 모드 | `PATCH /projects/:id/row-counter` / `RowCounter` |
| 행안내 | Workspace | 단별 지시 생성·수정·삭제·일괄 | `/projects/:id/row-instructions` / `RowInstruction` |
| 창고(재료) | Yarn/Needle/Tool LibraryView | 실·바늘·도구 CRUD | `/library/*` / `Yarn`,`Needle`,`ToolItem` |
| 도안 | PatternLibraryView | PDF 가져오기/스캔·수정·삭제 | `/patterns` / `PatternDocument`,`StoredFile` |
| 사전 | KnitDictionaryView | 용어 조회·검색·상세(읽기 전용) | `/dictionary-terms` / `DictionaryTerm` |
| 스킬 | SkillLibraryView, SkillTest | 스킬 CRUD, 레벨(몰라요/헷갈려요/잘알아요) | `/skills`,`/skills/:id/level` / `Skill`,`UserSkillLevel` |

---

## C. 초과 구현 8건 (v2.3 공식 편입)

기획 대비 추가로 구현된 8개 기능을 스펙으로 인정한다.

### C-1. 오프라인 동기화 (⭐ 테스트 근거 조항)
- **`syncStatus`는 5상태**(구현 `SyncStatus` enum):
  | 상태 | 표시 | 의미 |
  |---|---|---|
  | `localOnly` | 이 기기에만 있음 | 서버 미반영, 이 기기에만 저장 |
  | `pendingUpload` | 업로드 대기 | 원격 반영 대기 중 |
  | `synced` | (배지 숨김) | 서버 저장 완료 |
  | `pendingDelete` | 삭제 대기 | 삭제가 원격 미반영 |
  | `conflict` | 충돌 | 로컬/원격 불일치 (⚠️ **정의만 존재 — 미구현**, 아래 참조) |
- **⚠️ conflict 상태는 정의만 존재하고 전이 로직이 없다 (2026-07-29 검증)**: `SyncStatus` enum과 `SyncStatusBadgeView` 렌더 케이스에만 있고, **클라이언트(어느 OfflineFirst 리포지토리도 `.conflict`를 대입하지 않음)·서버(스키마에 `version`/`syncStatus` 없음, `updateProject`는 last-write-wins) 모두 충돌 감지·전이 로직 미구현**이다. 즉 현 구현에서 도달 불가능한 상태다. 서버측 공백은 **[Issue #14](../../issues/14)**(동시 수정 충돌 감지 없음, `severity/high`)로 이관.
- **오프라인 우선**: 서버 OFF 상태에서도 로컬 캐시로 조회·생성 가능, 서버 복구 시 pending 항목 동기화.
- **유저 격리**: 모든 도메인 데이터는 `ownerId` 스코프. 계정 전환 시 캐시 분리.
- **완료 기준**: 서버 OFF→생성→서버 ON 복구 후 재조회 시 pending 데이터가 원격 반영되어야 한다. 서버 OFF+캐시 없음 시 오프라인 안내를 표시해야 한다.
- **기획 대비 정정**: v2.2의 "4상태" 언급 → **5상태로 확정**. 단 5번째 상태(`conflict`)는 위와 같이 정의만 존재.

### C-2. 계정 인증 (⭐ 테스트 근거 조항)
- 회원가입/로그인/세션 유지. `POST /auth/register`·`/auth/login`(AccessToken), `GET /auth/me`(세션 확인).
- 토큰 Keychain 저장, 요청마다 Authorization 헤더 주입.
- **완료 기준**:
  - 회원가입 직후 온보딩 완료(프로필 저장)까지 인증이 유지되어야 한다.
  - 로그아웃 후 인증 필요 프로필 fetch를 수행하지 않아야 한다(오류 미노출).
  - 잘못된 비밀번호 로그인 시 세션이 저장되지 않아야 한다.

### C-3. 데이터 백업
- 설정 → 데이터 백업. JSON 내보내기/가져오기(공유 시트/파일 피커 의존, 실기기 대상).

### C-4. 작업시간 통계
- 설정 → 작업시간 통계. 총 작업/오늘/세션 수/평균, 프로젝트별 집계, 최근 세션 목록.

### C-5. 뜨개 애니메이션 재생
- 도구 → 뜨개 애니메이션. 스킬별 단계 설명 + 프레임 플레이어(예: "K 기본 프레임 1/3").

### C-6. 진행 사진
- 작업 공간 → 진행 사진 추가(카메라/앨범, 시스템 피커 의존). `/projects/:id/progress-photos` / `ProjectProgressPhoto`.

### C-7. 게이지 측정 도구 (실물 검증 2026-07-29)
- 도구 → 게이지 계산기. **실제 구현 흐름**: 내 스와치 입력(가로/세로 cm, 코/단 수) + 목표 완성 크기(cm) → **① 10cm 기준 게이지 환산 ② 목표 크기에 필요한 예상 코/단 수 역산**을 출력한다.
- 세탁 전/후 게이지를 분리 저장·비교(`GaugeRecord`), 목표 게이지(`GaugeTarget`)·스와치(`GaugeSwatch`)·수동 측정(`GaugeMeasurement`) 관리.
- **주의(§21 대비)**: 이 계산기는 "내 게이지 → 목표 완성 크기 역산기"이며, v2.2 **§21의 "도안 게이지 vs 내 게이지 비교 + 촘촘/느슨 조언"** 흐름과는 **다른 기능**이다. §21의 도안-비교·조언 서브기능은 미구현(§E 참조).

### C-8. OCR 행안내
- 도안 보며 행안내 입력 지원(도안 텍스트 참조). 작업 공간 행안내 흐름에 편입.

---

## D. 완료 기준 (Completion Criteria) — 감사 위반 반영

아래 조항은 §32 완료기준을 현행화한 것이며, 위반 3건은 GitHub Issue로 이관되었다(§ 이슈 트래커).

- **CR-1 (작업 세션 지속성)**: 진행 중인 작업 세션은 앱 백그라운드 진입/강제 종료 시에도 유실되지 않아야 한다. → **위반: [Issue #9](../../issues/9)**
- **CR-2 (작업 타이머 재진입)**: 사용자가 타이머를 **수동 정지**한 뒤 화면을 재진입해도 자동 재시작하지 않아야 한다(원 기획 §13). → **위반: [Issue #10](../../issues/10)**
- **CR-3 (Seed 데이터)**: 신규 사용자/환경이 기획에 명시된 기본 스킬·사전 데이터를 갖춰야 한다(스킬 15, 사전 18 등). 서버 seed 스크립트가 존재해야 한다. → **위반: [Issue #11](../../issues/11)**
- **CR-4 (인증 지속성)**: §C-2 완료 기준 관련 증상은 **DEF-006 → [Issue #12](../../issues/12)** (해결·verified, 근본원인은 테스트 하네스).
- **CR-5 (테스트 격리)**: e2e 테스트가 환경 `.env`에 오염되지 않아야 한다 → **DEF-007 → [Issue #13](../../issues/13)** (해결·verified).

---

## E. v2.3 범위 외 (미구현 확정)

기획엔 존재하나 v2.3 시점 미구현. 향후 버전 후보로만 남긴다.

| 항목 | 상태 | 비고 |
|---|---|---|
| 뜨개 레벨(사용자 등급) | 미구현 | 스킬 레벨(몰라요/헷갈려요/잘앎)과 별개의 사용자 종합 등급 |
| 썸네일 / 사진(프로젝트 대표 이미지) | 미구현 | 진행 사진(C-6)과 별개 |
| **§21 게이지 도안-비교·조언** (도안 게이지 vs 내 게이지 → 촘촘/느슨 판단 + 바늘 조정 제안) | 미구현 (실물 검증 2026-07-29) | 게이지 **계산기 자체는 구현됨**(§C-7, 내 게이지→목표 크기 역산). §21의 "도안 대비 비교·조언" 서브기능만 미구현. ⚠️ dev-log §16회차엔 "비교 구현"으로 기록됐으나 실물은 세탁 전후 비교였음 — 개발 로그와 실물의 괴리를 독립 검증으로 확인한 사례 |
| 소셜 로그인 | 미구현 | 이메일/비번 인증만 구현 |
| 온보딩 건너뛰기 | 미구현 | 온보딩 필수 진행 |
| 정렬 / 즐겨찾기 필터 | 미구현 | 상태 필터(CO/WIP/UFO/FO)만 존재 |
| CO 상태 분리(세부 단계) | 미구현 | CO 단일 상태로 처리 |
| JPG / PNG 도안 | 미구현 | PDF·문서 스캔만 지원 |
| 햅틱 피드백 | 미구현 | — |

---

## 부록 1. DB 스키마 (24 테이블)
UserAccount, UserProfile, Project, RowCounter, RowInstruction, WorkSession, ProjectPatternCopy, ProjectProgressPhoto, ProjectToolLink, ProjectYarnUsage, PatternDocument, StoredFile, Yarn, Needle, ToolItem, GaugeRecord, GaugeTarget, GaugeSwatch, GaugeMeasurement, Skill, SkillAnimation, UserSkillLevel, DictionaryTerm, _prisma_migrations

## 부록 2. 화면 ↔ API ↔ DB 매핑
상세 매핑은 `docs/qa/portfolio/03_feature_inventory.md`를 정본과 함께 참조.

## 부록 3. 클린 기동(재현) 절차
1. `cd server && docker compose up -d` (PostgreSQL)
2. `.env`는 `.env.example` 복사 후 값 설정
3. `npx prisma migrate deploy` (또는 `prisma:migrate`)
4. `npm run start:dev` (서버) / `npm run test:e2e` (e2e 105)
5. iOS: `KnitGether Local Simulator` 스킴으로 실행
