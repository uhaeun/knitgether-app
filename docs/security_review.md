# 보안 점검 기록 (2026-09-01)

대상: 브랜치 fix/qa-cycle-defects, 커밋 f93aacc 작업 트리. 방법: 정적 점검(코드와 설정 읽기, git 이력 패턴 검색, npm audit). 실행 재현은 하지 않았다.
작성: Claude (사실 조사). 심각도와 결함 등록 여부는 하은이 판정한다. 등급 열의 값은 권고이며 추정이다.

## 결론

1. public 전환을 막는 시크릿은 git 이력에 없다. 이력에 나온 값은 전부 로컬 기본값과 테스트용 문자열이다.
2. 계정 경계(다른 사용자 데이터 접근)는 서버가 강제한다. 노션 1차 조사 결론과 같다.
3. 남은 구멍은 셋이다. 로그인 시도 제한 없음, 업로드 경로 의존성(multer) high 취약점, 업로드 파일 내용 검증 부재. 나머지는 관찰 수준이다.
4. "로컬에 데이터를 저장해도 되는가"에 대한 답은 된다. 근거는 4절 C-1.

## 1. 점검 범위와 결과 요약

| # | 영역 | 확인한 것 | 결과 |
| --- | --- | --- | --- |
| A | git 이력 시크릿 | 전체 이력 diff에서 키, 토큰, 접속 문자열, 비밀번호 패턴 검색. .env 계열 파일 추가 이력 | 실제 시크릿 없음 |
| B | 서버 인증과 권한 | JWT 시크릿 처리, 개발 토큰 경로, 소유권 스코프, 비밀번호 해시, 로그인 제한 | 로그인 시도 제한 없음 (B-3) |
| C | 클라이언트 저장 | 캐시 파일 보호 등급, Keychain 접근 등급, 로그 노출, 계정별 분리 | 관찰 2건 |
| D | 전송 구간 | ATS 설정, 개발 스킴 http | 양호 |
| E | 입력 검증 | DTO whitelist, 길이 상한, 파일 업로드 타입과 크기, 경로 조작 | 파일 내용 검증 부재 (E-2) |
| F | 의존성 | npm audit (운영 의존성만) | high 5건 (F-1) |
| G | 정보 노출 | 에러 메시지의 계정 존재 노출, 개인 식별 정보(호스트명, 경로) | 관찰 2건 |

## 2. A. git 이력 시크릿

명령: `git log --all -p` 전체를 대상으로 PRIVATE KEY, AKIA, JWT 형태, JWT_SECRET=, PASSWORD=, postgres://user:pass@, sk-, ghp_ 패턴 검색. `.env` 계열 파일의 추가 이력 조회.

| 발견 | 내용 | 판정 |
| --- | --- | --- |
| DATABASE_URL | postgresql://knitgether:knitgether@localhost:5433 (docs, .env.example, CI 워크플로) | 로컬 기본값. docker-compose 컨테이너 계정. 위험 없음 |
| AUTH_JWT_SECRET | replace-with-a-long-random-secret (.env.example), test-jwt-secret (e2e) | 자리표시자. 위험 없음 |
| PASSWORD | appium-pass-1234, pytest-pass-1234 (테스트 코드) | 테스트 계정. 위험 없음 |
| .env 추적 | server/.env.example만 추적. server/.env는 이력에 없음 | 양호 |

public 전환 전 남은 확인: 시크릿은 아니지만 개인 식별 정보로 볼 수 있는 값이 있다. 판단은 하은. `haeun.local`(개발용 Mac 호스트명, docs/09와 스킴), `~/...` 절대 경로(문서 일부), 시뮬레이터 UDID(docs/06). 사내 정보는 아니다.

## 3. B. 서버 인증과 권한

| # | 항목 | 확인 결과 | 판정 | 등급(추정) |
| --- | --- | --- | --- | --- |
| B-1 | JWT 시크릿 | AUTH_JWT_SECRET 없으면 development, test에서만 고정값 사용. 그 외 환경은 AUTH_JWT_SECRET_REQUIRED로 기동 실패 (access-token.service.ts:100~115) | 양호. fail-closed | 없음 |
| B-2 | 개발 토큰 | DEV_AUTH_TOKEN 경로는 NODE_ENV가 development 또는 test일 때만 열린다 (api-auth.guard.ts:65~80) | 양호 | 없음 |
| B-3 | 로그인 시도 제한 | /auth/login에 rate limit, 계정 잠금, 지연 어느 것도 없다. Throttler 모듈 미사용. 토큰 만료 30일 | 무제한 비밀번호 추측이 가능하다. 서버가 인터넷에 노출되면 실질 위험 | 중 |
| B-4 | 비밀번호 해시 | PBKDF2-SHA256, 반복 120,000회, 16바이트 랜덤 솔트, timingSafeEqual 비교 (password.service.ts) | 동작한다. OWASP 2023 권고(PBKDF2-SHA256 600,000회)보다 낮다 | 하 |
| B-5 | 정적 API 토큰 | KNITGETHER_API_TOKENS의 userId:token 목록을 `===`로 비교 (api-auth.guard.ts:98) | 타이밍 세이프 비교가 아니다. 운영에서 정적 토큰이 필요한지부터 판단 | 하 |
| B-6 | 소유권 스코프 | ownerId는 항상 @CurrentUser(JWT sub)에서 온다. 조회는 (id, ownerId) 쌍 | 양호. 노션 1차 조사와 동일 | 없음 |
| B-7 | 대량 할당 | ValidationPipe whitelist + forbidNonWhitelisted (app.setup.ts) | 양호. DTO에 없는 필드는 400 | 없음 |

