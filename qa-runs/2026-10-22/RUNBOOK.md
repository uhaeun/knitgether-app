# 실행 환경과 재현 방법

기준 커밋 `75a9882eb841044aba1067ddbc703a985a4515d2`. 저장소 기존 테스트·제품 코드는 수정하지 않고 이 폴더에 추가 실험과 증거를 둔다. `report.md`가 최종 판정이며 스크립트 존재는 실행 성공을 뜻하지 않는다.

- 앱: Xcode 26.6 / iOS Simulator SDK 26.5, Debug arm64, 서명 비활성. `build-retry.log`에 실제 명령과 결과.
- A: iPhone 17 Pro / iOS 26.5 / `840CB58F-9AD8-4403-A8C3-3E2D5F93B0C5`.
- B: iPhone 17 Pro / iOS 26.5 / `311D4B83-D09B-4237-824C-ABCDD09264D1`.
- Appium 3.1.2 / XCUITest 12.3.4 / `127.0.0.1:14723`; WDA 포트 18101/18102. 최초에는 기기별 derivedData를 사용했고, 복구 중에는 기존 Library/Developer의 WDA 빌드 산출물도 재사용했다. 앱 컨테이너와 시뮬레이터 UDID는 별개다.
- Nest 서버: `127.0.0.1:3301`, `NODE_ENV=test`, 저장소 package-lock 기반 `npm ci`, Prisma 생성 후 빌드.
- 기록 프록시: `127.0.0.1:3300` → `3301`. `proxy.py`가 인증 토큰·비밀번호를 마스킹한 `http.jsonl` 기록.
- PostgreSQL 14.18: 전용 `pgdata`, `127.0.0.1:55432`, 사용자 `knitgether`, DB `knitgether_qa_20261022`, 로컬 trust 인증. 저장소 기본 docker-compose의 5433 DB는 사용하지 않았다. API·앱·SQL 모두 이 DB를 바라본다.
- 파일 저장소: 이 실행 폴더의 `storage/`. `db:reset-test`는 사용하지 않는다.

## 기존 테스트 재사용

저장소 루트에서 다음 명령으로 18개 항목을 실행했다. 자동 teardown은 이 실행에서 만든 API 테스트 계정만 삭제한다. iOS 시나리오용 계정과 경합 실험 데이터는 전용 DB에 남겨 증거를 보존한다.

```bash
API_BASE_URL=http://127.0.0.1:3300/api/v1 \
DB_HOST=127.0.0.1 DB_PORT=55432 DB_USER=knitgether DB_PASSWORD='' \
DB_NAME=knitgether_qa_20261022 \
qa-runs/2026-10-22/venv/bin/python -m pytest \
  qa/api-tests/test_02_last_write_wins.py \
  qa/api-tests/test_03_create_idempotency.py \
  qa/api-tests/test_11_sync_loss_regression.py \
  qa/api-tests/test_17_conflict_timestamp_precision.py \
  qa/api-tests/test_19_patch_replace_contract.py \
  -v --junitxml=qa-runs/2026-10-22/evidence/api-existing.xml
```

`run_sync.py`는 기존 `AuthPage`, `MyKnittingPage`, `WorkspacePage`, `ProjectInfoPage`, 계정·프로젝트 생성 유틸을 재사용한다. 전용 두 기기를 기동하고 이 커밋의 앱 빌드 및 API·프록시·Appium을 준비한 뒤 실행한다. 새 계정에 UI로 로그인하며 같은 프로젝트를 실제로 연다. 메모 충돌 뒤 다른 필드 보존 검사는 API로 이름·즐겨찾기·현재 단수를 추가 변경한 조건임을 구분한다. 재충돌의 중간 쓰기도 API다. 이 추가 쓰기까지 두 기기 UI로 수행했다고 해석하지 않는다.

