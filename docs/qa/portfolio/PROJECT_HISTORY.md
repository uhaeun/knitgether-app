# KnitGether QA 포트폴리오 프로젝트 전체 히스토리 (2026-07-19 ~ 진행 중)

> 이 문서는 QA 포트폴리오 준비 과정 전체를 시간 순으로, 빠짐없이 정리한 기록이다.
> 목적: (1) 이력 파악 (2) 앱 아키텍처 학습 자료 (3) 면접에서 "어떤 문제를 만나 어떻게 풀었는지" 답할 수 있는 근거.
> 대상 리포: `github.com/uhaeun/knitgether-app` (private). 서버: NestJS+Prisma. 앱: SwiftUI+CoreData.

---

## 0. 왜 이 프로젝트를 시작했는가

사용자는 DB QA(DBMS 패치/복구/정합성 검증, JMeter 부하테스트, PyAutoGUI 자동화, 대규모 시나리오 관리, 이슈 트래커 결함관리) 경력자로, 앱 QA 직무로 전환하기 위한 포트폴리오가 필요했다. 부트캠프식으로 "남의 앱"을 잡고 TC만 몇십 개 쓰는 흔한 포트폴리오와 차별화하기 위해, **본인이 직접 기획·개발한 iOS 앱(KnitGether)을 QA 프로세스 전체(요구사항 리뷰 → 리스크 기반 계획 → TC 설계 → 실행 → 결함관리 → 릴리즈 판단)로 검증**하는 방향을 잡았다.

핵심 차별화 포인트로 초기에 합의한 것:
- **UI–API–DB 3개 레이어 데이터 정합성 검증** (DB QA 경력이 직접 이어지는 지점)
- **AI 협업 지표 측정** (AI 제안 채택률/폐기율, 사람이 추가한 TC 비율 등 — 사용자가 스스로 제안한 아이디어)
- QA 도구(Postman/Appium/CI)는 **사람이 직접 손으로 만들어야** 면접에서 방어 가능하다는 원칙

---

## 1. 협업 방식이 어떻게 자리잡았는가 (매우 중요한 이력)

### 1.1 첫 시행착오: Claude가 판단까지 대신 채움
초기에 Claude가 문서 템플릿을 만들면서 리스크 등급(P0/P1/P2) 같은 **판단이 필요한 내용까지 미리 채워 넣는** 실수를 여러 번 했다. 사용자가 "너가 다 해주면 내가 뭐 한게 되는데?"라고 지적하면서 역할 분담 원칙이 확정됐다:

- **판단(리스크 등급, TC 기대결과, 결함 심각도, 릴리즈 Go/No-Go)은 사용자가 직접**
- **템플릿/사실조사/코드 조사/리뷰는 Claude가**
- 완성된 산출물에 대해 Claude는 "QA 리드처럼" 지적하는 리뷰어 역할
- 예외: 밤 시간 CS 공부는 Claude가 적극적으로 가르쳐도 됨 (개념 설명 → 사용자가 자기 앱 사례로 재설명 → 꼬리질문)
- 나중에 QA 도구(Postman/Appium/CI)에도 같은 원칙이 적용됨 — "이건 내가 직접 해봐야 하는 거 아니야?"라는 사용자의 자각으로 Codex/Claude가 앱만 안정화하고 도구는 사람이 만드는 것으로 최종 확정

### 1.2 커뮤니케이션 스타일
사용자는 ADHD가 있어 다음이 확정됨:
- 응답은 짧게, 표 남발 금지
- 압도된 신호("뭐부터 해야할지 모르겠어")가 오면 옵션을 주지 말고 **가장 작은 행동 1개만** 제시
- 다이어리(종이)에 손으로 오늘 할 일을 적고 체크 — 노션은 Claude가 참고하는 백로그/운영 문서로 용도 분리
- 노션 "Week Plan" 페이지가 최종적으로 이 역할을 함 (원래 있던 "열심히살기" 페이지는 사용자가 정리/삭제)

### 1.3 노션 구조가 여러 번 바뀐 과정
1. 처음엔 "QA 포트폴리오 실행 계획" 페이지를 새로 만듦
2. 사용자가 기존 "열심히살기" 페이지(7주치 상세 계획 있음)를 알려주며 그쪽으로 통합
3. Codex 관련 대응 도중 실수로 페이지 내용 일부가 삭제됐다가 즉시 백업으로 복원 (Notion API의 `replace_content`가 위험할 수 있음을 학습)
4. 사용자가 "Week 탭엔 할 일만, 산출물은 이직 탭에" 요청 → 별도 "📅 Week Plan" 페이지 신설
5. 사용자가 "너무 구체적으로 써놓으니 뭘 해야할지 모르겠다" → 용어를 전부 풀어쓴 버전으로 재작성 (Quality Bar → "출시 조건", RTM → "기능·테스트·버그 연결하는 표" 등)
6. 하루 리듬(🌅 판단 · ☀️ 실행 · 🌙 공부) 도입, 7/20~8/9 사이 실제 공부 가능 시간대(9~11, 12~18, 21~23시)에 맞춰 데일리 플랜 재작성
7. 최종적으로 "Week Plan 페이지 = Claude가 읽는 운영 문서, 사용자는 종이 다이어리로 관리"로 역할 분리 확정. 이 페이지엔 날짜별 계획, 산출물 리뷰 기준, 미해결 트래커, 일정 밀릴 때 자를 순서까지 담음

---

## 2. 기획 문서 체계 (docs/qa/portfolio/)

### 2.1 최초 설계 (7/19)
- `00_TOC.md` — 목차 v1 (프로젝트 개요, 아키텍처, 테스트 범위, 리스크 전략, RTM, TC, 수동 E2E, API 테스트, UI 자동화, 결함, 결과 요약, 회고)
- `GUIDE_how_to_write.md` — 문서별 "생각하는 순서 + 나쁜예/좋은예 + 스스로 점검 질문" (사용자가 직접 쓸 때 참고하는 가이드)
- `01_baseline_status_2026-07-19.md` — 베이스라인 기록 (리포/커밋/구조/테스트 수치)
- `02_project_goal.md`, `03_feature_inventory.md` — 프로젝트 목표/기능 목록·리스크 등급 템플릿 (사용자가 채우도록 비워둠)

### 2.2 목차 v2로 확장 (Appium 범위 확장 결정 이후)
목표 회사들이 요구하는 QA 역량표에 맞춰 15개 절 구조로 확장. 핵심 추가: Quality Bar(품질 기준), XCUITest vs Appium 비교표, CI 품질 게이트, 성능 Smoke(JMeter), 결함 생명주기.

### 2.3 Codex가 실제로 채운 문서 (7/19 밤 ~ 7/20)
사용자가 Codex(ChatGPT)에게 병행 작업을 시켰고, Codex가 다음을 작성:
- `04_pom_screen_success_failure_criteria.md` — POM 화면별 PASS/FAIL 판정 기준, 공통 판정 규칙(PASS/FAIL/ENV_ISSUE/NEED_SPEC_CONFIRM)
- `05_test_plan_2026-07-19.md` — 테스트 계획서 (범위/제외범위/리스크등급/환경매트릭스/Entry-Exit Criteria/결함 처리 규칙)
- `06_smoke_test_cases.md` — 스모크 TC 15개 (Happy Path/Negative/Boundary/State Transition/Persistence/Offline/API-DB 태그)
- `evidence/0719_qa_round_1_execution.md` — 1회차 실행 리포트 (2026-08-27 이동, 원래 `07_qa_round_1_execution_2026-07-19.md`)

**중요한 지점**: Codex가 `02_project_goal.md`, `03_feature_inventory.md`의 **판단 내용(리스크 등급 P0/P1/P2)까지 채워버림**. 이는 원래 "사용자가 직접 판단"하기로 한 영역이라, Claude가 검토하며 "이 등급표를 그대로 쓰지 말고, 동의 여부를 하나씩 확인하는 방식으로 자기 판단을 남기라"고 조언함.

---

## 3. 개발 이력 — Codex가 밤사이 한 일 (7/19 22:44 ~ 7/20 07:04, 1차 라운드)

Codex에게 "QA 포트폴리오에 필요한 XCUITest POM 자동화 + 문서화"를 맡긴 결과, 약 8.3시간 동안 다음을 진행:

### 3.1 XCUITest POM 구조 구축
`KnitGetherUITests/`에 Page Object Model 파일 다수 신설: `AuthPage`, `OnboardingPage`, `MainTabBarPage`, `MyKnittingPage`, `ProjectFormPage`, `WorkspacePage`, `SettingsPage`, `SkillTestPage`, `ToolPage`, `GaugeCalculatorPage`, `KnitGetherUITestCase`(공통 베이스), `UITestPage`(공통 헬퍼 프로토콜) 등.

