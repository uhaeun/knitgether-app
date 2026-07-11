# KnitGether 서버-클라이언트 전환 감사

작성일: 2026-07-09  
최종 갱신: 2026-07-11

## 결론

현재 브랜치는 기존 CoreData 중심 앱을 서버-클라이언트 구조로 상당 부분 이전한 상태다. 서버는 NestJS/PostgreSQL/Prisma, iOS는 Repository + OfflineFirst cache 구조로 연결되어 있다.

자동 검증 기준으로는 서버 build/test, iOS generic build, iOS 전체 테스트가 통과했다. 다만 “출시 가능한 완성”으로 보려면 아직 수동 QA와 일부 제품 리스크 정리가 남아 있다.

## 현재 탭 구조

`ContentView`는 현재 5탭 구조다.

- `Home`: 프로필 이름, 프로젝트 개수, 진행/완성 수, 누적 작업시간, 이어서 작업, 최근 작업
- `My Knitting`: 프로젝트 목록과 작업공간
- `Tool`: 게이지 계산기, 스킬 테스트, 뜨개니게이션, 뜨개 사전, 뜨개 애니메이션
- `Library`: 도안/실/바늘/도구/스킬 창고
- `Settings`: 계정, 프로필, 데이터 백업/관리, 작업시간 통계, 상태 설명, 앱 정보

최초 실행 시에는 `OnboardingView`가 뜬다. 온보딩 안에서 계정 만들기/로그인 화면으로 들어갈 수 있고, 프로필 이름과 단위 저장 뒤 스킬 테스트로 이어진 다음 메인 탭으로 진입한다.

## 서버 API 현황

공통 prefix는 `/api/v1`이다.

| 도메인 | 서버 경로 | iOS Repository | 상태 |
| --- | --- | --- | --- |
| Health | `GET /health` | 없음 | 연결됨 |
| Auth | `POST /auth/register`, `POST /auth/login`, `GET /auth/me` | `RemoteAuthRepository` | 연결됨 |
| Profile | `GET /profile`, `PATCH /profile` | `RemoteProfileRepository` | 연결됨 |
| Projects | `GET/POST /projects`, `GET/PATCH/DELETE /projects/:id`, row counter/row instruction/work session partial API | `RemoteProjectRepository` | 연결됨 |
| Project pattern copy | `GET/POST /projects/:id/pattern-copy/file`, `GET/POST/DELETE /projects/:id/pattern-copy/drawing` | `RemoteProjectRepository`, `RemotePatternRepository` | 연결됨 |
| Project progress photos | `GET/POST /projects/:id/progress-photos`, `PATCH/DELETE /projects/:id/progress-photos/:photoId`, file download | `RemoteProjectProgressPhotoRepository` | 연결됨 |
| Project yarn usage | `GET/POST /projects/:id/yarn-usages`, `PATCH/DELETE /projects/:id/yarn-usages/:usageId` | `RemoteLibraryRepository` | 연결됨 |
| Patterns | `GET/POST /patterns`, `GET/PATCH/DELETE /patterns/:id`, `GET /patterns/:id/file` | `RemotePatternRepository` | 연결됨 |
| Library yarns | `GET/POST /library/yarns`, `PATCH/DELETE /library/yarns/:id`, `GET /library/yarns/:id/usages` | `RemoteLibraryRepository` | 연결됨 |
| Library needles | `GET/POST /library/needles`, `PATCH/DELETE /library/needles/:id` | `RemoteLibraryRepository` | 연결됨 |
| Library tools | `GET/POST /library/tools`, `PATCH/DELETE /library/tools/:id`, project link/unlink | `RemoteLibraryRepository` | 연결됨 |
| Gauge records | `GET/POST /gauge-records`, `PATCH/DELETE /gauge-records/:id` | `RemoteGaugeRecordRepository` | 연결됨 |
| Gauge targets | `GET/POST /gauge-targets`, `GET/PATCH/DELETE /gauge-targets/:id` | `RemoteGaugeTargetRepository` | 연결됨 |
| Skills | `GET/POST /skills`, `GET/PATCH/DELETE /skills/:id`, `GET /skill-animations` | `RemoteSkillRepository` | 연결됨 |
| Dictionary | `GET/POST /dictionary/terms`, `GET/PATCH/DELETE /dictionary/terms/:id` | `RemoteDictionaryRepository` | 연결됨 |