## 4. C. 클라이언트 저장

| # | 항목 | 확인 결과 | 판정 | 등급(추정) |
| --- | --- | --- | --- | --- |
| C-1 | 캐시 파일 보호 | Application Support/KnitGether/RemoteCaches/<baseURL>/<userId>/ 아래 JSON. 코드에 FileProtection 지정 없음. iOS 기본 보호 등급(첫 잠금 해제 후 접근 가능)이 적용된다고 본다(추정, 프로젝트 entitlement에 Data Protection 미설정) | 저장해도 된다. 데이터가 뜨개 프로젝트 기록이라 기기 잠금 해제 전 암호화면 충분하다. 토큰은 여기 없고 Keychain에 있다 | 없음 |
| C-2 | Keychain | kSecClassGenericPassword, 접근 등급 미지정(기본 WhenUnlocked), iCloud 동기화 없음 (AuthSessionStore.swift) | 양호 | 없음 |
| C-3 | 로그 | print, NSLog, Logger 호출 중 토큰, 비밀번호, 세션을 출력하는 곳 없음 | 양호 | 없음 |
| C-4 | 계정별 분리 | 캐시 경로가 userId로 나뉜다. 로그아웃 후 이전 계정 캐시는 디스크에 남는다 | 기능 결함으로는 이미 관리 중(02 AUTH-06, 10 DEF-05~07). 보안으로는 기기 물리 접근이 전제라 낮다 | 하 |
| C-5 | 로컬 전용 모드 | KNITGETHER_API_BASE_URL 없으면 인증 없이 로컬 파일만 쓴다 | 서버 없이 쓰는 모드라 인증 부재가 설계다. 별도 위험 없음 | 없음 |

## 5. D. 전송 구간

| # | 항목 | 확인 결과 | 판정 |
| --- | --- | --- | --- |
| D-1 | ATS | NSAllowsLocalNetworking만 true. NSAllowsArbitraryLoads 없음 (KnitGether-Info.plist:23~27) | 양호. 로컬 네트워크 외 http는 iOS가 차단한다. 운영 서버는 https여야 동작한다 |
| D-2 | 개발 스킴 | Local Simulator, Local Device, 기본 KnitGether 스킴 세 개 모두 KNITGETHER_DEV_AUTH_TOKEN 환경변수를 갖는다 | 스킴 환경변수는 Xcode에서 실행할 때만 주입되고 아카이브 빌드에는 들어가지 않는다(추정). 서버 쪽은 B-2로 이중 차단. 확인 방법: 릴리즈 빌드에서 ProcessInfo 환경 덤프 |

## 6. E. 입력 검증

| # | 항목 | 확인 결과 | 판정 | 등급(추정) |
| --- | --- | --- | --- | --- |
| E-1 | 텍스트 길이 | f93aacc로 30자, 500자, 80자, 256자 상한이 DTO에 들어갔다. 본문 크기는 express 기본 100KB | 양호. 02 PROJ-02 | 없음 |
| E-2 | 업로드 파일 내용 | PDF는 확장자와 클라이언트가 선언한 mimetype만 검사 (patterns.service.ts:319). 진행 사진과 드로잉은 타입 검사 없음, contentType을 클라 값 그대로 저장 | 매직 바이트 검사가 없어 임의 파일을 PDF로 저장할 수 있다. 소비자가 네이티브 앱뿐이라 실질 영향은 낮다. 크기 제한은 있다(50MB, 15MB, 10MB) | 하 |
| E-3 | 경로 조작 | storage key는 ownerId, patternId, fileId로 구성되고 id는 DTO IsUUID 검증을 거친다. 절대 경로가 루트 밖이면 예외 (local-file-storage.service.ts:184~192) | 양호 | 없음 |
| E-4 | 숫자 상한 | currentRow @Max 없음 (노션 1차 조사 잔존) | 통계와 화면 오염 가능. 보안보다 데이터 계약 문제 | 하 |
| E-5 | 작업 세션 시각 | endedAt > startedAt, 24시간 이하 검증 추가됨 (f93aacc) | 노션 1차 조사 #15 해소. 재검증 필요 | 없음 |

