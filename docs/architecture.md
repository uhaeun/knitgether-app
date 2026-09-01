# KnitGether 아키텍처: 전환 전, 전환 후, 바꾼 이유

작성 2026-09-01. 기준은 브랜치 fix/qa-cycle-defects 커밋 f93aacc의 코드와 git 이력, docs/superpowers/specs의 설계 문서, docs/spec/원본_v2.2.md다. 코드에서 확인한 사실과 문서에 적힌 결정은 그대로 적고, 문서에 없는 이유는 추정이라고 표시했다. 추정은 마지막 절에 질문으로 모았다.
작성: Claude (사실 조사). 판단과 답변은 하은.

## 결론

1. 현재 앱은 서버-클라이언트 구조다. 화면과 뷰모델은 Repository 프로토콜만 보고, 그 뒤에서 OfflineFirst 래퍼가 로컬 JSON 캐시와 원격 API를 합친다. 서버는 NestJS, Prisma, PostgreSQL이고 파일은 서버 디스크에 둔다.
2. 이 구조는 2026-07-04 설계서에서 시작해 07-11에 갖춰졌고, 07-29 커밋 bf2b001이 QA 기준이다. 그 전에 기획서 v2.2대로 만든 CoreData 로컬 앱과, 이 저장소의 초기 Repository 앱이 있었다. 둘은 전사(前史)로만 다룬다.
3. 서버를 붙인 이유는 문서상 둘이다. 기획서가 미뤄둔 데이터 동기화를 구현하려는 것(7/4 설계서)과, QA 포트폴리오에서 UI, API, DB 세 층을 검증하려는 것(PROJECT_HISTORY 0절). 어느 쪽이 먼저였는지는 문서에 없다.

## 1. 현재 구조

```
iOS 앱 (SwiftUI)
  View
    → ViewModel (@MainActor, ObservableObject)
      → Repository 프로토콜 (ProjectRepository, PatternRepository, LibraryRepository, ...)
        → OfflineFirst*Repository            ← 온라인 모드에서만
            ├ Local*Repository  (JSON 파일 캐시, 계정별 디렉토리)
            └ Remote*Repository (APIClient → URLSession)
                                                 │ HTTPS/HTTP, Bearer JWT
서버 (NestJS)                                    ▼
  Controller → ApiAuthGuard (JWT → userId)
    → Service (소유권 스코프, 검증, 트랜잭션)
      → Prisma → PostgreSQL (docker compose)
      → LocalFileStorageService → server/storage/ (PDF, 사진, 드로잉)
```

조립은 AppRepositoryContainer.makeDefault 한 곳에서 한다. 환경변수 KNITGETHER_API_BASE_URL이 있으면 위 구조를, 없으면 Local*Repository만 꽂는다(로컬 모드. 자세한 비교는 docs/modes.md). 로그인, 로그아웃, 계정 전환 시 AppRepositoryStore가 컨테이너를 다시 만들어 캐시 디렉토리를 계정 스코프로 바꾼다.

### 계층별 책임