## iOS 기능 현황

### My Knitting / Workspace

구현됨:

- 프로젝트 생성/수정/삭제, 즐겨찾기, 상태/날짜/메모
- 프로젝트 작업공간
- 도안 3가지 연결 방식: 도안 창고에서 가져오기, PDF 직접 연결, 수동 도안
- 프로젝트 도안 PDF 보기, 도안 위 그리기 저장/삭제
- 단수 카운터, 현재/목표 단수 수정, 섹션/메모, 단수 리셋
- 행안내 추가/수정/삭제/대량 붙여넣기/스킬 태그
- 작업 시작/종료, 10초 미만 세션 저장 방지, 세션 목록/통계
- 도안 작업 중 사전/스킬 빠른 조회
- 진행 사진 추가/수정/삭제/파일 캐시
- 실 사용 기록 추가/수정/삭제, 수량 차감/복구
- 바늘 섹션, 도구 섹션, 프로젝트별 도구 연결
- 게이지 기록 연결 섹션

### Library

구현됨:

- `PatternLibraryView`: PDF 도안 업로드, 목록, 검색, 상세, 수정, 삭제, 파일 캐시
- `YarnLibraryView`: 실 추가/목록/검색/상세/수정/삭제, 사용량 조회
- `NeedleLibraryView`: 바늘 추가/목록/검색/상세/수정/삭제
- `ToolLibraryView`: 도구 추가/목록/검색/상세/수정/삭제
- `SkillLibraryView`: 스킬 추가/목록/검색/상세/수정/삭제

### Tool / Settings

구현됨:

- 계정 가입/로그인/로그아웃/현재 계정 조회
- 프로필 이름/단위 저장
- 데이터 백업 상태 설명 + 현재 데이터를 JSON 백업 파일로 생성/공유/가져오기
- 데이터 관리: 도메인별 저장 개수 확인
- 작업시간 통계: 전체/오늘/평균/프로젝트별 시간
- 작업 세션 목록: Settings에서 전체 프로젝트 세션 조회, 메모 수정, 삭제
- 게이지 계산기: 계산, 프로젝트/도안 연결, 세탁 전/후 기록 저장, 비교, 기록 불러오기/수정/삭제
- 상세 게이지 측정: Target/Swatch/Measurement 기반 저장/목록, 수동 측정, 사진 4점 측정 기본 플로우
- 스킬 테스트: 레벨 선택, 카드 진행, 결과
- 스킬 이해도 신호등 표시: `몰라요` 빨강, `헷갈려요` 주황, `잘 알아요` 초록
- 뜨개니게이션/뜨개 사전/뜨개 애니메이션 상세
- 프로젝트 상태 설명, 앱 정보
- MVP UI/UX parity 1차 복원: Settings 5번째 탭, 공통 카드 테마, Tool/Library 카드형 홈, Workspace 카드 섹션
- MVP UI/UX parity 2차 보강: Library 목록/상세 카드화, Workspace 카운터/행안내/도안/사진/실/바늘/도구/게이지 세부 패널 정리, Gauge Target/Swatch/Measurement 상세 카드화, Skill Test/Dictionary/Animation/Settings 세부 목록 테마 적용

## Offline-first 구조

`KNITGETHER_API_BASE_URL`이 있으면 서버 API + 로컬 캐시 구조로 동작한다.