### 3.2 자동화된 시나리오 (커밋 12개)
회원가입→온보딩→스킬테스트→프로젝트생성→게이지기록 핵심 흐름부터 시작해서: 프로젝트 재실행 유지, 작업공간 단수/작업시간 기록, 오프라인 스모크(서버 OFF 캐시 표시/pending 재동기화/캐시 없음 안내), 계정 전환 캐시 분리, 기존 계정 재로그인, 잘못된 비밀번호 로그인, 로그아웃 후 프로필 오류 미노출, 프로젝트 수정/삭제, 행안내(RowInstruction) CRUD, 작업세션(WorkSession) 삭제, 게이지 목표(GaugeTarget) 수정까지 — 총 17개 시나리오.

### 3.3 실제 버그 발견 및 수정 (1차 라운드)
- **`fix(ios): hide profile load error after logout`** — 로그아웃 상태를 프로필 로드 실패로 오인해 "프로필을 불러오지 못했어요" 오류를 잘못 표시하던 버그. `AppRepositoryContainer`에 `profileRequiresAuthentication` 플래그를 추가해 구분.
- **`fix(ios): show offline notice without project cache`** — 캐시가 전혀 없는 상태에서 서버 연결이 실패하면 "빈 목록"으로 오인 표시되던 버그. `OfflineFirstProjectRepository.fetchProjects()`에 `hasLocalProjectState` 체크를 추가해, 캐시도 없고 원격도 실패하면 에러를 전파하도록 수정.

### 3.4 문서화
`docs/qa/portfolio/04~07` 작성 (위 2.3 참고), `docs/qa/appium-charles-smoke.md`(기존 문서)도 참고 자료로 활용됨.

---

## 4. 개발 이력 — Codex 2차 라운드 (7/20 낮, ~7시간)

사용자가 "Codex 요금제로 몇 시간 더 돌린다"고 알려온 두 번째 라운드에서:

### 4.1 CI 파이프라인 최초 구축
`.github/workflows/ci.yml` 신설 — 서버 job(postgres 서비스 컨테이너 + build + test)과 iOS job(시뮬레이터 선택 + build + unit test + UI smoke 3개) 2-job 구조. 관련 안정화 커밋들: `ci: isolate dev auth from server tests`, `ci: stabilize ui smoke tests`, `ci: add build and smoke test workflow`, 그리고 iOS 쪽 `test(ios): harden ci ui navigation`, `test(ios): isolate ui auth token`, `test(ios): dismiss password prompt in UI flows`.

### 4.2 실제 버그 발견 — 게이지 스와치 측정값 유실 (대표 결함 후보)
- **`fix(gauge): preserve swatch measurements on patch`** — `server/src/gauge-targets/gauge-targets.service.ts`의 `createSwatchWithMeasurements`가 **PATCH(수정) 요청에서도 매번 새로 INSERT**하고 있었다. 즉 게이지 스와치나 측정값을 "수정"할 때마다 기존 값을 덮어쓰는 게 아니라 새 레코드가 계속 쌓이는 **데이터 중복 생성 버그**였다.
- 수정: `saveSwatchWithMeasurements`로 이름을 바꾸고, `updateMany` 시도 → 매칭되는 row가 없을 때만(`count === 0`) `create`하는 upsert 패턴으로 교체. Swatch와 Measurement 양쪽 모두 이 패턴 적용.
- 이 버그는 **DB QA 경력과 가장 잘 어울리는 대표 결함**으로 판단됨 (Claude가 검토 중 발견, 포트폴리오 대표 결함 후보로 지목).

### 4.3 DEF-001의 "가짜 해결"
1차 라운드에서 발견된 DEF-001(auth 이메일/비밀번호 입력칸 접근성 ID가 컨테이너에 붙어 아이콘과 같은 ID를 공유하는 문제)에 대해, `07_qa_round_1_execution` 문서는 "Retest Passed"라고 기록했다. 그러나 Claude가 코드를 직접 대조 검증한 결과: **앱 코드는 전혀 고쳐지지 않았고, 테스트 헬퍼(`UITestPage.inputElement`)가 `app.textFields[id]`처럼 타입을 지정해서 찾도록 바뀌어 우연히 버그를 우회하고 있었을 뿐**이었다. 이것 자체가 좋은 QA 교훈: **"테스트가 통과한다 ≠ 근본 원인이 고쳐졌다"**.

---

## 5. 전략적 전환점 — "이거 내가 직접 해야 하는 거 아니야?" (7/20 저녁)

사용자가 Codex에게 Postman/Appium/CI까지 전부 맡기는 10시간짜리 작업 지시서를 만들어 달라고 요청했다가 (Claude가 실제로 초안을 작성함, plan mode 사용), 곧바로 스스로 질문을 던졌다: **"Appium이나 Playwright, Postman 이런 건 내가 직접 해봐야 할 것들 아니야?"**

Claude는 이 직감이 정확하다고 판단하고 다음 원칙으로 정리했다:

| | 대신 시켜도 되는 것 | 반드시 직접 해야 하는 것 |
|---|---|---|
| 이유 | 지루한 반복 셋업, 서면 판단(리뷰로 내 것이 될 수 있음) | **툴 사용 경험 자체는 읽기만 해선 내 것이 안 됨** — 면접에서 "Appium 어떻게 디버깅했어요?"에 답이 안 나옴 |
| 예 | XCUITest 뼈대, Postman 컬렉션 초안 | Postman 실제 조작, Appium 셋업+디버깅, CI에 도구 얹기 |

최종 역할 재분배:
- **Codex/Claude**: 앱 자체를 테스트하기 쉽고 안정적인 상태로 만드는 것에만 집중 (버그 헌팅, 접근성 ID 정리, 테스트 데이터 리셋 스크립트)
- **CI는 지금 상태 유지, 확장 금지** — Postman/Newman/Appium 단계를 CI에 추가하는 것도 사람 몫
- **Postman 컬렉션, Appium 코드는 Claude가 절대 작성하지 않음**

이 결정은 메모리에 영구 기록됨.

---

## 6. Codex 자원 소진 → Claude가 직접 안정화 작업 인수 (7/20 밤 ~ 7/22)

사용자가 "Codex 요금제 다 썼다, 너가 해라"고 지시하면서, 위 5절에서 정한 "앱 안정화" 지시서를 Claude가 직접 수행하게 됨. 작업 목록(6개 태스크)을 만들어 순서대로 처리:

### 6.1 베이스라인 확인
- 서버 e2e: 12 suites / **105 tests PASS** (게이지 스와치 수정으로 1건 늘어남, 104→105)
- 작업 디렉터리 혼동으로 첫 iOS 테스트 실행이 `xcodebuild: error: 'KnitGether.xcodeproj' does not exist` 오류로 실패 → `cd` 경로 확인 후 재실행

### 6.2 DEF-001 근본 수정 — 예상보다 훨씬 큰 작업이 됨
`AuthAccountView.swift`의 `authField()` 함수를 읽어보니, 문제의 원인이 명확했다:
```swift
// 문제: authField() 호출 뒤에서 컨테이너(HStack) 전체에 identifier를 체이닝
authField(title: "이메일", ...)
    .accessibilityIdentifier(AppAccessibilityID.Auth.emailField)  // ← HStack(아이콘+TextField)에 붙음
```
수정 방향: `authField()`가 `identifier` 파라미터를 받아서 **TextField/SecureField 자체에** `.accessibilityIdentifier()`를 적용하도록 함수 시그니처를 바꾸고, 모든 호출부(`emailField`, `passwordField`, `displayNameField`)를 함께 수정.

**이 과정에서 훨씬 중요한 발견**: 앱 전체에서 재사용되는 공용 컴포넌트(`AppFormComponents.swift`의 `AppFormTextFieldRow`, `AppFormTextEditorRow`, `AppFormDecimalRow`)와 `ProjectFormView.swift`의 `ProjectTextInput`이 **정확히 같은 구조적 결함**을 갖고 있었다 — 즉 DEF-001은 인증 화면만의 버그가 아니라, **아이콘+입력칸을 나란히 두는 앱의 공통 폼 패턴 자체의 버그**였다.

이를 근본적으로 고치기 위해 **16개 파일**을 체계적으로 수정:
1. `AppFormComponents.swift` — 공용 컴포넌트 3종에 `identifier` 파라미터 추가, 내부에서 실제 입력 요소에 조건부 적용
2. `AuthAccountView.swift` — `authField()`
3. `ProjectFormView.swift` — `ProjectTextInput`
4. `AddSkillView.swift`, `NeedleLibraryView.swift`, `PatternLibraryView.swift`, `ToolLibraryView.swift`, `YarnLibraryView.swift` — 라이브러리 CRUD 폼 전체
5. `ProjectWorkspaceView.swift`, `ProjectProgressPhotoPanelView.swift`, `ProjectYarnUsagePanelView.swift`, `ProjectWorkSessionListView.swift` — 작업공간 패널들
6. `GaugeCalculatorView.swift`, `GaugeSwatchViews.swift`, `GaugeMeasurementViews.swift`, `GaugeTargetFormView.swift` — 게이지 계산기 전체

