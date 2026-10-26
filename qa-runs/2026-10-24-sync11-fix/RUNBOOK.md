# 이번 실행 환경과 재검증

2026-10-24. 제품 수정·테스트·판정은 report.md. 현재 코드=75a9882 + 작업 트리 패치이며 commit/push하지 않았다.

전용 PostgreSQL14.18은 `/tmp/knitgether-sync11-fix-20261024/pgdata`, 사용자 knitgether, localhost55434, DB knitgether_qa_sync11_20261024다. 최초 migrations를 deploy했다. 이전 Documents QA 클러스터와 사용자5432/5433 데이터는 보존했다. 임시 디렉터리가 없어지면 evidence/isolated-fixed-db.dump를 새로운 전용 DB에 복원한다. 기존 DB를 drop/reset하지 않는다.

실제 DB 테스트는 저장소 루트에서:

```sh
QA_REAL_DATABASE_URL='postgresql://knitgether@127.0.0.1:55434/knitgether_qa_sync11_20261024?connection_limit=6' npm --prefix server run test:db:projects
npm --prefix server run test:e2e
```

선택적으로 QA_DB_EVIDENCE_PATH를 절대경로로 지정하면 실제 요청·응답·DB JSON을 저장한다. 테스트는 새 UUID 프로필/프로젝트를 만들고 전용 DB에 보존한다. 격리 경로의 임시 파일 저장소만 정리한다. 별도 Jest 설정을 사용해 기본 mock suite에서 실제 DB에 우발적으로 접속하지 않는다. 외부 API probe는 `probe_concurrency.py`를 기존 QA venv로 실행하며 QA_API_URL=3301 직접 또는3300 프록시를 선택한다. API 계정/프로젝트는 전용 DB에 보존한다.

수정 서버 실행은 server 폴더에서 NODE_ENV=test, DATABASE_URL=위 URL, AUTH_JWT_SECRET=실행 전용 값, PORT=3301, HOST=127.0.0.1, FILE_STORAGE_ROOT=이 실행의 storage 절대경로를 지정해 `node dist/main.js`를 사용했다. `npm run build` 성공 뒤 시작했다. proxy.py는3300→3301을 기록한다.

서버 직접/프록시40쌍 뒤 기존 pytest test_02·03·11·17·19를 실행했다. API_BASE_URL=3300/api/v1, DB_HOST=127.0.0.1, DB_PORT=55434, DB_USER=knitgether, DB_PASSWORD='', DB_NAME=위 전용 DB를 명시했다. 생성한 API 회귀 계정만 fixture teardown이 삭제한다.

Appium14723, iOS26.5 A/B UDID는 report.md. `restore_sessions.py`와 B 단독 `restore_b.py`로 기존 정상 서명 앱과 기기별 WDA 파생 빌드를 재사용했다. WDA는 /tmp/knitgether-ios-retest-20261022/WDA와 WDA-B에 있다. 앱은 같은 경로의 App/Build/Products/Debug-iphonesimulator/KnitGether.app이며 iOS 소스는 미변경이다. 기존 서명·WDA 복구의 상세 빌드 명령은 앞선 실행의 ENVIRONMENT.md에 있다.

현재 Appium 세션이 준비되면:

```sh
QA_REUSE_SESSIONS=1 QA_APP_PATH=/tmp/knitgether-ios-retest-20261022/App/Build/Products/Debug-iphonesimulator/KnitGether.app QA_PLATFORM_VERSION=26.5 qa-runs/2026-10-22/venv/bin/python qa-runs/2026-10-24-sync11-fix/run_sync.py
qa-runs/2026-10-22/venv/bin/python qa-runs/2026-10-24-sync11-fix/run_pure_ui.py
```

두 번째 스크립트는 첫 흐름의 세션과 프로젝트를 이어받는다. 새 재실행은 새 evidence 폴더를 사용해 이번 성공 증거를 덮어쓰지 않는다. 앱 환경은 KNITGETHER_API_BASE_URL=http://127.0.0.1:3300/api/v1, KNITGETHER_DISABLE_DEV_AUTH_TOKEN=1. phase actor는 실행 단계 주석이며 기기 자체의 네트워크 인증값은 아니다.

환경 복구 이력: 기본포트로 재기동하려던 첫 PostgreSQL 실패, Documents DB CopyFileRead 지연, A 컨테이너 서비스 조회 지연, B 기본 boot timeout. QA 기기 내부 컨테이너 서비스만 재시작하고 B startup timeout을360초로 늘렸다. 실패 원본 로그와 복구 대상 PID/명령은 evidence에 보존했다. 제품 결함으로 합산하지 않았다. 오래 남아 있던 이전 QA A screenshot 프로세스도 정리했다.

자료 취급: HTTP 인증 헤더를 수집하지 않고 token/password를 마스킹한다. Appium 파일/콘솔 원본, 세션 ID JSON, DB 덤프는 Git 제외 대상이다. Git diff와 소스/컴파일 산출물 해시·실제 설치 UUID·스크린샷/XML·DB·HTTP를 연결한다. 종료 상태는 evidence/shutdown.txt에 기록한다.