`run_ui03.py`는 완료된 `run_sync.py`의 두 세션 중 A에 재접속한다. 전용 계정의 `preferredUnits`를 SQL로 바꾸고 앱이 프로필을 실제 GET한 것을 확인한 뒤 같은 게이지 입력을 반복한다. 마지막에는 로그아웃 및 온보딩 초기화로 단위 선택 UI 제거를 확인한다. 개인 계정·개인 시뮬레이터에서 실행하지 않는다.

`probe_race.py`는 10개의 새 프로젝트에 각 2개 동시 PATCH를 전송하고 DB를 직접 조회한다. `QA_API_URL=http://127.0.0.1:3301/api/v1`로 프록시 없는 대조도 실행했다. 이 결과는 API 층이며 iOS E2E로 집계하지 않는다.

## 환경 장애 및 공간 확보

최초 앱 빌드가 약 133MB의 디스크 잔여 공간에서 실패했다. 실패 로그를 보존한 후 이번 실행의 실패 빌드 산출물만 제거했다. 사용자의 추가 요청에 따라 npm 다운로드 캐시, CocoaPods 다운로드 캐시, 실행 중인 Gradle 프로세스가 없는 것을 확인한 뒤 Gradle 9.3.1 빌드 캐시를 정리했다. 파일 경로와 전후 공간은 `evidence/cleanup.txt`에 있다. 소스, 기존 QA 증거, DB, 기존 시뮬레이터는 삭제하지 않았다. 캐시 재사용이 사라져 향후 해당 도구의 다운로드·빌드 시간이 늘 수 있다.

디스크 부족 시점에 만든 A/B의 첫 부팅은 데이터 마이그레이션 실패가 있었다. 이번 실행에서 새로 만든 A/B만 초기화해 부팅을 재시도했다. `boot-*-retry.log`와 시작 화면 스크린샷을 보존한다. 초기 환경 실패를 제품 FAIL로 합산하지 않는다.

## 증거 취급

### 최종 복구 시도 및 종료 상태

Finder 메타데이터가 Documents 아래 번들에 다시 붙어, `ditto --norsrc --noextattr`로 앱을 `/tmp/knitgether-qa-20261022/KnitGether.app`에 복사하고 ad-hoc 서명·검증했다. `QA_APP_PATH`가 이 복사본을 가리키도록 설정했다. `app-build-identity.txt`의 원본·복사본 debug dylib UUID가 일치한다.

`QA_WDA_DERIVED_DATA`로 기존 WDA 산출물을 Xcode에서 실행하는 방식과, `QA_WDA_APP_PATH`로 임시 폴더의 WDA 복사본을 직접 실행하는 방식을 시도했다. 후자의 테스트 전용 패키징에는 Xcode 제공 `lib_TestingInterop.dylib`를 복사·서명하는 복구 실험도 포함한다. 원래 WDA 소스와 제품 소스를 수정한 것은 아니다. 최종적으로 WDA 포트의 정상 제어 세션을 확보하지 못했다. 위 대체 실행 옵션은 통과가 검증된 해결책이 아니다.

추가 테스트용 iOS 18.5 기기 `1DA534CF-4ADC-4D93-8618-3D93109B0743` / `9DDF93D9-E584-4D4A-BC35-CC689D2BA6D7`는 호환성 대조에만 사용한 뒤 삭제했다. 원래 있던 기기는 보존했다. 이번 iOS 26.5 A/B는 종료 상태로 남겨 두었고 서버·프록시·Appium·전용 PostgreSQL도 종료했다. 전용 DB 디렉터리와 DB 덤프는 보존했다. 실제 화면 자동화와 추가 스크립트의 종단 실행은 아직 검증되지 않았다.

`evidence/http.jsonl`의 인증 헤더는 수집하지 않으며 토큰·비밀번호 필드는 마스킹한다. Appium 로그에 기록될 수 있는 테스트 비밀번호도 전달 전 마스킹한다. 계정 이메일은 생성된 `example.com` 테스트 주소다. DB 덤프·세션 식별자·빌드·가상환경·DB 데이터 디렉터리는 이 폴더의 `.gitignore`로 Git 추적에서 제외한다. 제품 소스의 Git diff가 없는지도 최종 확인한다.
