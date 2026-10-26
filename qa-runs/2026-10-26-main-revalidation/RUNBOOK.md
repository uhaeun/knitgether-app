# 재현 환경과 실행 순서

수정0ae2c64와 main6df5c4e의 통합 후보를 /tmp/knitgether-qa-latest-20261026에서 실행했다. 서버 제품 코드와 기존18개 회귀는0ae2c64와 같고 문서·검증 실행기를 추가했다. 이전 qa-runs/2026-10-26-latest와 결과물을 덮어쓰지 않았다.

전용 클러스터 /tmp/knitgether-qa-pg-20261026을 pg_ctl -o '-h 127.0.0.1 -p 55437'로 기동하고 새 DB knitgether_qa_sync11_revalidation_20261026을 만들었다. 이전 DB·사용자 DB는 reset/drop하지 않았다. server에서 Prisma generate, DATABASE_URL=QA DB로 migrate deploy, npm run build를 실행했다.

서버 환경: NODE_ENV=test, DATABASE_URL=postgresql://knitgether@127.0.0.1:55437/knitgether_qa_sync11_revalidation_20261026, AUTH_JWT_SECRET=실행 전용 값, HOST=127.0.0.1, PORT=3301, FILE_STORAGE_ROOT=/tmp/knitgether-qa-revalidation-storage-20261026. node dist/main.js로 시작하고 proxy.py를3300에 실행한다.

실제 DB: QA_REAL_DATABASE_URL에 위 URL과 connection_limit=6을 명시하고 QA_DB_EVIDENCE_PATH를 evidence/real-db-evidence.json의 절대 경로로 지정해 npm run test:db:projects를 실행한다. 기본 서버 회귀는 npm run test:e2e다. API는 API_BASE_URL=3300/api/v1, KG_NETGATE_FORWARD_PORT=3300, DB_HOST=127.0.0.1, DB_PORT=55437, DB_USER=knitgether, DB_PASSWORD 빈 값, DB_NAME=새 QA DB, FILE_STORAGE_ROOT=위 스토리지를 명시해 기존 qa/api-tests 전체를 실행한다. probe_concurrency.py와 probe_session_boundary.py는 직접3301과 실제SQL을 사용한다.

Python은 기존 qa-runs/2026-10-22/venv를 재사용했다. 새 환경에서는 qa/appium·qa/api-tests requirements의 의존성이 필요하다. 새 재실행은 새 결과 폴더·계정·DB명을 사용하고 실행기의 포트/DB명도 맞춘다.

A/B는 보고서의 기존 전용 QA UDID다. 부팅 완료 후 Appium14723의 /status ready를 확인하고 restore_sessions.py로 WDA18101/18102를 복구했다. /tmp/knitgether-ios-retest-20261022/WDA 및 WDA-B를 재사용하며 waitForIdleTimeout1초, startupTimeout360초를 설정했다. iOS 소스가 main과 같아 /tmp/knitgether-qa-app-20261026/Build/Products/Debug-iphonesimulator/KnitGether.app을 재사용했고 설치 UUID를 확인했다.

QA_REUSE_SESSIONS=1, QA_APP_PATH=위 앱, QA_PLATFORM_VERSION=26.5로 run_sync.py를 실행한다. 300초 관찰이 포함된다. 성공 후 run_pure_ui.py, 성공 후 run_boundary_ui.py를 실행한다. 마지막 실행기는 B만3999 관문을 사용해 단절을 만들고 복구 후 API3300으로 돌려놓는다. build_report.py와 update_docs.py는 완료 결과를 검증하고 문서를 생성·반영한다. update_docs.py는 중복 반영을 막으므로 같은 저장소에서 다시 실행하지 않는다.

토큰/비밀번호는 HTTP에서 마스킹하며 인증 헤더를 저장하지 않는다. dump, Appium 원본, 세션, 물리 기기 인벤토리는 로컬 전용이고 Git 제외다. shutdown.json처럼 QA 서비스·시뮬레이터·DB를 종료했으며 클러스터와 dump를 보존했다.