검증: `grep`으로 전수 조사한 결과 85개 컴포넌트 호출 중 77개에 identifier가 정상 적용됨을 확인 (나머지 8개는 원래부터 ID가 없던 "빠른 게이지 측정" 폼으로 의도된 상태).

**편집 중 실수 1건**: `GaugeCalculatorView.swift`에서 `old_string`/`new_string` 경계를 잘못 잡아 중복된 `.accessibilityIdentifier(...)` 줄이 남는 실수를 함. 전체 파일 재스캔으로 발견하고 즉시 수정.

이 작업은 결국 커밋 `a44c5d5 refactor(ios): apply accessibility identifiers across views`로 저장됨 (2026-07-22 00:11).

### 6.3 "빌드 도중 편집" 오염 사건 — 중요한 방법론적 교훈
DEF-001을 고치는 동안, 백그라운드에서 이전에 띄워둔 iOS 전체 테스트가 **여전히 실행 중**이었다. 파일을 계속 수정하면서 그 위에서 도는 빌드가 완료된 후, 결과를 보니 **UI 테스트 16개가 전부 동시에 실패**했다. 처음엔 "파일을 편집하는 도중 빌드가 소스를 읽어서 오염된 결과"라고 판단하고, **"모든 편집을 먼저 끝내고 나서 딱 한 번만 깨끗하게 빌드한다"**는 원칙을 세움.

### 6.4 테스트 데이터 리셋 스크립트 + Prisma 스키마 탐구
`server/scripts/reset-test-data.ts` 작성 목적: Postman/Appium으로 반복 테스트할 때 매번 깨끗한 DB 상태로 시작할 수 있게.

Prisma 스키마를 조사하며 발견한 구조:
- 거의 모든 테이블이 `UserProfile`에서 `onDelete: Cascade`로 연결됨 (Project, GaugeTarget, Skill 등)
- **시스템 스킬은 `ownerId = 'system'`이라는 특수 UserProfile 소유** — 마이그레이션(`20260711060000_add_system_skill_levels`)에서 `INSERT INTO "UserProfile" ("id", ...) VALUES ('system', 'KnitGether', ...)`로 시딩됨
- 따라서 리셋 스크립트는 `UserProfile.deleteMany({ where: { id: { not: 'system' } } })` 한 줄이면, cascade로 모든 사용자 데이터가 지워지면서도 시스템 스킬 37개는 안전하게 보존됨을 확인

### 6.5 "DATABASE_URL이 어디서 오는가" 미스터리 — 반나절 걸린 조사
리셋 스크립트를 처음 실행했을 때 `Environment variable not found: DATABASE_URL` 에러가 났다. 그런데 `npm test`(서버 e2e)는 계속 105/105로 통과하고 있었다. **왜 서버 e2e 테스트는 DATABASE_URL 없이도 도는가?**

조사 과정 (전부 헛수고로 끝난 가설들):
- `.env` 파일 존재 여부 확인 → `server/.env.example`만 있고 `.env`는 없음
- 쉘 프로필(`~/.zshrc`, `~/.zshenv`), `NODE_OPTIONS`, `npmrc`, `direnv` 전부 확인 → 아무것도 없음
- docker-compose가 postgres만 정의하고 앱 서비스는 없음을 확인
- 마침내 **`test/projects.e2e-spec.ts`에서 `overrideProvider(PrismaService).useValue(mockPrisma)`를 발견** — 서버 e2e 테스트는 **실제 Postgres에 전혀 연결하지 않고 Mock PrismaService를 쓰고 있었다.** 그래서 DATABASE_URL이 필요 없었던 것.

이 조사의 부산물로 **훨씬 중요한 실제 버그**를 발견함: **로컬 개발 서버(`npm run start:dev`)는 이 세션 내내 실제 DB에 전혀 연결되지 않고 있었다.** `server/.env` 파일 자체가 한 번도 만들어진 적이 없었기 때문. `GET /api/v1/skills` 같은 실제 DB 접근 엔드포인트를 호출하면 500 에러(`PrismaClientInitializationError: Environment variable not found: DATABASE_URL`)가 나고 있었다. `/health`만 DB를 안 건드리니 여태 "서버 정상"으로 착각하고 있었던 것.

**해결**: `.env.example`을 `.env`로 복사(정상적으로 `.gitignore`에 `server/.env`가 이미 등록되어 있어 안전). 서버 재시작 후 `GET /skills`가 실제 시스템 스킬 데이터를 정상 반환함을 확인. 리셋 스크립트에도 안전망으로 `dotenv/config` 로드 + 로컬 기본 URL 폴백을 추가.

**이 발견의 의미**: 6.3에서 "편집 중이라 오염됐다"고 판단했던 이전의 16개 UI 테스트 동시 실패는, 사실 **이 DB 연결 문제가 진짜 원인이었을 가능성이 훨씬 높다**는 것을 깨달음. 앱이 회원가입/로그인 등 서버 API를 호출하는 모든 테스트가 이 시점엔 전부 실패할 수밖에 없는 환경이었다.

이 작업은 커밋 `156d1ff chore(server): add test data reset script for manual QA`로 저장됨. 실행 결과: 사용자 프로필 277개 삭제, 시스템 스킬 37개 보존 확인.

### 6.6 서버 좀비 프로세스 발견
DB 연결 수정 후 재검증하면서 `ps aux`로 확인한 결과 `nest start --watch` 프로세스가 **3개나 동시에 떠 있었다** — 하나는 7/19(일요일) 오후부터, 하나는 7/21 새벽 1시부터, 하나는 방금 재시작한 것. 포트 3000을 실제로 잡고 있는 건 하나(자식 프로세스)뿐이었고, 프로세스 시작 시각이 재시작 시점과 정확히 일치해 **"파일 편집 중 nest watch가 서버를 재시작해서 테스트가 실패했다"는 가설은 기각**됨. 나머지 2개는 이전 세션들에서 정리되지 않고 남은 좀비 프로세스였고, 정리(kill)함.

---

## 7. 재검증 라운드 — Clone 2 시뮬레이터 플레이키니스 vs 진짜 회귀 (7/21 밤 ~ 7/22, 자율 루프 구간)

`.env` 수정 후 "진짜로 깨끗한" 상태에서 iOS 전체 테스트를 여러 차례 재실행하며 검증. 사용자가 자리를 비운 사이 자율 루프(autonomous loop)로 진행됨.

### 7.1 병렬 실행(v2) 결과 — Clone 2에서만 15개 실패
- 유닛 테스트: 전부 통과 (325개+)
- UI 테스트: `testExistingAccountCanLogInAndReachMainTabs` 등 일부는 "Clone 1"에서 정상 통과
- **15개 테스트가 전부 "Clone 2" 러너에서, 거의 동일한 ~66~72초 길이로 `XCTAssertTrue failed`** — 이 패턴(같은 러너, 균일한 시간)은 개별 로직 버그라기보다 **환경적 문제**(그 클론의 디버거 연결 문제, 로그에 반복되던 `IDELaunchParametersSnapshot: no debugger version` 에러와 연관 추정)일 가능성이 높다고 1차 판단.

### 7.2 순차 실행(v3, `-parallel-testing-enabled NO`)으로 재검증
클론 변수를 완전히 제거하기 위해 병렬 실행을 끄고 재실행. **그런데 여기서도 정확히 같은 증상이 재현됨** — `testWorkspaceRowCounterPersistsAfterAppRelaunch`, `testWorkspaceRowInstructionCanBeSavedEditedDeletedAndStayDeletedAfterRelaunch` 등이 `MainTabBarPage.swift:12`(`app.tabBars.buttons["내 뜨개"].waitForExistence(timeout: 12)`)에서 **12초 넘게 못 찾고 실패**. 이는 시뮬레이터 클론 문제가 아니라 **진짜 재현되는 문제**임을 확인.

### 7.3 근본 원인 조사 — 단일 테스트 격리 + 증거 수집

전체 스위트 대신 `-only-testing:KnitGetherUITests/KnitGetherUITests/testWorkspaceRowCounterPersistsAfterAppRelaunch`으로 **단일 테스트만 타겟팅**해 재현 속도를 높임 (풀 스위트 15~70분 → 단일 테스트 약 2분).

**1) 실패 스크린샷 + UI 계층 덤프 확보** (`xcrun xcresulttool export attachments`)
- 실패 순간, 앱은 **메인 탭바가 아니라 온보딩 "ready" 단계 화면**에 멈춰 있었다.
- 표시된 이름이 테스트가 실제 등록한 계정이 아니라 **"dev-user님"** 이었고, 화면엔 **"시작 정보를 저장하지 못했어요."** 에러가 떠 있었다.
- 이 문구는 `OnboardingViewModel.completeOnboarding()`의 catch 블록에서만 나오는 문구 — 즉 프로필 저장(PATCH) 자체가 실패했다는 뜻.

