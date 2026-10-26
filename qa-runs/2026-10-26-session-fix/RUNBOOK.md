# 실행 환경과 재현

기준은 71fc254361e30f1710cf5d24e27db1d12202d2d3이며 최신 main 6df5c4ef9473ac97437e3022a602eddd9ce92bbe를 이미 포함한다. 이전 증거는 덮어쓰지 않는다.

PostgreSQL14 전용 클러스터 `/tmp/knitgether-qa-pg-20261026`을127.0.0.1:55438에 시작하고 새 DB `knitgether_qa_sync11_session_20261026`을 생성했다. 사용자 DB와 이전 QA DB는 reset/drop하지 않았다. Prisma migrate deploy 후 `QA_REAL_DATABASE_URL=postgresql://knitgether@127.0.0.1:55438/knitgether_qa_sync11_session_20261026`과 `QA_DB_EVIDENCE_PATH` 절대 경로로 `npm --prefix server run test:db:projects`를 실행한다. red.log/red.json은 제품 변경 전 신규3회귀만 실행한 결과다. green.log/green.json은 수정 후 기존18개와 신규6개 전체 결과다. 중간 테스트 fixture에 불필요한 ownerId를 넣어400이 발생한1건은 테스트 코드 문제로 수정했다. 최종 회귀 결과와 제품 결함 재현3건을 구분한다.

서버는 NODE_ENV=test, 위 DATABASE_URL, AUTH_JWT_SECRET=실행 전용 값, HOST=127.0.0.1, PORT=3301, FILE_STORAGE_ROOT=/tmp/knitgether-qa-session-storage-20261026로 실행한다. proxy.py는3300에서 요청·응답을 기록하며 토큰/비밀번호를 마스킹하고 인증 헤더를 보존하지 않는다. API 회귀에는 DB_HOST127.0.0.1, DB_PORT55438, DB_USERknitgether, DB_PASSWORD 빈 값, DB_NAME 위 전용DB, API_BASE_URL=http://127.0.0.1:3300/api/v1, KG_NETGATE_FORWARD_PORT3300을 지정한다.

Python은 기존 `qa-runs/2026-10-22/venv/bin/python`을 재사용한다. Appium3.1.2/xcuitest12.3.4를14723에 띄우고 /status ready 이후 restore_sessions.py를 실행한다. 최초 준비 중 연결 거절은 환경 준비 문제이며 제품 FAIL로 집계하지 않는다. 기존 QA A/B(840CB58F-9AD8-4403-A8C3-3E2D5F93B0C5,311D4B83-D09B-4237-824C-ABCDD09264D1)의 컨테이너는 지우지 않는다. WDA는 기존 `/tmp/knitgether-ios-retest-20261022/WDA`와 WDA-B를 사용한다.

변경된 iOS 앱은 `/tmp/knitgether-qa-draft-20261026` DerivedData에서 arm64 Debug Simulator로 빌드한다. run_sync.py 실행 시 QA_REUSE_SESSIONS=1, QA_REINSTALL_APP=1, QA_APP_PATH를 해당 Build/Products/Debug-iphonesimulator/KnitGether.app으로 지정한다. 이후 run_pure_ui.py와 run_boundary_ui.py를 순서대로 실행한다.300초 자동 재시도 관찰을 유지한다. Boundary 실행기는 실제 terminate/relaunch 후 초안 복구·명시적 버리기·직접 저장 및 오프라인 생성/재생을 검증한다.

서버/DB 회귀는 API·SQL 검증이고 E2E 통과로 대체하지 않는다. iOS Swift 테스트는 계정·프로젝트 격리, 초안 저장/복구/삭제, 충돌·재조회 유지에 대한 보완 근거다. 로그인 토큰·Appium 세션·원본 내부 로그·xcresult·DB dump는 Git 제외다.
