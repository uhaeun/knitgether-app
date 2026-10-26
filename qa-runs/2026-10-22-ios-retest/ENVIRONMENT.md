# iOS 자동화 환경 복구 기록

기준 커밋 `75a9882eb841044aba1067ddbc703a985a4515d2`. macOS 26.5.1, Xcode 26.6 (17F113), iOS Simulator 26.5, Appium 3.1.2, xcuitest driver 12.3.4. A/B 모두 iPhone 17 Pro, 별도 UDID/앱 컨테이너.

- A: `840CB58F-9AD8-4403-A8C3-3E2D5F93B0C5`, WDA 18101
- B: `311D4B83-D09B-4237-824C-ABCDD09264D1`, WDA 18102
- 전용 DB `knitgether_qa_ios_20261022`, PostgreSQL 55432. 이전 QA DB와 기존 사용자 DB 보존.
- Nest 3301, 기록 프록시 3300, Appium 14723. 앱은 두 기기 모두 `http://127.0.0.1:3300/api/v1` 사용.

## 복구와 원인 구분

1. 현재 Xcode와 맞는 WDA를 `/tmp/knitgether-ios-retest-20261022/WDA`에 새로 빌드했다. Documents 경로의 FinderInfo 서명 실패와 과거 런타임 조합 문제를 피하고, 두 장치에서 실제 WDA HTTP 제어를 확보했다. `evidence/wda-build.log`, `wda-status-A/B.json`.
2. Documents 안 앱 빌드가 멈춘 원인은 프로세스 샘플상 `NSFileCoordinator`의 재귀 읽기 대기였다. `evidence/app-build-hang-sample.txt`. 커밋 소스를 `git archive`로 `/tmp/knitgether-ios-retest-20261022/Source`에 복제해 정상 서명 빌드했다. `evidence/app-build-outside.log`의 BUILD SUCCEEDED 확인.
3. CODE_SIGNING_ALLOWED=NO 산출물의 사후 임시 서명 대신, `CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=-`로 정상 시뮬레이터 빌드했다. `app-Simulated.xcent`에 앱 식별자 포함. 이전 패키지에서 API 로그인 200 뒤 화면 로그인 실패가 있었으나 새 빌드에서는 두 기기 실제 로그인 확인. 패키징/환경 문제로 분류하며 제품 결함으로 확정하지 않는다.
4. 추가 실행 스크립트의 로그인/로그아웃 후 홈 이동 처리, 설치 직후 일시 Busy 처리, API 버전값 대신 DB 시간 문자열을 보낸 오류를 수정했다. 모두 이 폴더의 검증 코드만 수정했다. 실패 시도는 `evidence/recovery-attempts`에 보존했다.

제품 코드 및 기존 테스트는 수정하지 않았다. `source-integrity.json`의 248개 파일은 기준 커밋과 임시 빌드 소스가 바이트 단위로 동일하다. 실제 설치 UUID는 `installed-app-0/1.txt`. 원래 시뮬레이터나 사용자 데이터를 초기화하지 않았다.

## 빌드 재현

```sh
xcodebuild -project /Users/yuha/.appium/node_modules/appium-xcuitest-driver/node_modules/appium-webdriveragent/WebDriverAgent.xcodeproj -scheme WebDriverAgentRunner -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/knitgether-ios-retest-20261022/WDA -jobs 2 IPHONEOS_DEPLOYMENT_TARGET=26.5 CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build-for-testing
```

임시 Source 디렉터리에서:

```sh
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/knitgether-ios-retest-20261022/App -jobs 2 ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build
```

`run_sync.py`는 기존 qa/appium 페이지 객체를 재사용한다. `run_pure_ui.py`는 API 쓰기 없이 두 기기의 UI로 변경한다. `run_ui03.py`는 QA_DEVICE_INDEX=0/1로 각각 실행한다. 새 세션 생성에는 QA_APP_PATH, QA_WDA_DERIVED_DATA, QA_PLATFORM_VERSION를 설정하고, 세션 재사용에는 QA_REUSE_SESSIONS=1을 사용한다. 세션 ID는 로컬 보관하고 공유 대상에서 제외한다.

## 2026-10-24 재개

이전 UI-03 A 실행은 설정·프로필 확인 뒤 중단되었고, 시뮬레이터 종료로 WDA 18101 연결이 끊겼다. 첫 두 PASS를 전체 UI-03 PASS로 취급하지 않았다. 원본은 `evidence/recovery-attempts/interrupted-ui03-A`에 보존했다. A/B 전용 기기를 재부팅하고 `restore_sessions.py`로 새 제어 세션을 생성했다. 기존 앱·계정·격리 DB를 재사용한다. 동시 부팅 때 호스트 load average가 급증해 QA B를 잠시 종료하고 A부터 복구했다. 제품 실패로 분류하지 않는다. `evidence/reboot-A.log`, `session-restore.log`에 복구 이력을 남겼다.

추가 하네스 문제는 `recovery-attempts/favorite-*`, `unchanged-draft`, `form-save-tap`에 보존했다. 키보드 닫기·스위치 실값 확인·좌표 안정화 후 저장·폼 종료 확인을 추가했고, 같은 저장값을 재입력해 저장이 비활성화된 시도는 유효한 충돌 검사로 집계하지 않았다. 최종 완료 시도의 결과만 본 보고서에 집계하되, 이전 실패 이력은 삭제하지 않는다.

B 복구에서는 첫 WDA 시작 실패 뒤에도 테스트 실행 자식 프로세스가 남아 있어 해당 QA B의 xcodebuild만 종료했다. 별도 `/tmp/knitgether-ios-retest-20261022/WDA-B` 작업 경로와 상세 로그를 사용했다. B 재부팅 후 홈 화면은 표시됐으나 `simctl get_app_container`가 지연됐다. A의 12개 UI-03 완료 후 A 세션/기기를 종료하고, B의 launchd_sim 부모를 확인한 뒤 그 아래 containermanagerd 및 containermanagerd_system만 재시작했다. 이후 컨테이너 조회와 WDA 실행이 복구됐다. 내부 서비스 지연의 근본 원인은 확정하지 않았으며 제품 결함으로 분류하지 않는다. `B-containermanager-sample.txt`, `session-restore-B.log`, `appium.log` 참조. B는 원래 UDID를 유지했고 앱 컨테이너와 계정 데이터를 삭제하지 않았다.

UI-03은 호스트 부담을 줄이기 위해 A 완료 후 B를 실행했다. 두 기기의 동시 편집 SYNC-11은 이전 완료 흐름에서 A/B를 함께 실행했다. WDA 작업 경로 분리는 복구 조치이지 그 자체를 원인 확정으로 해석하지 않는다.

버전값 하네스 오류의 세부 근거: SQL row_to_json의 updatedAt는 시간대 표식 없는 문자열이었고 API는 UTC Z 문자열을 반환했다. 서버는 `new Date(body.baseUpdatedAt).getTime()`으로 비교한다 (`server/src/projects/projects.service.ts:1476`). 따라서 SQL 표시 문자열을 그대로 요청의 기준 버전으로 쓰지 않고 앱과 동일하게 API가 반환한 updatedAt를 사용하도록 보완했다. 초기 진행 설명의 ‘정밀도 차이’보다 시간대 표식/표현 차이가 정확한 설명이다. 이 오류는 제품 충돌 실패로 집계하지 않는다.

완료 후 A/B QA 세션·시뮬레이터와 전용 API/프록시/Appium/PostgreSQL을 종료했다. DB 파일·덤프·앱·증거는 보존했다.