**2) 서버 요청 로그 대조** (`APIClient`의 기존 `[KnitGether API]` 디버그 로그 활용)
서버 로그를 넓게 훑어보니, **relaunch와 무관하게 매 회원가입 직후 100% 재현되는 4줄 패턴**을 발견:
```
POST /api/v1/auth/register 201   ← 등록 성공
GET  /api/v1/auth/me      200   ← 같은 토큰으로 즉시 검증 성공
GET  /api/v1/profile      401   ← 곧바로 이어지는 프로필 조회 실패
PATCH /api/v1/profile     401   ← 저장도 실패
```
같은 토큰으로 `/auth/me`는 성공하는데 `/profile`만 401이 나는 것이 핵심 단서. 이는 relaunch 시나리오뿐 아니라 **모든 회원가입 직후에 항상 벌어지는 문제**였다는 뜻 — 그동안 "재실행 후 세션 복원 문제"라고 좁게 보던 프레임 자체가 틀렸을 가능성이 드러남 (relaunch 테스트들이 유독 많이 걸린 건 그것들이 전부 registerAndFinishOnboarding으로 시작하기 때문일 뿐).

**3) 서버 결백 증명** (curl로 직접 재현)
같은 register→auth/me→profile 순서를 `curl`로 그대로 재현: **서버는 완벽하게 정상 동작**했다 (둘 다 200). 이로써 **버그가 서버가 아니라 클라이언트(iOS 앱)에 있다는 것이 확정**됨. `ProfileService.getCurrentProfile()`이 `upsert`로 프로필이 없으면 `displayName: ownerId`로 자동 생성한다는 것도 확인 — 즉 클라이언트가 어떤 이유로 `ownerId`가 "dev-user"로 해석되는 토큰(혹은 무토큰)을 보내면, 서버가 자동으로 "dev-user"라는 이름의 프로필을 만들어버리는 것이 "dev-user님" 표시의 원인일 가능성이 높음.

**4) 클라이언트 코드 추적 — 유력 용의선**
`AppRepositoryContainer.swift`의 인증 토큰 결정 로직을 정독:
```swift
authTokenProvider: {
    if let apiToken, !apiToken.isEmpty { return apiToken }               // 정적 토큰 (미설정)
    if let sessionToken = await authSessionStore.accessToken(), ...       // Keychain 세션 토큰
       { return sessionToken }
    return devToken                                                       // 개발용 토큰 (테스트에서 비활성화됨)
}
```
- `APIClient.requestData()`에서 `authTokenProvider()`가 **`nil`을 반환하면 Authorization 헤더 자체를 아예 안 붙이고 조용히 요청을 보낸다** — 서버는 이를 "토큰 없음"으로 보고 401.
- `AuthAccountView`/`OnboardingView`는 각각 별도의 `AppRepositoryContainer` 참조(`repositories`)를 들고 있고, `AppRepositoryStore`는 로그인 성공 시 `authSessionStore.$currentSession`을 구독해 **컨테이너를 통째로 재구성(rebuild)** 한다(`rebuildIfSessionScopeChanged`). `OnboardingView`는 `.onChange(of: repositories.instanceID)`로 이 재구성을 감지해 자신의 `profileRepository`를 교체하는 구조.
- 가설: 로그인 직후 `/auth/me`(등록 응답에서 받은 세션으로 직접 호출)는 성공하지만, 그 직후 온보딩이 사용하는 `profileRepository`(컨테이너 재구성 타이밍에 의존)가 **아직 재구성되지 않았거나, 재구성된 컨테이너의 `authTokenProvider`가 Keychain에서 토큰을 읽어오는 시점에 문제가 있어** 이 특정 호출에서만 토큰이 비어있게 되는 것으로 추정 — **컨테이너 재구성 레이스(race) 또는 세션 저장/전파 타이밍 버그**.
- 확정을 위해 `APIClient.requestData()`에 임시 디버그 로그 한 줄을 추가함 (`auth=present(...)` / `auth=MISSING`)해서 실제로 어느 케이스인지 다음 재현 실행에서 직접 확인 중 (진행 중, 결과 대기).

### 7.4 결론 (현재까지 확정된 사실 + 남은 불확실성)

**확정된 사실 (증거 기반, 100% 재현):**
1. 이 버그는 relaunch 전용이 아니라 **매 회원가입 직후 항상** 발생한다 (`POST /auth/register` → `GET /auth/me` 200 → `GET /profile` 401 → `PATCH /profile` 401, 예외 없이 매번).
2. curl로 동일 시퀀스를 서버에 직접 재현 → **서버는 완벽히 정상** (둘 다 200). **서버 버그 아님, 클라이언트(iOS) 버그로 확정.**
3. `APIClient.requestData()`가 `authTokenProvider()`에서 `nil`을 받으면 Authorization 헤더를 아예 안 붙이고 조용히 요청을 보낸다는 것을 코드로 확인 (`KnitGether/Networking/APIClient.swift:140`).
4. `OnboardingViewModelTests.swift`에 이미 존재하는 단위 테스트(`replacingProfileRepositoryUsesNewScopeWhenCompletingOnboarding` 등)는 Fake Repository로 **로직만** 검증하고 있어, 이 버그(실제 Keychain/네트워크/컨테이너 재구성 타이밍)를 잡아낼 수 없는 구조라는 것도 확인 — 유닛 테스트는 전부 통과하는데 실제 통합 환경에서만 깨지는 전형적 사례.

**추가로 시도했으나 결론에 이르지 못한 것:**
- `APIClient.requestData()`에 진단용 로그(`auth=present/MISSING`)를 추가하고 재현을 시도했으나, UI 테스트의 앱-대상-프로세스 표준출력은 `xcodebuild test`의 캡처 로그에 나타나지 않음을 확인. `xcrun simctl log stream`으로 라이브 캡처를 시도했으나, `xcodebuild`가 테스트마다 지정한 시뮬레이터의 **클론(Clone)**을 새로 만들어 실행한다는 것을 뒤늦게 확인 — 내가 스트리밍하던 것은 원본 시뮬레이터였고 실제 실행은 별도 클론에서 일어나 로그가 잡히지 않았음. 이 진단 로그 자체는 향후 디버깅에 유용하므로 **코드에는 그대로 남겨둠** (`APIClient.swift`).
- 남은 가장 유력한 가설: `AuthAccountView`(온보딩의 "계정" 단계로 내장됨)에서 회원가입 성공 직후, `AppRepositoryStore`가 `authSessionStore.$currentSession` 변경을 구독해 컨테이너를 비동기로 재구성(`rebuildIfSessionScopeChanged`)하는 타이밍과, `OnboardingView`가 `.onChange(of: repositories.instanceID)`로 이 재구성을 감지해 `OnboardingViewModel.profileRepository`를 교체하는 타이밍 사이에 **경쟁 상태(race condition)** 가 있어, 온보딩이 아주 짧은 창 동안 아직 인증되지 않은(또는 세션이 아직 전파되지 않은) `profileRepository`로 `/profile`을 호출하는 것으로 추정.
- 완전한 확정에는 실제 기기/시뮬레이터에 LLDB를 붙여 `authTokenProvider` 클로저 실행 시점의 실제 값을 브레이크포인트로 확인하는 절차가 필요하며, 이는 CLI 기반 도구만으로는 재현 신뢰도 있게 계측하기 어려웠다.

**의미**: 이 결함은 DEF-001과 마찬가지로 **자동화 테스트(XCUITest)가 아니었다면 절대 발견하지 못했을 문제**다 — 유닛 테스트는 다 통과하고, 수동으로 앱을 켜서 한 번 가입하고 끝내는 정도로는 절대 걸리지 않는다(단 한 번의 relaunch가 필요). "왜 UI 자동화가 유닛 테스트만으로는 부족한가"에 대한 최고의 실증 사례로 포트폴리오에 남길 가치가 있다.

### 7.5 수정 시도 1건 — 부분 개선 확인 후 안전하게 되돌림

가장 유력한 가설(세션 저장과 컨테이너 재구성 사이의 비동기 지연)을 실제로 고쳐서 검증해봄:
```swift
// 이전: Task{@MainActor}로 다음 런루프 턴까지 재구성이 미뤄짐
Task { @MainActor in self?.rebuildIfSessionScopeChanged(session) }
// 시도: MainActor.assumeIsolated로 즉시(동기적으로) 재구성
MainActor.assumeIsolated { self?.rebuildIfSessionScopeChanged(session) }
```
재현 결과: **실패 지점이 뒤로 밀렸다** — 온보딩 저장 실패는 사라지고, 대신 프로젝트 생성("프로젝트 추가") 화면에서 저장 버튼이 스피너 상태로 멈추며 서버 로그에 `/profile`, `/projects`, `/patterns`, `/library/yarns` 등 다수 엔드포인트에서 401이 쏟아지는 새로운 증상으로 바뀜. 즉 **이 지연이 원인의 일부는 맞지만 전부는 아니며, 더 넓은 범위의 인증 타이밍 문제가 존재**함을 시사한다.