- 인증 토큰 우선순위: `KNITGETHER_API_AUTH_TOKEN` -> 로그인 세션 토큰 -> `KNITGETHER_DEV_AUTH_TOKEN`
- 기본 원격 캐시 경로: `Application Support/KnitGether/RemoteCaches/<base-url-scope>/<user-id-scope>/`
- `KNITGETHER_LOCAL_CACHE_ROOT_DIRECTORY`로 테스트용 캐시 루트를 바꿀 수 있다.
- `KNITGETHER_LOCAL_CACHE_DIRECTORY`를 지정하면 명시 경로를 그대로 사용한다.
- 서버가 5xx 또는 네트워크 오류일 때 일부 변경은 local cache에 pending 상태로 보관된다.
- 서버가 400/404 같은 비재시도 오류를 반환하면 로컬 선반영 변경을 도메인별 스냅샷으로 롤백한다.

## 이번 갱신에서 추가로 고친 항목

- `PATCH /gauge-records/:id` 서버 API 추가
- `RemoteGaugeRecordRepository.updateGaugeRecord` 추가
- `OfflineFirstGaugeRecordRepository.updateGaugeRecord` 및 pending PATCH sync 추가
- `GaugeCalculatorViewModel.updateLoadedGaugeRecord` 추가
- `GaugeCalculatorView`에 불러온 기록 수정 저장 UX 추가
- `HomeDashboardViewModel`과 `HomeView` 추가
- `ContentView`에 Home 탭 추가
- `OnboardingViewModel`, `OnboardingView`, `UserDefaultsKeys.onboardingCompleted` 추가
- `DataBackupExportViewModel` 추가
- `DataBackupView`에서 JSON 백업 파일 생성/공유 연결
- 기본 원격 캐시 경로를 `baseURL + userId` 기준으로 분리
- 백업 JSON 가져오기/import 추가: 프로필, 프로젝트, 도안, 실/바늘/도구, 스킬, 사전, 게이지 기록, 실 사용 기록, 프로젝트별 도구 연결 복원
- 앱 실행 중 로그인/로그아웃/계정 변경 시 `AppRepositoryStore`가 Repository container를 재생성하고 탭 subtree를 새 캐시 scope로 전환
- OfflineFirst 계층의 400/404 비재시도 오류 롤백 정책 추가
- 프로젝트 하위 데이터 부분 수정 API 추가: row counter, row instruction, work session
- My Knitting/Library 최초 오프라인 사용자 안내 및 재시도 UX 추가
- 온보딩에 계정 만들기/로그인 진입과 스킬 테스트 진입 추가
- 스킬 중간 이해도 라벨을 `애매해요`에서 `헷갈려요`로 정리하고 기존 `애매해요` 데이터는 읽을 때 호환
- 스킬 목록/뜨개니게이션/애니메이션/행안내 태그에 신호등 배지 표시 강화
- 도안을 보면서 용어/스킬을 바로 찾는 `PatternSupportLookupView` 추가
- Settings 전역 `WorkSessionListView` 추가
- Appium UI 자동화용 accessibility identifier 보강: 탭, 프로젝트 CRUD, Library CRUD, Workspace 반복 입력, Gauge 측정 플로우, Settings/Auth/Onboarding
- Home/Onboarding 직접 시스템 색상 사용을 공통 `AppTheme` 기반으로 정리

## 검증 결과

2026-07-10 기준 자동 검증:

- 서버: `npm run build` -> 통과
- 서버: `npm test` -> 10 suites, 85 tests 통과
- iOS: `xcodebuild build -quiet -project KnitGether.xcodeproj -scheme KnitGether -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO` -> 통과
- iOS 전체 테스트: `xcodebuild test -quiet -project KnitGether.xcodeproj -scheme KnitGether -destination 'id=917A2C02-7D9B-482D-AAFC-C95A904B9A6D' -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO` -> 통과

이번 갱신 중 별도 확인한 좁은 테스트:

