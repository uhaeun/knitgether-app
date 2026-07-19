# 기능 목록·화면-API 연결 구조 (7/20 12:00–15:00 작성)

> 시드 자료: `docs/03_screen_structure.md`(화면 구조), `docs/qa/postman/knitgether-local.postman_collection.json`(API 목록), `docs/04_test_checklist.md`

## 기능 목록 + 리스크 등급

| # | 기능 영역 | 화면 | 데이터 변경 | 리스크 | 우선순위 |
|---|---|---|---|---|---|
| 1 | 온보딩 | OnboardingView | - | | P? |
| 2 | 회원가입/로그인 | AuthAccountView | 계정 생성 | 高 | P0 |
| 3 | 홈 | HomeView | - | | P? |
| 4 | 프로젝트 생성/수정/삭제 | AddProjectView, EditProjectView, MyKnittingView | CRUD+동기화 | 高 | P0 |
| 5 | Workspace (단수·행·작업시간) | WorkspaceView | 세션 기록 | 高 | P0 |
| 6 | PDF·PencilKit | PatternViewer | 파일 저장 | | P? |
| 7 | 게이지 계산기/측정 | GaugeCalculatorView, GaugeMeasureHubView | 기록 저장 | | P? |
| 8 | 스킬 테스트 | SkillTestResultView | 결과 저장 | | P? |
| 9 | 창고 (도구/도안/스킬) | ToolStorageView 등 | CRUD | | P? |
| 10 | Offline·Sync·Cache | (횡단) | 동기화·충돌 | 高 | P0 |
| 11 | 설정/계정 | Settings | 로그아웃·전환 | | P? |

<!-- 우선순위 기준: 데이터가 바뀌는 흐름(생성/수정/삭제/동기화/계정) = P0 -->

## 화면 ↔ API ↔ DB 매핑

| 화면 액션 | API 엔드포인트 | DB 테이블(Prisma 모델) | 오프라인 동작 |
|---|---|---|---|
| 예) 프로젝트 생성 | POST /projects | Project | 로컬 저장 후 재동기화 |

<!-- server/prisma/schema.prisma 와 Postman 컬렉션 대조하며 채우기 -->

## 테스트 환경표

| 항목 | 값 |
|---|---|
| 앱 빌드 (커밋) | (베이스라인 커밋 해시) |
| iOS 시뮬레이터 | |
| 실기기 | |
| 서버 | localhost (nest start) |
| DB | Prisma / (DB 종류·초기화 방법) |
| 테스트 계정 | |
| 네트워크 상태 조작 방법 | 서버 중단 / (Link Conditioner 등) |