`MainActor.assumeIsolated`는 "지금 반드시 메인 액터 위에 있다"는 가정이 틀리면 **크래시**하는 API라, 문제를 완전히 고치지도 못한 상태로 이 위험을 감수할 이유가 없다고 판단해 **원래의 안전한 `Task { @MainActor in ... }` 코드로 되돌렸다.** (검증되지 않은 "개선처럼 보이는 변경"을 남기지 않는 것 — 이번 세션에서 반복해서 지킨 원칙.)

### 7.6 추가 검증 라운드 — 모든 환경적 가설을 하나씩 소거함

라이브러리 POM 테스트를 새로 작성한 뒤 실행하자 **3개 전부**가 동일하게 `MainTabBarPage.swift:12`(재실행/등록 직후 메인 탭바 대기)에서 실패했다. 이번엔 의심 가능한 환경 변수를 하나씩 통제하며 재현을 반복했다:

| 시도 | 조건 | 결과 |
|---|---|---|
| 1 | 서버 완전 재시작(좀비 프로세스 정리 후 새 프로세스) | 여전히 실패 |
| 2 | curl로 서버만 직접 재검증 | 서버는 정상 (재확인) |
| 3 | 실패하는 테스트 1개만 완전 격리 실행 | 여전히 동일 지점에서 실패 |
| 4 | 시뮬레이터에서 앱 완전 삭제(Keychain/UserDefaults 초기화) 후 격리 실행 | 여전히 실패 |
| 5 | 시뮬레이터 전체 초기화(`simctl erase`) + DerivedData 완전 삭제 후 클린 빌드 | 여전히 실패 |
| 6 | `AuthAccountView.swift`의 접근성 ID 리팩터 diff 재검토 | 순수 코스메틱 변경만 확인, 로직 변경 없음 — 원인 아님 |

**결론**: 이 버그는 세션 누적 상태, 서버 노후화, 시뮬레이터 오염, 내가 만든 접근성 ID 변경 중 **어느 것도 원인이 아니다.** 클린룸 조건에서도 100% 결정적으로 재현되는, 회원가입 직후 온보딩 완료(프로필 저장) 플로우 자체에 내재한 실제 앱 버그다.

### 7.7 마지막 시도 — 파일 기반 로깅으로 직접 계측

`xcrun simctl log stream`이 xcodebuild가 생성하는 시뮬레이터 클론을 제대로 못 잡는 문제를 우회하기 위해, `APIClient.debugLog`가 콘솔 출력 대신 **앱 컨테이너 내부 파일에 직접 기록**하도록 임시로 바꾸고, 테스트 실행 후 `~/Library/Developer/CoreSimulator/Devices/` 전체에서 그 파일을 찾아보았다. 49개 디바이스 전체를 뒤졌지만 파일 자체가 발견되지 않음 — 이는 로깅 코드가 실행되지 않았거나(가능성 낮음, 매 요청마다 호출되는 경로), 파일 쓰기 자체가 샌드박스 문제로 조용히 실패했거나, 컨테이너 검색 경로가 실제 실행 인스턴스와 어긋났을 가능성이 있다. 이 접근도 결론에 이르지 못해 **원상 복구**했다.

### 7.8 최종 상태 (DEF-006)

- **확정 (매우 높은 확신도)**: 클라이언트 버그, 서버 아님(curl로 2회 독립 검증). 회원가입 직후 온보딩 완료(프로필 저장) 흐름에서 인증 토큰이 유실/누락되어 100% 결정적으로 재현됨.
- **소거 완료**: 세션 누적 상태, 서버 프로세스 노후화, 시뮬레이터/DerivedData 오염, 접근성 ID 리팩터 — 전부 원인이 아님을 개별적으로 확인.
- **부분 확인**: 세션→컨테이너 재구성의 비동기 지연(`Task { @MainActor in }`)이 원인의 일부일 가능성은 있으나(수정 시 실패 지점이 온보딩에서 프로젝트 저장으로 이동), 이 지연을 동기화하는 시도(`MainActor.assumeIsolated`)는 문제를 완전히 없애지 못했고 크래시 위험이 있는 API라 되돌림.
- **미해결**: 정확한 트리거 메커니즘. `xcodebuild`의 UI 테스트가 매 실행마다 시뮬레이터 클론을 새로 만들어, CLI 기반 콘솔/파일 로그 캡처가 계속 빗나갔다 — Xcode GUI에서 LLDB를 직접 붙여 `AppRepositoryContainer.authTokenProvider` 클로저와 `AuthSessionStore.accessToken()`에 브레이크포인트를 걸어야 확정 가능하다.
- **조치**: 진단용 임시 코드(파일 로깅) 전부 원상 복구. `AppRepositoryContainer.swift`, `APIClient.swift`는 최종적으로 세션 시작 시점과 동일한 커밋 상태로 유지됨 — 이번 세션에서 만든 유일한 영구 변경은 접근성 ID 리팩터(정상 동작 확인됨)와 테스트 데이터 리셋 스크립트뿐.
- **의미**: 이 결함은 DEF-001과 마찬가지로 **XCUITest 자동화가 없었다면 절대 발견하지 못했을 문제**다. 유닛 테스트(Fake Repository 기반)는 전부 통과하고, 수동으로 앱을 한 번 켜서 가입만 하고 끝내는 정도로는 걸리지 않는다. "왜 UI 자동화가 유닛 테스트만으로는 부족한가"를 보여주는 최고의 실증 사례이자, 6시간 넘게 다각도로 재현·소거법을 적용한 것 자체가 QA 방법론(가설 수립 → 통제 변수로 하나씩 소거 → 확정 못 하면 정직하게 보류)의 좋은 사례다.
- **다음 세션 제안**: Xcode GUI + LLDB로 `AppRepositoryContainer.authTokenProvider`와 `AuthSessionStore.accessToken()`에 브레이크포인트를 걸고 실제 실행 순간의 값을 확인하는 것이 유일하게 남은, 확실한 다음 단계.

### 7.9 조사 도중 발견한 별개의 진짜 버그 — 서버 e2e 테스트 격리 깨짐 (발견 즉시 수정 완료)

DEF-006과 무관하게, "이 서버 설정 변경이 혹시 관련 있나?" 확인차 전체 서버 e2e를 재실행했다가 **34개 테스트가 갑자기 실패**하는 것을 발견했다 (`profile`, `patterns`, `skills`, `dictionary`, `library`, `gauge-records`, `gauge-targets` 7개 스펙 파일).

**원인 추적**: 실패 메시지를 보니 테스트가 기대한 `id: 'user-a'` 대신 실제로는 `id: 'dev-user'`로 인증되고 있었다. 각 e2e 스펙은 `beforeAll`에서 `process.env.DEV_AUTH_USER_ID = 'user-a'`를 직접 대입해 인증 대상을 스텁하는 방식을 쓰는데, **`server/.env` 파일이 존재하면 `@nestjs/config`가 파일에서 읽은 값(`DEV_AUTH_USER_ID=dev-user`)을 테스트의 런타임 `process.env` 대입보다 우선시**해서, 이 스텁이 조용히 무시되고 있었다. `server/.env`는 이번 세션 6.5절에서 "개발 서버가 DB에 전혀 연결 안 되던" 진짜 문제를 고치려고 내가 직접 만든 파일이라, **내가 만든 수정의 부작용으로 뒤늦게 발견된 회귀**다.

**수정**: `AppModule`의 `ConfigModule.forRoot()`에 `ignoreEnvFile: process.env.NODE_ENV === 'test'`를 추가 — 테스트 실행 시에는 `.env` 파일을 아예 무시하고 테스트 자신의 process.env 스텁만 보게 함. 개발 모드(NODE_ENV=development)는 영향 없음을 수동으로 재확인(서버 재시작 후 `/health`, `Bearer dev-token`으로 `/skills` 정상 응답 확인).

**검증**: 서버 e2e 105/105 복구. 이 수정이 DEF-006에도 영향이 있는지 확인차 라이브러리 테스트를 재실행했으나 **DEF-006은 그대로 재현됨** — 두 문제는 서로 무관한 별개의 결함으로 최종 확정.

이 발견은 포트폴리오에서 좋은 사례다: **"내가 만든 수정이 다른 곳에서 회귀를 일으켰는지 반드시 전체 테스트로 재확인해야 한다"** — 부분 검증(새 코드가 컴파일되고 의도대로 동작하는지)만으로는 충분하지 않고, 항상 전체 회귀 스위트를 다시 돌려야 발견할 수 있는 종류의 버그였다.

| ID | 제목 | 발견 경위 | 상태 |
|---|---|---|---|
| DEF-007 | `server/.env` 존재 시 e2e 테스트의 `DEV_AUTH_USER_ID` 스텁이 무시되고 실제 `.env`의 `dev-user`로 인증됨 (7개 스펙, 34개 테스트 영향) | DEF-006 조사 중 우연히 실행한 전체 회귀에서 발견 | ✅ 근본 수정 완료 (`ConfigModule.forRoot({ ignoreEnvFile: NODE_ENV==='test' })`), 105/105 복구 확인 |

