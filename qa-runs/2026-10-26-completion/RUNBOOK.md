# 재현 및 증거

이전 QA 문서/테스트를 재사용했다. `server/test/projects-concurrency.real-db-spec.ts`는 실제 PostgreSQL/HTTP에만 실행하고 QA 전용 이름·localhost를 검사하며 개발 DATABASE_URL을 기본값으로 사용하지 않는다. 이 실행의 새 DB는 `knitgether_qa_sync11_completion_20261026`, 포트55439다. 기존 DB reset/drop은 하지 않는다.

```sh
QA_REAL_DATABASE_URL=postgresql://knitgether@127.0.0.1:55439/knitgether_qa_sync11_completion_20261026 \
QA_DB_EVIDENCE_PATH=/absolute/path/evidence/child-verified.json \
npm --prefix server run test:db:projects -- --json --outputFile=/absolute/path/evidence/child-jest-results.json
npm --prefix server run build
npm --prefix server run test:e2e
```

API 독립 회귀는 `API_BASE_URL=http://127.0.0.1:3301/api/v1`, `KG_NETGATE_FORWARD_PORT=3301`, DB_HOST127.0.0.1/DB_PORT55439/DB_USERknitgether/DB_PASSWORD빈값/DB_NAME위QA_DB/FILE_STORAGE_ROOT전용경로를 지정해 `python -m pytest qa/api-tests -q`로 실행했다. API 준비 health200을 확인한다. 테스트 계정은 매번 새 synthetic 계정으로 만든다.

Swift는 Xcode26.6/iOS26.5 QA A 대상으로 `xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,id=840CB58F-9AD8-4403-A8C3-3E2D5F93B0C5' -parallel-testing-enabled NO -derivedDataPath /tmp/knitgether-qa-completion-build-20261026 -only-testing:KnitGetherTests -resultBundlePath /tmp/knitgether-completion-unit-verified.xcresult`로 전체 실행했다. 최종 앱 dylib UUID는 A4EAA2CF-FBDA-38E2-ACC2-930BC3563327이며 두 기기의 installed-app-0/1.txt로 확인한다.

Appium14723/WDA18101·18102/mjpeg19101·19102, 프록시3300→API3301을 쓴다. `restore_sessions.py`로 두 QA 시뮬레이터의 독립 세션을 만들고 `setup_devices.py`로 같은 새 계정·프로젝트에 네이티브 로그인한 뒤 `QA_DEVICE_INDEX=0/1 python run_ui03.py`를 순차 실행한다. `run_final_ui.py`는 Swift 최종 성공 뒤 이 순서를 실행했다. QA_APP_PATH는 위 DerivedData의 Debug-iphonesimulator/KnitGether.app, QA_REUSE_SESSIONS=1, QA_REINSTALL_APP=1을 지정한다. 기기 전체를 erase하지 않는다.

UI-03은 설정·프로필·회원가입·온보딩5단계에 단위 선택/잘못된 안내가 없는지 검사한다. 합성 계정의 UserProfile.preferredUnits에 Metric/Imperial/US/cm를 각각 SQL 주입하고 앱을 종료/재시작해 실제 GET /profile 응답을 확인한다. 실제 필드에 8,10,20,30,40,55를 입력한 값과25코/30단/약100코/약165단을 PNG/XML에 남긴다. 최종 결과 JSON은 TC별 PASS/FAIL이고 중간626 앱 실행은 pre-final-ui03로 격리했다. 입력 후 실제 화면 결과가 보이는 PNG도 별도로 확인한다.

목/테스트 코드 문제와 실제 제품 FAIL을 구분한다. child-red는6개 신규 경로의 제품 FAIL, scope-red는3개 ID 범위의 제품 FAIL이다. server-tests/server-scope 등의 중간 실패는 목의 추가 조회/조건과 파일 이름 계약을 조정한 기록이며 최종 전체147 PASS와 구분한다. 원본 파일의 공백을 정규화하지 않는다.

공개 증거에서는 인증 헤더를 수집하지 않고 JSON의 token/password/secret 키를 재귀 마스킹한다. 세션 자격·비밀번호·Appium/서버 원본·DB dump·venv·xcresult는 로컬 전용이다. 공유 ZIP은 공개 manifest에 열거된 파일만 포함한다. Git whitespace 검사는 소스/문서에만 적용하고 원본 로그/SQL 결과는 제외한다.
