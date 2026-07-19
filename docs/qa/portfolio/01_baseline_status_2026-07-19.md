# 베이스라인 상태 기록 — 2026-07-19

## 대상 리포지토리 (확정)

- **활성 리포**: `/Users/yuha/Desktop/Projects/KnitGether` → `github.com/uhaeun/knitgether-app` (branch: `main`)
- 구 리포 `knitgether-mvp`(마지막 커밋 6/30 스냅샷)는 포트폴리오 대상 **아님** — 혼동 주의
- 앱/테스트 베이스라인: `main` 최신 로컬 커밋 기준
- 문서 베이스라인 커밋: `8070209` 2026-07-19 `docs(qa): start portfolio baseline`
- 원격 대비 상태: `main...origin/main [ahead 17]` — 아직 push 전

## 베이스라인 확정 상태

- 2026-07-19 기준 미커밋 변경사항 없음.
- 아래 17개 커밋을 QA 베이스라인으로 사용한다.
  - `b096e5b` `chore(dev): support local API device testing`
  - `d02f55f` `fix(ios): improve save feedback and skill sync`
  - `b8c73b0` `test(ios): add POM core user flow UI tests`
  - `8070209` `docs(qa): start portfolio baseline`
  - `2fe2c82` `test(ios): restore core user flow test name`
  - `d3907be` `docs(qa): document POM screen criteria`
  - 테스트 계획서, 스모크 TC, 1회차 실행 리포트 추가 커밋
  - SMK-004 프로젝트 재실행 유지 자동화 추가 커밋
  - SMK-005/006 작업공간 단수/작업시간 자동화 추가 커밋
  - SMK-008/009 오프라인 cache/pending retry 자동화 추가 커밋
  - SMK-010 계정 전환 cache scope 분리 자동화 추가 커밋
  - 프로젝트 수정/삭제/재실행 유지 자동화 추가 커밋
  - 서버 OFF + cache 없음 오프라인 안내 자동화 추가 커밋
  - RowInstruction 저장/수정/삭제/재실행 유지 자동화 추가 커밋
  - 기존 계정 로그인 재진입 자동화 추가 커밋
  - 로그아웃 후 프로필 로드 오류 미노출 수정/자동화 추가 커밋
  - WorkSession 삭제/재실행 유지 자동화 추가 커밋
- 테스트 수치와 결함 기록은 이 베이스라인 위에서만 갱신한다.

## 프로젝트 구조

| 구성요소 | 위치 | 비고 |
|---|---|---|
| iOS 앱 | `KnitGether/` + `KnitGether.xcodeproj` | SwiftUI, CoreData, Offline-first |
| iOS Unit 테스트 | `KnitGetherTests/` | Swift 파일 42개 |
| iOS UI 테스트 | `KnitGetherUITests/` | XCUITest POM 구조, Swift 파일 12개 |
| 서버 | `server/` | NestJS + Prisma, `npm test` = jest e2e (`--runInBand`) |
| 서버 테스트 | `server/` 내 spec | e2e spec 12개 |

## 검증 수치 (2026-07-19 베이스라인)

| 검증 | 명령/대상 | 결과 |
|---|---|---|
| 서버 build | `cd server && npm run build` | PASS |
| 서버 E2E | `cd server && npm test` | PASS, 12 suites / 104 tests |
| iOS Unit | `xcodebuild test ... -only-testing:KnitGetherTests` | PASS, 327 tests |
| iOS UI | `xcodebuild test ... -only-testing:KnitGetherUITests` | PASS, 15 UI test functions / xcresult testsCount 19 |
| 공백 검사 | `git diff --check` | PASS |

## 자동화 베이스라인

- XCUITest POM 1차 구현 완료.
- 자동화된 핵심 흐름: 회원가입 → 온보딩 → 스킬 테스트 저장 → 프로젝트 생성 → 게이지 기록 저장 → 성공 메시지 확인.
- 자동화된 재실행 흐름: 프로젝트 생성 → 앱 종료/재실행 → 같은 프로젝트가 목록에 유지되는지 확인.
- 자동화된 작업공간 흐름: 단수 증가 → 앱 재실행 후 단수 유지, 작업시간 기록 → 세션 내역 진입, WorkSession 삭제 → 앱 재실행 후 미복구 확인.
- 자동화된 오프라인 흐름: 서버 OFF + cache fallback, 서버 OFF pending 프로젝트 저장 → 서버 복구 후 빈 cache에서 원격 조회 확인.
- 자동화된 오프라인 안내 흐름: 로그인 세션 유지 → 빈 cache 경로 + 서버 OFF 재실행 → 서버 연결 안내 표시 확인.
- 자동화된 계정 분리 흐름: A 계정 프로젝트 생성 → 로그아웃 → B 계정 가입/온보딩 → A 프로젝트 미노출 확인.
- 자동화된 프로젝트 변경 흐름: 프로젝트 생성 → 수정 → 재실행 유지 → 삭제 → 재실행 후 미노출 확인.
- 자동화된 작업공간 행안내 흐름: 행안내 모드 전환 → 행안내 저장 → 수정 → 재실행 유지 → 삭제 → 재실행 후 미노출 확인.
- 자동화된 기존 로그인 흐름: 기존 계정 생성 → 로그아웃 → 앱 재실행 → 로그인 → 메인 탭 진입 확인.
- 자동화된 로그아웃 오류 처리 흐름: 로그아웃 → 프로필 화면 진입 → `프로필을 불러오지 못했어요.` 미노출 확인.
- 아직 자동화되지 않은 후보: GaugeTarget 수정/삭제 UI, 잘못된 비밀번호 로그인.

## 재사용 가능한 기존 QA 자산

- `docs/qa/postman/knitgether-local.postman_collection.json` — API 테스트 출발점 (8절)
- `docs/qa/appium-charles-smoke.md` — 네트워크 로그 검증 참고 (8절)
- `docs/08_qa_automation_ids_2026-07-11.md` — 접근성 ID 목록 → XCUITest POM (9절)
- `docs/04_test_checklist.md` — 기존 체크리스트 → TC 마스터 시드 (6절)
- `docs/03_screen_structure.md` — 화면 구조 → RTM/POM 화면 목록 (5·9절)

## 테스트 실행 명령 (기록용)

- 서버: `cd server && npm test` (jest e2e, runInBand)
- iOS Unit: `xcodebuild test -project KnitGether.xcodeproj -scheme 'KnitGether Local Simulator' -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:KnitGetherTests`
- iOS UI: `xcodebuild test -project KnitGether.xcodeproj -scheme 'KnitGether Local Simulator' -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:KnitGetherUITests`