### 7.10 DEF-006 최종 해결 (2026-07-23) — 앱 버그가 아니라 **테스트 인프라 버그**였다

7.8절에서 "Xcode+LLDB가 유일한 다음 단계"로 남겨뒀으나, 이번 세션에 **LLDB 없이 서버 쪽 계측만으로** 완전히 규명·해결했다.

**방법론 (서버를 계측 지점으로 삼음)**: xcodebuild가 매번 시뮬레이터 클론을 만들어 클라이언트 로그가 안 잡히는 문제를, "클라이언트가 서버에 말하게" 해서 우회했다. `authTokenProvider`가 토큰이 없을 때 `nil` 대신 진단 문자열(`DIAG.…`)을 Bearer 토큰으로 보내게 하고, 서버 접근 로그(`app.setup.ts`)에서 그 값을 읽었다. 단계별로:
1. `auth=none` → 첫 401은 토큰이 틀린 게 아니라 **헤더 자체가 없음** 확인
2. `lastClear`/`clears` 카운터 → 회원가입 저장 성공(`lastSave-ok`) **후에도** 세션이 `clear()`로 지워짐 확인
3. `clear(reason:)` 태깅 → 지운 주체가 `signOut`임 확인 (401 핸들러 아님)
4. `Thread.callStackSymbols`를 서버로 전송 → demangle 결과 **`AuthAccountView.signedInContent`의 로그아웃 버튼**에서 signOut 발동 확인
5. xcresult 액티비티 로그의 탭 시퀀스 → `auth.logout` 명시적 탭은 **단 1회**뿐인데 회원가입 후 signOut이 또 발생

**근본 원인 (확정)**: 테스트 헬퍼 `UITestPage.dismissSystemPasswordPromptIfNeeded`가 비밀번호 저장 다이얼로그를 닫으려 할 때, 이름으로 버튼을 못 찾으면 **좌표 (0.31, 0.74)를 맹목적으로 탭**하는 fallback이 있었다. 실제로 이 테스트에선 비밀번호 다이얼로그가 뜬 적이 없어(액티비티 로그상 "저장 안 함" 탭 0회), 이 좌표 탭이 매번 **앱 화면 위로 그대로 떨어졌고**, 회원가입 직후 화면(`signedInContent`)의 **로그아웃 버튼이 정확히 세로 74% 지점**에 있어 그 버튼을 눌러버렸다. → 방금 만든 세션이 로그아웃으로 삭제 → 온보딩 완료 시 `PATCH /profile` 401 → "시작 정보를 저장하지 못했어요".

**즉 앱은 정상이었다.** 프로덕션엔 좌표 자동 탭이 없으므로 이 버그가 존재하지 않는다. 7.1~7.8절에서 6시간 넘게 쫓던 "컨테이너 재구성 경쟁 상태"·"인증 타이밍"은 전부 헛다리였다.

**수정**: fallback 좌표 탭을 **springboard 알림/시트가 실제로 존재할 때만** 실행하도록 가드 (커밋 `7b4eae3`). 진단용 임시 코드(앱 3파일 + 서버)는 전부 원상 복구, 앱/서버는 pristine.

**교훈 (포트폴리오 가치)**: (1) 버그가 앱에 있다고 단정하지 말 것 — 테스트 하네스 자신이 원인일 수 있다. (2) 계측이 막히면 우회 경로를 설계하라(클라이언트 로그 대신 서버 로그). (3) 좌표 기반 맹목적 탭은 안티패턴 — 조건 없는 fallback이 조용히 다른 요소를 눌러 상태를 오염시킨다.

### 7.11 DEF-006 해결로 드러난 신규 결함 2건 (동일 세션 즉시 수정·검증 완료)

DEF-006이 온보딩을 막고 있던 탓에 라이브러리 POM 3개가 한 번도 CRUD까지 실행된 적이 없었다. 온보딩이 뚫리자 즉시 2건이 드러났다.

| ID | 제목 | 성격 | 상태 |
|---|---|---|---|
| DEF-008 | 실/바늘/도구 상세에서 **수정 저장 시 상세가 아니라 목록으로 튕김** — 수정 시트 onSave 클로저가 상세 뷰의 `dismiss()`를 호출(삭제 플로우에서 복붙, 삭제 땐 pop이 맞지만 수정 땐 틀림). 시트 닫기는 FormView가 자기 dismiss로 이미 처리하므로 중복+유해 | **진짜 앱 UX 버그** (프로덕션에도 존재) | ✅ 3개 뷰에서 잘못된 `dismiss()` 제거 (커밋 `df13aef`), 3개 UI 테스트 통과로 검증 |
| DEF-009 | 바늘 추가 UI 테스트가 저장 안 됨(`POST /library/needles` 미발생) — `NeedleFormData.canSave`는 이름+종류+사이즈 3개 필수인데 POM `addNeedle`이 **종류를 안 채워** 저장 버튼이 비활성 | POM 미완성(테스트 버그). 앱은 정상 | ✅ POM에 종류 필드 입력 추가 (커밋 `3b2bc52`) |

**최종 검증**: `testYarn/Needle/ToolLibrary...AfterRelaunch` **3개 전부 통과** (각 121~132초, add→edit→relaunch→delete→relaunch 전체 라이프사이클 완주). 서버 로그로 `POST 201 → PATCH 200 → DELETE 204` 정상 흐름 확인.

---

## 8. 앱 아키텍처 정리 (학습 자료)

### 8.1 전체 구조
```
[iOS 앱: SwiftUI]
   ├─ Views (SwiftUI 화면들)
   ├─ ViewModels (ObservableObject, @Published 상태)
   ├─ Repositories
   │    ├─ Protocol (예: ProjectRepository)
   │    ├─ LocalXXXRepository (CoreData/파일 기반, 오프라인 전용)
   │    ├─ RemoteXXXRepository (APIClient로 서버 호출)
   │    └─ OfflineFirstXXXRepository (Local+Remote 합성 — "로컬 저장 → 원격 시도 → 실패 시 pending 처리·롤백")
   ├─ AppRepositoryContainer (환경변수로 Local/API 모드 결정, 어떤 Repository 조합을 쓸지 조립)
   └─ APIClient (URLSession 기반 HTTP 클라이언트)
        ↓ HTTP (KNITGETHER_API_BASE_URL)
[서버: NestJS]
   ├─ Controller → Service → Prisma → PostgreSQL
   ├─ ApiAuthGuard (Bearer 토큰 → userId 매핑: JWT 검증 → 설정된 정적 토큰 → 개발용 dev-token 순서로 폴백)
   └─ 도메인별 모듈: Auth, Profile, Projects(+RowCounter/RowInstruction/WorkSession/PatternCopy), Patterns, GaugeRecords, GaugeTargets(+Swatch/Measurement), Skills, Dictionary, Library(Yarn/Needle/Tool)
```

### 8.2 오프라인 우선(Offline-First) 패턴
`OfflineFirstProjectRepository`, `OfflineFirstSkillRepository` 등에서 반복되는 패턴:
1. 로컬(CoreData/파일)에 먼저 저장 (즉시 사용자에게 반영)
2. 원격 서버로 동기화 시도
3. 실패 시: 재시도 가능한 에러(`shouldDefer`)라면 로컬 상태를 `pending`으로 유지하고, 원격 호출이 완전히 실패했는데 로컬 캐시조차 없으면 에러를 사용자에게 노출 (6.5에서 다룬 `hasLocalProjectState` 체크가 이 판단의 핵심 — 이게 없으면 "빈 목록"과 "네트워크 에러"를 구분 못 함)
4. 복구 시: pending 상태 항목을 재동기화

### 8.3 데이터 정합성 관련 핵심 모델
- `UserProfile` — 모든 소유 데이터의 루트, `id='system'`은 시스템 스킬 전용 특수 프로필
- `Skill.isSystem` — 시스템 제공 스킬(수정 불가, `ensureEditable`로 차단)과 사용자 스킬 구분
- `GaugeTarget → GaugeSwatch → GaugeMeasurement` — 3단계 중첩 구조. 여기서 "수정 시 새로 생성되는" 버그(4.2)가 나온 지점
- `Project → RowCounter/RowInstruction/WorkSession/ProjectYarnUsage/ProjectToolLink/ProjectPatternCopy` — 프로젝트 하나에 딸린 여러 하위 리소스, 전부 cascade delete