| 계층 | 책임 | 하지 않는 것 | 대표 파일 |
| --- | --- | --- | --- |
| View | 화면 그리기, 사용자 입력을 뷰모델 메서드로 전달, 접근성 ID | 저장 규칙, 네트워크 | Views/MyKnitting/ProjectWorkspaceView.swift |
| ViewModel | 화면 상태, 입력 검증(길이 상한, 음수 보정), 세션 시작과 종료, 오류 메시지 선택 | 엔드포인트, HTTP 상태 코드 판단 | ViewModels/ProjectWorkspaceViewModel.swift |
| Repository 프로토콜 | 도메인 단위 CRUD 계약 | 구현 | Repositories/Protocols/*.swift |
| OfflineFirst | 로컬 선반영, 원격 시도, 실패 분류(지연 vs 거부), 롤백, pending 재개, 캐시 갱신 | 화면 문구 | Repositories/OfflineFirst*Repository.swift |
| Local | JSON 파일 읽기 쓰기, tombstone, 롤백 스냅샷, 샘플 시드 | 네트워크 | Repositories/Local/LocalSampleRepositories.swift (2,605줄) |
| Remote | 요청 본문과 응답 매핑, 파일 캐시 | 재시도 정책 | Repositories/Remote/*.swift |
| APIClient | URL 조립, Bearer 토큰 주입, 응답 코드 해석, 토큰 있는 요청의 401 시 세션 제거 | 도메인 지식 | Networking/APIClient.swift |
| AuthSessionStore | 토큰은 Keychain, 프로필은 UserDefaults | | Networking/AuthSessionStore.swift |
| 서버 Guard | Bearer 검증, userId 주입. JWT, 정적 토큰, 개발 토큰(개발과 테스트 환경만) 순 | | server/src/auth/api-auth.guard.ts |
| 서버 Service | ownerId 스코프, DTO 밖 검증(세션 시각, 충돌), 파일 저장 호출 | | server/src/projects/projects.service.ts |
| Prisma 스키마 | 25개 모델. 소프트 삭제 deletedAt, 스냅샷 필드, FK 제약조건 부재 참조(바늘, 스킬 ID 배열) | | server/prisma/schema.prisma |

### 데이터 모델의 결

서버 스키마는 25개 모델이다. 연결 방식이 항목마다 다르다는 점이 QA 문서 01의 치명도 2위(연결 정합성) 근거다.

| 연결 | 방식 | 스키마 |
| --- | --- | --- |
| 프로젝트와 도안 | 프로젝트당 복사본 1개. ProjectPatternCopy.projectId @unique | 1:1 복사 |
| 프로젝트와 실 | ProjectYarnLink(연결) + ProjectYarnUsage(사용 기록) + 스냅샷 필드 | 연결 테이블 + 스냅샷 |
| 프로젝트와 바늘 | ProjectNeedleLink + 스냅샷. FK 제약조건 부재 | 연결 테이블 + 스냅샷 |
| 프로젝트와 도구 | ProjectToolLink N:M, @@unique([projectId, toolId]) | 연결 테이블, 스냅샷 없음 |
| 프로젝트와 스킬 | relatedSkillIds 문자열 배열. FK 제약조건 부재 | ID 배열 |
| 프로젝트와 카운터 | RowCounter 서버 옵셔널, 클라 필수 | 계약 불일치 (02 CNT-03) |

## 2. 여기까지 온 경로 (전사)

현재 구조를 이해하는 데 필요한 만큼만 적는다. 1세대 코드는 이 저장소에 없어 독자가 검증할 수 없으므로, 여기 적은 사실은 전부 이 저장소 안의 문서(원본_v2.2.md, 07_mvp_feature_parity)와 git 이력에서 확인되는 것으로 한정했다.

| | 1세대 CoreData 앱 | 2세대 초기 Repository 앱 | 3세대 서버-클라이언트 (현재) |
| --- | --- | --- | --- |
| 시기 | 기획서 v2.0~v2.2 시기 (샘플 날짜 2026.06) | 2026-06-02 ~ 06-07, 커밋 6건 | 2026-07-04 설계, 07-05 ~ 07-11 구현 53건, 07-29 QA 기준 bf2b001 |
| 위치 | 별도 프로젝트 knitgether-mvp (07 parity 문서 기준 View 117개) | 이 저장소 | 이 저장소 |
| 저장 | CoreData, 로컬 전용. 기획서 2절 "Data Sync: MVP에서는 제외" | Codable JSON 파일. 모델에 SyncStatus가 6/4부터 존재 | 서버 PostgreSQL 원본, 기기는 계정별 JSON 캐시 |
| 화면 | 홈 허브, 기획서가 TabView 금지 | TabView 3탭 | TabView 5탭 + 온보딩 + 세션 게이트 |

세 가지만 기억하면 된다. 기획서는 로컬 전용 CoreData 앱을 요구했고 실제로 그렇게 한 번 만들어졌다. 이 저장소는 그것을 이어받지 않고 6/2에 동기화를 염두에 둔 Repository 구조로 새로 시작했다. 7/10 parity 문서는 3세대가 1세대의 기능을 "서버 구조로 복원"하는 과정을 기록한다. 즉 기획서와 현재 코드의 괴리(02 문서가 "데이터 구조 전면 변경"이라 부른 것)는 이 갈아타기에서 왔다.

## 3. 바꾼 이유

### 문서에 근거가 있는 것

| 변경 | 이유 | 근거 |
| --- | --- | --- |
| 로컬 전용 → 서버 동기화 | 기획서가 "추후 확장"으로 미뤄둔 동기화를 구현. 계정 단위 데이터, 파일 업로드와 다운로드, 프로젝트 상태 동기화가 목표 | docs/superpowers/specs/2026-07-04-ios-sync-api-server-design.md Purpose |
| 서버 프레임워크 NestJS | 첫 서버는 웹앱이 아니라 구조화된 API 서비스가 필요하다. 모듈, 검증, 인증, 파일 처리, 유지보수성에서 Next.js보다 적합 | 같은 문서 Decision |
| Repository 프로토콜 유지 | 이미 데이터 접근이 프로토콜 뒤에 있으므로 원격 구현체를 옆에 추가하면 화면과 뷰모델을 다시 쓰지 않아도 된다 | 같은 문서 Purpose, iOS Integration |
| OfflineFirst 계층 | 설계서는 "오프라인 우선 저장은 나중에 추가 가능"으로 열어 두었고, 7/11 커밋 f426a96에서 구현 | 같은 문서 Open Decisions, 커밋 f426a96 |
| UI, API, DB 3층 검증 | QA 포트폴리오의 차별점으로 처음부터 합의. DB QA 경력과 이어지는 지점 | docs/qa/portfolio/PROJECT_HISTORY.md 0절 |
| 작업 공간 2탭 분리 | 한 세로 스크롤에 12개 섹션이 쌓여 정보 과부하. 뜨는 중 쓰는 것(카운터, 도안, 행안내, 타이머)과 정보를 분리 | docs/superpowers/specs/2026-07-27-workspace-two-tab-design.md |
| 캐시 디렉토리를 계정별로 분리 | 계정 간 데이터 노출 방지 | docs/06_architecture_audit 갱신 항목 |

### 문서에 없어 추정인 것

- CoreData를 버리고 Codable JSON 파일로 간 이유. 추정: 서버 응답(JSON)과 로컬 저장을 같은 Codable 타입으로 다루면 매핑 계층이 하나 줄고, 테스트에서 파일 경로를 주입해 격리하기 쉽다. 기획서는 SwiftData만 금지했고 CoreData를 요구했으므로 명시적 결정이 있었을 것이다.
- 홈 허브를 버리고 TabView로 간 이유. 기획서 3절은 TabView 사용 금지였다. 2세대 첫 커밋(6/2)부터 TabView였다.
- 1세대 프로젝트를 이어가지 않고 6/2에 새 저장소로 시작한 이유.
- 7/4 설계서의 서명 URL 업로드(S3 호환 스토리지)를 서버 스트리밍과 로컬 디스크로 바꾼 이유. 추정: 로컬 개발 환경에서 외부 스토리지 없이 돌리기 위해.

## 4. 설계서와 구현의 차이

7/4 설계서와 f93aacc 코드를 대조했다.

| 설계서 | 구현 | 상태 |
| --- | --- | --- |
| Apple 로그인을 운영 인증으로 | 이메일과 비밀번호, PBKDF2 해시, JWT 30일 | 다름. Apple 로그인 없음 |
| 파일은 서명 URL로 직접 오브젝트 스토리지 업로드 | multipart로 서버가 받아 server/storage/ 디스크에 저장 | 다름 |
| GET /sync?since= 변경분 조회, POST /sync 일괄 반영 | 없음. 도메인별 전체 조회(GET /projects 등) | 미구현 |
| 충돌: 오래된 updatedAt 저장 요청은 409, 클라는 갱신 | 7/29 기준 미구현(known issue #14, 02 SYNC-11 한시 허용). 2026-09-01 f93aacc에서 baseUpdatedAt 기반 409 구현 | 두 달 뒤 구현. 02 SYNC-11 v2.2 |
| 오류 코드 422 검증 실패 | 400 VALIDATION_FAILED | 코드 번호 다름 |
| 게이지는 기본 동기화 후 모델링 | GaugeRecord, GaugeTarget, GaugeSwatch, GaugeMeasurement 구현. 단 GaugeTarget은 OfflineFirst 없이 원격 전용 | 구현, 오프라인 예외 |

## 5. 이 구조가 QA에 뜻하는 것

- 결함은 경계에 숨는다. OfflineFirst의 실패 분류(URLError와 5xx는 지연, 그 외는 롤백)가 SYNC-09, SYNC-10 불일치의 근원이었고, 프로젝트 전체 PATCH가 자식 레코드를 전체 교체하는 서버 구현(SYNC-08)이 DEF-01, DEF-02의 근원이었다. 계층이 나뉘어 있어 어느 층의 결함인지 특정할 수 있었다.
- 검증 층위가 셋이다. 화면(Appium, XCUITest), API(Postman, pytest), DB(psql). 같은 조작의 결과를 세 층에서 대조하는 07 문서 방식은 이 구조라서 가능하다.
- 테스트 가능성이 설계에 들어 있다. Repository 프로토콜은 뷰모델 단위 테스트에서 가짜 구현으로 바꿀 수 있고, 캐시 경로와 API 주소와 토큰은 환경변수로 주입된다. XCUITest와 Appium이 KNITGETHER_LOCAL_CACHE_ROOT_DIRECTORY로 격리된 캐시를 쓰는 근거다.
- 반대로 구조가 만든 위험도 있다. 클라 필수와 서버 옵셔널이 어긋난 RowCounter(CNT-03), FK 제약조건 없는 바늘과 스킬 참조(LINK-03, LINK-04), 도메인마다 다른 오프라인 지원 범위(게이지 목표와 진행 사진은 원격 전용)는 전부 계층을 나눈 결과로 생긴 계약 지점이다.

## 6. 확인 필요

꼭 필요한 것 하나. 면접에서 "왜 서버를 붙였나"에 답할 문장이 된다.

1. 서버 전환의 첫 동기는 동기화 기능 자체였나, QA 포트폴리오였나.

있으면 좋은 것. 3절 추정을 확정하지만 없어도 문서는 성립한다.

2. knitgether-mvp를 이어가지 않고 6/2에 새로 시작한 이유.
3. CoreData 대신 JSON 파일 저장을 택한 결정은 누가 언제 했나.
4. 홈 허브 대신 TabView로 간 이유. 기획서 금지 사항을 뒤집은 결정.

## 부록. 파일 지도

| 경로 | 내용 |
| --- | --- |
| KnitGether/Models/ | Codable 도메인 모델 25개. SyncStatus 열거형 포함 |
| KnitGether/Repositories/Protocols/ | 프로토콜 10개 |
| KnitGether/Repositories/Local/ | JSON 파일 구현. LocalSampleRepositories.swift에 프로젝트, 도안, 창고, 스킬, 사전, 프로필, 게이지 기록, 인증 구현이 모여 있음 |
| KnitGether/Repositories/Remote/ | API 구현 10개 |
| KnitGether/Repositories/OfflineFirst*.swift | 래퍼 7개 (프로젝트, 도안, 창고, 스킬, 사전, 프로필, 게이지 기록. 게이지 기록 래퍼는 Local/LocalSampleRepositories.swift:1874에 있음) |
| KnitGether/Repositories/AppRepositoryContainer.swift | 모드 결정과 조립 |
| KnitGether/Networking/ | APIClient, APIConfiguration, APIError, AuthSessionStore |
| KnitGether/ViewModels/ | 19개 |
| KnitGether/Views/ | 탭별 디렉토리 (MyKnitting, Library, Tool, Onboarding, Shared) |
| server/src/ | auth, profile, projects, patterns, library, skills, dictionary, gauge-records, gauge-targets, storage, health, database |
| server/prisma/schema.prisma | 모델 25개 |
| server/test/ | e2e 14 파일 (AI 작성, 회귀 장치로만 사용) |
| docs/superpowers/specs/ | 설계서 5편 (7/4 서버, 7/5 프로젝트 CRUD, 7/6 도안 파일, 7/7 작업 공간 UX, 7/27 2탭) |
| docs/06_architecture_audit_2026-07-09.md | 서버 전환 직후 감사. API 목록과 남은 리스크 |
| docs/07_mvp_feature_parity_2026-07-10.md | 1세대와 3세대 화면 1:1 대조 |
