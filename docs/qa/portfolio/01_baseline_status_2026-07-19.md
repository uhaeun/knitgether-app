# 베이스라인 상태 기록 — 2026-07-19

## 대상 리포지토리 (확정)

- **활성 리포**: `/Users/yuha/Desktop/Projects/KnitGether` → `github.com/uhaeun/knitgether-app` (branch: `main`)
- 구 리포 `knitgether-mvp`(마지막 커밋 6/30 스냅샷)는 포트폴리오 대상 **아님** — 혼동 주의
- 최신 커밋: `ff4066c` 2026-07-12 "Merge branch 'codex/ios-sync-api-project-list'"

## ⚠️ 미커밋 변경사항 (7/20 시작 전 반드시 처리)

- **30개 파일, +829/-60 라인이 커밋되지 않은 상태** (APIClient, Offline-first repositories, ViewModels, Views, server 등)
- 포트폴리오 완료 기준 "테스트 수치가 실제 실행 결과와 일치한다"를 지키려면 **베이스라인 커밋을 먼저 확정**해야 함
- 선택지: ① 변경사항 검토 후 커밋 → 그 커밋을 QA 베이스라인으로 고정 ② stash 후 ff4066c 기준으로 진행
- 결정 전까지 테스트 수치 기록 금지 (수치가 떠 있는 코드와 어긋남)

## 프로젝트 구조

| 구성요소 | 위치 | 비고 |
|---|---|---|
| iOS 앱 | `KnitGether/` + `KnitGether.xcodeproj` | SwiftUI, CoreData, Offline-first |
| iOS Unit 테스트 | `KnitGetherTests/` | Swift 파일 42개 |
| iOS UI 테스트 | `KnitGetherUITests/` | Swift 파일 2개 (KnitGetherUITests, LaunchTests) |
| 서버 | `server/` | NestJS + Prisma, `npm test` = jest e2e (`--runInBand`) |
| 서버 테스트 | `server/` 내 spec | spec 파일 12개 |

## 과거 기록 수치 (미검증 — 7/20 현재 브랜치에서 재실행 필요)

- 서버 E2E: 10/10 시나리오, 87 tests
- iOS Unit: 289/289 / iOS UI: 6/6 / Simulator Build 성공
- **상태: 미검증.** 베이스라인 커밋 확정 후 재실행하여 이 문서에 실제 수치로 갱신할 것

## 재사용 가능한 기존 QA 자산

- `docs/qa/postman/knitgether-local.postman_collection.json` — API 테스트 출발점 (8절)
- `docs/qa/appium-charles-smoke.md` — 네트워크 로그 검증 참고 (8절)
- `docs/08_qa_automation_ids_2026-07-11.md` — 접근성 ID 목록 → XCUITest POM (9절)
- `docs/04_test_checklist.md` — 기존 체크리스트 → TC 마스터 시드 (6절)
- `docs/03_screen_structure.md` — 화면 구조 → RTM/POM 화면 목록 (5·9절)

## 테스트 실행 명령 (기록용)

- 서버: `cd server && npm test` (jest e2e, runInBand)
- iOS: `xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,name=<기기명>'`