### 8.4 접근성 ID 시스템 (`AppAccessibilityID.swift`)
`enum` 네임스페이스(`Auth`, `Project`, `Workspace`, `Library`, `Tool`, `Settings`, `Tab`, `Onboarding` 등)로 문자열 상수를 관리하고, XCUITest POM이 이 상수와 매칭되는 문자열로 요소를 찾는 구조. **6.2에서 다룬 버그의 교훈**: SwiftUI에서 `.accessibilityIdentifier()`를 컨테이너(HStack 등)에 걸면, 그 안의 자식 요소(아이콘 Image 포함)에도 같은 ID가 내려가 테스트가 엉뚱한 요소를 찾을 수 있다 — **반드시 실제 상호작용 가능한 leaf 요소(TextField, Button 등)에 직접 걸어야 한다**는 것이 이번 작업으로 확립된 규칙.

---

## 9. 지금까지 발견/수정된 결함 목록 (포트폴리오 결함 리포트 재료)

| ID | 제목 | 발견 주체 | 근본 수정 여부 | 비고 |
|---|---|---|---|---|
| DEF-001 | 인증 화면 이메일/비밀번호 입력칸 접근성 ID가 컨테이너(아이콘 포함)에 붙어 테스트가 잘못된 요소를 찾음 | Claude (7/19 첫 UI 테스트 실행) | ✅ 근본 수정 (7/21~22, 16개 파일) | Codex의 "Retest Passed" 기록은 실제로는 테스트 우회였음이 밝혀짐 — 좋은 QA 사례 |
| DEF-002 (가칭) | 로그아웃 상태를 프로필 로드 실패로 오인 표시 | Codex (1차 라운드) | ✅ 수정됨 (`b451f7c`) | |
| DEF-003 (가칭) | 캐시 없이 서버 연결 실패 시 빈 목록으로 오인 (오프라인 안내 미표시) | Codex (1차 라운드) | ✅ 수정됨 (`ebef0c6`) | |
| DEF-004 (가칭, 대표 결함 후보) | 게이지 스와치/측정값 PATCH 시 매번 새 레코드 생성 (수정이 아니라 중복 생성) | Codex (2차 라운드) | ✅ 수정됨 (`5cb7283`) | DB QA 경력과 가장 잘 맞는 소재 |
| DEF-005 (환경 버그, 앱 코드 버그 아님) | 로컬 개발 서버가 `.env` 부재로 DB에 전혀 연결되지 않고 있었음 | Claude (7/21, 리셋 스크립트 작업 중) | ✅ 수정됨 (`.env` 생성) | 앱 버그는 아니지만 QA 관점에서 "환경 문제(ENV_ISSUE)"로 분류할 가치 있는 사례 |
| DEF-006 | 앱 재실행 후 메인 탭바가 12초 내에 나타나지 않음 (`relaunchForExistingSession` 경로) | Claude (7/22, 순차 재검증 중) | ✅ 해결 (`7b4eae3`) — **앱 버그가 아니라 테스트 인프라 버그**였음 (7.10 참고) | 병렬/순차 양쪽에서 재현되어 실제 이슈로 추정했으나, 원인은 POM의 무조건 좌표 탭이 로그아웃 버튼을 누른 것 |
| DEF-007 | `server/.env` 존재 시 e2e의 `DEV_AUTH_USER_ID` 스텁이 무시됨 (7개 스펙, 34개 테스트) | Claude (7/22, DEF-006 조사 중 전체 회귀에서) | ✅ 근본 수정 (`65027d6`) | 7.9 참고. 내가 만든 수정의 부작용으로 뒤늦게 발견된 회귀 |
| DEF-008 | 실/바늘/도구 상세에서 수정 저장 시 상세가 아니라 목록으로 튕김 | Claude (7/23, DEF-006 해제 직후) | ✅ 근본 수정 (`df13aef`) | 프로덕션에도 존재하던 진짜 앱 UX 버그 |
| DEF-009 | 바늘 추가 POM이 필수값(종류)을 안 채워 저장 버튼이 비활성 | Claude (7/23) | ✅ POM 수정 (`3b2bc52`) | 앱 정상, 테스트 미완성 |
| DEF-010 | XCUITest 헬퍼 `replaceText`가 기존 텍스트를 한 번에 지우려다 일부만 지워, 수정(edit) 계열 테스트가 **간헐 실패** | Claude (7/28, 워크스페이스 2탭 분리 회귀 검증 중) | ✅ 헬퍼 수정 (12절) | 앱 정상. severity 판단은 하은님 몫. 증거: `evidence/0728_DEF-010_workspace-row-instruction_FAIL.png` |

---

## 10. 아직 남은 작업 (사용자 지시 체크리스트 기준)

- [x] DEF-001 근본 수정
- [x] 접근성 ID 전수 점검 (16개 파일, 커밋 `a44c5d5`)
- [진행 중] 라이브러리/도안/사전 영역 회귀 테스트 추가 — 실/바늘/도구 창고 CRUD 3건 작성 완료(커밋 `4d1af42`), 도안/사전은 미착수. 실행 검증은 DEF-006에 막혀 있음
- [x] 테스트 데이터 리셋 스크립트 (커밋 `156d1ff`)
- [부분] 서버/iOS 전체 테스트 여전히 통과 — **서버 105/105 통과**(DEF-007 발견·수정 후 복구, 커밋 `65027d6`), **iOS 유닛 전체 통과**. **DEF-006(재실행/등록 직후 프로필 API 401)은 미해결로 남겨둠** — 서버·시뮬레이터·DerivedData·접근성 리팩터·이번에 고친 DEF-007까지 전부 무관함을 하나씩 소거법으로 확인했으나 최종 트리거는 못 찾음 (7.6~7.9절 참고)
- [x] 이 히스토리 문서 최신화

## 11. 라이브러리 XCUITest POM 추가 (진행 중)

기존 QA 문서(`04_pom_screen_success_failure_criteria.md`)에 "P1, 자동화 아직 안 됨"으로 남아있던 영역 — 실/바늘/도구 창고 CRUD — 에 대해 XCUITest POM을 새로 작성함.

**중요한 실수 하나와 교훈**: 처음에 `AppAccessibilityID.Library.yarnAddButton`처럼 앱 타겟의 enum을 POM에서 직접 참조하도록 작성했다가 컴파일 에러(`cannot find 'AppAccessibilityID' in scope`)를 만남. **UI 테스트 타겟은 앱-대상 프로세스와 별도 프로세스로 실행되기 때문에 앱의 Swift 타입을 직접 import할 수 없고, 오직 문자열 기반 접근성 식별자만 프로세스 경계를 넘어 작동한다** — 기존 POM 파일(AuthPage, GaugeCalculatorPage 등)이 전부 문자열 리터럴(`"tool.gauge.swatch.add"` 등)을 쓰고 있었던 이유를 뒤늦게 이해함. 전부 문자열 리터럴로 고쳐서 해결.

추가한 파일:
- `KnitGetherUITests/LibraryPage.swift` — 창고 탭 진입점 (실/바늘/도구 창고로 분기)
- `KnitGetherUITests/YarnLibraryPage.swift` — 실 추가/수정/삭제 + 재실행 후 유지 확인
- `KnitGetherUITests/NeedleLibraryPage.swift` — 바늘 추가/수정/삭제 + 재실행 후 유지 확인
- `KnitGetherUITests/ToolLibraryPage.swift` — 도구 추가/수정/삭제 + 재실행 후 유지 확인
- `MainTabBarPage.openLibrary()` 메서드 추가
- `KnitGetherUITests.swift`에 테스트 3개 추가: `testYarnLibraryCanBeAddedEditedDeletedAndStayDeletedAfterRelaunch`, `testNeedleLibrary...`, `testToolLibrary...` (기존 `testProjectCanBeEditedDeletedAndStayDeletedAfterRelaunch`와 동일한 구조: 추가→수정 확인→재실행→유지 확인→삭제→재실행→미노출 확인)

빌드는 정상 성공(컴파일 에러 없음). 실행 검증 결과: 3개 전부 `registerAndFinishOnboarding()` 단계, 즉 **DEF-006과 정확히 동일한 지점**에서 실패 — 새로 작성한 POM/테스트 코드 자체의 문제가 아니라, 이 세션 전체에서 발견된 DEF-006(7.6~7.8절)이 모든 신규 테스트의 셋업 단계를 막고 있는 것으로 확정됨. 코드는 기존에 이미 통과 이력이 있는 `testProjectCanBeEditedDeletedAndStayDeletedAfterRelaunch` 등과 동일한 구조·컨벤션을 따르므로, DEF-006이 해결되면 별도 수정 없이 통과할 것으로 예상한다. **"작성 완료, DEF-006 해결 전까지 실행 검증 불가"** 로 정직하게 표시하여 커밋한다 — 검증 안 된 것을 통과했다고 주장하지 않는다.

---

## 12. 워크스페이스 2탭 분리 회귀 검증 → DEF-010 발견 (2026-07-28)

### 12.1 배경 — 무엇을 검증했는가