- `GaugeRecords` 서버 e2e
- `RemoteGaugeRecordRepositoryTests`
- `OfflineFirstGaugeRecordRepositoryTests`
- `GaugeCalculatorViewModelTests`
- `HomeDashboardSummaryTests`
- `OnboardingViewModelTests`
- `DataBackupExportViewModelTests`
- `AppRepositoryContainerTests`
- `OfflineFirstLibraryRepositoryTests`
- `OfflineFirstProjectRepositoryTests`
- `RemoteProjectRepositoryTests`
- `ProjectWorkspaceViewModelTests`
- `SkillAnimationViewModelTests`

2026-07-11 UI/UX parity 2차 작업 중 확인:

- iOS: `xcodebuild build -quiet -project KnitGether.xcodeproj -scheme KnitGether -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO` -> 통과
- iOS 전체 테스트: `xcodebuild test -quiet -project KnitGether.xcodeproj -scheme KnitGether -destination 'id=917A2C02-7D9B-482D-AAFC-C95A904B9A6D' -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO` -> 통과

2026-07-11 기능/QA 보강 중 확인:

- 서버: `npm run build` -> 통과
- 서버: `npm test` -> 10 suites, 85 tests 통과
- iOS: `xcodebuild build -quiet -project KnitGether.xcodeproj -scheme KnitGether -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO` -> 통과
- iOS 전체 테스트: `xcodebuild test -quiet -project KnitGether.xcodeproj -scheme KnitGether -destination 'id=917A2C02-7D9B-482D-AAFC-C95A904B9A6D' -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO` -> 통과

## 아직 남은 리스크

자동 테스트가 통과해도 아래는 출시 전 추가 설계/수동 QA가 필요하다.

- 전체 `Project` 저장 경로는 하위 배열을 재동기화하는 fallback으로 남아 있다. row counter/work session과 단건 row instruction은 partial API를 쓰지만, 행안내 대량 붙여넣기/재정렬은 아직 전체 저장 fallback을 사용한다.
- `KNITGETHER_LOCAL_CACHE_DIRECTORY`를 명시하면 계정별 분리 없이 해당 경로를 그대로 쓴다. 개발/테스트 편의를 위한 동작이다.
- Pattern/Skill/Dictionary 삭제에서 서버 404는 이미 삭제된 상태로 간주해 synced 처리한다. 다른 비재시도 오류는 롤백한다.
- 백업 JSON import는 앱 데이터 구조 복원까지 구현되었다. 서버 계정 간 병합 정책, 중복 충돌 해결 UI, 첨부 파일 원본까지 포함하는 완전한 백업 포맷은 별도 제품 설계가 필요하다.
- 최초 오프라인 안내는 My Knitting/Library에 우선 적용했다. Tool 탭 세부 화면은 오류 메시지와 재시도 흐름이 있으나 제품 문구 통일은 추가 QA가 필요하다.
- 기존 CoreData 앱과 1:1 픽셀 동일 UI는 아니다. 기능 중심으로 새 서버 구조에 맞게 재구성된 화면이 많다.

## 남은 완료 기준

다음 수동 QA까지 통과해야 “앱 완성”으로 판단할 수 있다.

- 회원가입/로그인/로그아웃/프로필 저장
- 프로젝트 생성/수정/삭제
- 도안 창고 PDF 업로드/보기/삭제
- 프로젝트 도안 가져오기/직접 PDF 연결/수동 입력/그리기
- 행안내 추가/수정/삭제/대량 붙여넣기/스킬 태그
- 실/바늘/도구 창고 추가/수정/삭제
- 프로젝트별 도구 연결/해제
- 실 사용 기록과 수량 차감/복구
- 작업시간 시작/종료/세션 목록/통계
- 진행 사진 추가/수정/삭제
- 게이지 계산/저장/수정/삭제/세탁 전후 비교
- 게이지 Target/Swatch/Measurement 플로우
- 스킬 테스트/사전/애니메이션 탐색
- 데이터 백업 JSON 생성/공유/가져오기