## 7. F. 의존성

`npm audit --omit=dev` 결과 high 5건, critical 0건.

| 패키지 | 경로 | 내용 | 영향 |
| --- | --- | --- | --- |
| multer 1.0.0~2.1.1 | @nestjs/platform-express 경유 | 깊게 중첩된 필드명으로 DoS, 중단된 업로드 미정리로 DoS | 업로드 엔드포인트 3개(도안, 진행 사진, 드로잉)에 직접 해당 |
| deepmerge-ts <8.0.0 | prisma, @prisma/config 경유 | 재귀 객체 병합 시 스택 고갈 | 빌드 시점 도구. 런타임 요청 경로 아님 |

권고: `npm audit fix`로 해결되는지 확인하고, 안 되면 @nestjs/platform-express를 multer 2.1.2 이상을 쓰는 버전으로 올린다. 등급(추정) 중. 서버 e2e 재실행으로 회귀 확인.

## 8. G. 정보 노출

| # | 항목 | 확인 결과 | 판정 |
| --- | --- | --- | --- |
| G-1 | 계정 존재 노출 | 로그인 실패는 "Email or password is incorrect."로 구분하지 않는다. 회원가입은 409 "Email is already registered."로 구분한다 | 가입 여부를 회원가입 엔드포인트로 알 수 있다. 대부분 서비스가 감수하는 트레이드오프. 등급(추정) 하 |
| G-2 | 개발 로그 | NODE_ENV=development에서만 메서드, URL, 상태, 소요시간 출력. 본문과 헤더는 출력하지 않는다 | 양호 |
| G-3 | admin.html | server/public/admin.html 1,196줄. 서버가 정적 파일로 서빙하지 않고 fetch 호출도 없다. 외부 CDN 폰트를 참조한다 | 정적 목업으로 보인다(추정). 용도와 잔존 여부는 하은 판단. 미조사 |

## 9. 결함 또는 관찰 등록 후보 (2026-09-01 처리: SEC-A → OBS-4-01 배포 전 조건, SEC-B → OBS-4-02, SEC-C → OBS-4-03. 배포 이력 없음이 관찰 판정의 근거)

등록 여부와 심각도는 하은이 정한다. 발견 시점은 전부 QA 신규 발견, 방법은 정적 점검이다.

| 후보 | 항목 | 권고 처리 |
| --- | --- | --- |
| SEC-A | B-3 로그인 시도 제한 없음 | 결함. 재현: Postman Runner로 같은 이메일에 잘못된 비밀번호 100회 연속 전송, 전부 401이고 지연이나 차단 없음 확인 |
| SEC-B | F-1 multer high 취약점 | 결함 또는 운영 리스크. 재현: npm audit 출력 첨부 |
| SEC-C | E-2 업로드 파일 내용 검증 부재 | 관찰(14 문서). 재현: 텍스트 파일을 .pdf로 이름 바꿔 mimetype application/pdf로 업로드, 201 확인 |
| SEC-D | B-4 PBKDF2 반복 횟수 | 관찰 |
| SEC-E | G-1 회원가입 계정 존재 노출 | 관찰 |
| SEC-F | E-4 currentRow 상한 | 노션 1차 조사에서 이미 판정 대기 |

## 10. 미조사

- 서버가 실제로 인터넷에 배포된 적이 있는지. 배포 이력이 없으면 B-3, F-1의 실질 위험은 배포 시점으로 미뤄진다
- 릴리즈 빌드에 스킴 환경변수가 들어가지 않는다는 점의 실측 (D-2)
- Keychain 항목이 앱 삭제 후에도 남는지(iOS 기본 동작상 남는다). 재설치 시 이전 세션 복원 여부
- admin.html의 용도 (G-3)
- (확인 완료) 백업 JSON 내보내기에는 토큰과 비밀번호가 없다. SettingsBackupSnapshot은 프로필, 프로젝트, 창고, 스킬, 사전, 게이지, 사용 기록, 사진 데이터만 담는다(DataBackupExportViewModel.swift:11~26). 사진 원본이 Data로 들어가 파일이 커질 수 있고, 공유 시트로 내보낸 파일은 암호화되지 않는다

## 11. 도구로 재검증하는 방법 (하은이 직접)

- git 이력: `brew install gitleaks` 후 `gitleaks git --redact -v .` (이 문서의 A절은 grep 패턴이라 gitleaks가 더 넓다)
- 의존성: `cd server && npm audit --omit=dev`
- 로그인 제한: Postman Collection Runner, iterations 50, 같은 요청. 응답 시간과 코드가 일정하면 제한 없음
- 파일 검증: Postman form-data로 `echo hello > fake.pdf` 업로드
- ATS: Charles로 http://<서버 IP> 배포 서버를 흉내 내면 iOS가 차단하는지. 로컬 네트워크 대역이면 예외라 공인 IP나 도메인으로 해야 한다