`2026-07-27-workspace-two-tab-design.md` 스펙에 따라 작업 공간이 **뜨는 중 / 프로젝트 정보** 2탭으로 분리됐다(`cedd35d`). 스펙은 검증 방법까지 지정해 뒀다: "기존 워크스페이스 UI 테스트가 다루는 섹션은 전부 기본 탭(뜨는 중)에 있으므로 그대로 통과 예상 → 구현 후 `testWorkspaceRowCounter*` · `testWorkspaceRowInstruction*` · `testWorkspaceWorkSession*` 3계열 재실행으로 확인."

커밋 메시지에는 이미 "Existing workspace UI tests ... still pass unchanged"라고 적혀 있었다. **그 주장을 실제로 돌려서 확인하는 것**이 이번 작업이었다.

### 12.2 결과 — 4개 중 3개 통과, 1개 실패

| 테스트 | 1차 | 재실행 |
|---|---|---|
| `testWorkspaceRowCounterPersistsAfterAppRelaunch` | PASS (140초) | — |
| `testWorkspaceWorkSessionCanBeRecorded` | PASS (92초) | — |
| `testWorkspaceWorkSessionCanBeDeletedAndStaysDeletedAfterRelaunch` | PASS (147초) | — |
| `testWorkspaceRowInstructionCanBeSavedEditedDeletedAndStayDeletedAfterRelaunch` | **FAIL** (154초) | PASS (194초) |

즉 커밋 메시지의 "still pass unchanged"는 **4개 중 3개까지만 사실**이었다. 검증 없이 쓰인 통과 주장을 실행으로 반증한 사례 — DEF-001에서 Codex의 "Retest Passed"가 실제로는 테스트 우회였던 것과 같은 계열이다.

### 12.3 실패 지점 특정 — 로그가 아니라 xcresult 액티비티로

실패 메시지는 `WorkspacePage.swift:108: XCTAssertTrue failed - 행안내가 보여야 합니다: Purl back a037e971`였다. 그런데 이 테스트는 `expectRowInstruction(editedInstruction)`을 **재실행 전과 후 두 번** 호출하므로, 메시지만으로는 어느 쪽인지 알 수 없었다.

xcresult 액티비티에서 `Launch com.uhaeun.KnitGether`가 **단 1회**뿐임을 확인 → 실패는 `relaunchForExistingSession()` **이전**, 즉 수정 직후 검증 단계에서 났다. 재실행/영속성 문제가 아니라 **수정 자체가 반영되지 않은 것**으로 범위가 좁혀졌다.

### 12.4 근본 원인 — 실패 스크린샷이 결정적 증거

액티비티 로그상 폼에 `Purl back a037e971`을 정확히 입력하고 저장했는데도 화면에서 그 텍스트를 못 찾고 8회 스크롤 후 실패했다. 실패 스크린샷을 열자 화면의 행안내는:

```
Knit Purl back a037e971
```

**기존 텍스트가 완전히 지워지지 않고 새 텍스트가 이어붙어 있었다.** 원본 `Knit across a037e971`(20자)에서 15자만 지워지고 `"Knit "`가 남은 것.

원인은 `UITestPage.replaceText`:

```swift
if let currentValue = element.value as? String, !currentValue.isEmpty {
    element.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
}
element.typeText(text)
```

delete 키를 **한 번에 몰아 보내고, 실제로 다 지워졌는지 검증하지 않는다.** 긴 텍스트일수록, 특히 여러 줄 입력(TextView)에서 일부 키가 유실된다. 유실 개수가 실행마다 달라지므로 **간헐 실패(flaky)** 로 나타난다.

**앱은 정상이다.** 화면에 보이는 문자열을 그대로 저장했을 뿐이고, 잘못 만든 것은 테스트 헬퍼다.

### 12.5 수정

지운 뒤 값을 다시 읽어 줄어들 때까지 라운드를 반복하도록 바꿨다:

```swift
var previousValue: String?

for _ in 0..<10 {
    guard let currentValue = element.value as? String,
          !currentValue.isEmpty,
          currentValue != previousValue
    else { break }

    previousValue = currentValue
    element.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
}
```

빈 필드는 placeholder를 `value`로 돌려주는 XCUITest 특성이 있어 `!currentValue.isEmpty`만으로는 루프가 안 끝난다. **"직전 라운드와 값이 같으면 중단"** 조건이 그 경우를 처리한다.

**검증**: 수정 후 `xcodebuild test -test-iterations 3`으로 동일 테스트를 3회 반복 실행 → **3회 전부 통과**(203초 / 192초 / 197초).

다만 이것이 절대적 증명은 아니다. 원래 간헐 실패였고 수정 전에도 재실행 1회는 통과했으므로, 3회 연속 통과는 **재발 확률을 크게 낮춘 근거이지 무결성 증명이 아니다.** 정직하게 "3회 연속 통과로 확인"까지만 주장한다. 수정 계열 테스트(프로젝트/게이지/라이브러리 수정 등)가 `replaceText`를 공유하므로, 이후 라운드에서 동일 증상이 다시 보이면 이 절을 먼저 의심할 것.

### 12.6 교훈 (포트폴리오 가치)

1. **간헐 실패를 "flaky니까 재실행"으로 넘기지 않았다.** 재실행하면 통과하는 실패였지만, 실패 스크린샷까지 파고들어 `"Knit Purl back a037e971"`이라는 물증으로 원인을 특정했다. 넘겼다면 이 결함은 계속 남아 다른 수정 계열 테스트를 무작위로 오염시켰을 것이다.
2. **테스트 실패 = 앱 버그가 아니다.** DEF-006(좌표 맹목 탭), DEF-009(POM 필수값 누락)에 이어 세 번째로, 원인이 테스트 하네스 자신이었던 사례.
3. **검증 없이 쓰인 통과 주장은 검증해야 한다.** 커밋 메시지의 "still pass unchanged"는 실제로 돌려보니 4개 중 3개였다.
4. **입력 필드를 지우는 헬퍼는 "지웠다고 가정"하면 안 된다** — 지운 결과를 다시 읽어 확인해야 한다. 이것이 이번 작업으로 확립된 규칙이다.

### 12.7 부수적으로 확인/추가한 것

- 새 세그먼트 컨트롤(`workspaceTabPicker`)에 접근성 ID가 없어 탭 전환을 POM으로 잡을 수 없었다 → `AppAccessibilityID.Workspace.tabPicker = "workspace.tab"` 추가(`01f1303`). POM에서는 `app.segmentedControls["workspace.tab"].buttons["프로젝트 정보"]`로 잡힌다.
- **탭 분리로 인한 회귀는 없다** — 4개 테스트 전부 최종 통과. 행안내 패널은 `counterPanel` → `mainWorkspaceArea` 안에 있어 기본 탭(뜨는 중)에 그대로 남아 있음을 코드로도 확인했다.
- 시뮬레이터 destination 함정: `name=iPhone 16 Pro`에 `OS:latest`가 붙으면 최신 런타임(26.5)에서 그 기기를 찾아 실패한다. 이 기기는 18.5 런타임에만 존재하므로 **device id로 고정**해야 한다.

---

## 13. 역할 재정의 (2026-07-29) — 이 절이 이전 역할 조항을 대체한다

지금부터 QA도, 환경 구축도 하은이 직접 한다. Claude는 실행자가 아니라 조력자다.

**기본 원칙**
- 하은이 명령을 직접 실행하고, Claude는 안내·설명·진단만 한다.
- 어떤 작업도 선제적으로 대신 하지 않는다. "제가 해드릴까요?" 제안도 하지 않는다.
- 파일 생성·수정·커밋·push는 하은의 명시적 요청이 있을 때만.

**Claude가 하는 것**
1. 길 안내: 하은이 목표를 말하면 다음 한 단계의 실행 명령 + 그 단계의 목적 한두 줄. 전체 절차를 한 번에 쏟지 말고 단계별로.
2. 에러 진단: 에러 출력을 붙여넣으면 출력 해석 → 원인 판단 → 해결 명령 순으로 답한다. "확인해보세요"로 끝내지 않는다. 실행은 하은이 한다.
3. 사실 조사: 코드/DB/로그/설정 질문에 읽기 전용으로 확인하고 답한다. 판단을 얹지 않는다.
4. 원리 설명: "왜"를 물으면 설명. 안 물어도 다음에 혼자 못 할 내용이면 한두 줄만 덧붙인다.
5. 리뷰: 하은이 작성한 TC/코드/문서를 요청 시 리뷰. 고쳐주지 말고 문제점과 이유를 지적만.

**Claude가 하지 않는 것**
- 환경 구축 대행 (하은이 명시 요청한 스크립트만 예외)
- TC 설계, 테스트 코드 작성, 탐색적 테스트
- 결함 리포트 작성, 심각도/우선순위 판정
- 회귀 범위 결정, 릴리즈 판정, QA 문서 대필
- 요청받지 않은 파일 변경·정리·개선·제안

**유일한 예외**
- 하은이 이슈를 지목해 "수정해"라고 명시하면 그 결함 수정은 수행한다(개발자 역할). 수정 후 해당 이슈에 Resolved 코멘트까지만 — Verify/Close는 하은 전권.
