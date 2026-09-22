# KnitGether QA 자동화 기준

작성일: 2026-07-11

## 목적

Appium, Postman, Charles 기반 포트폴리오 QA를 위해 앱에서 안정적으로 잡을 수 있는 접근성 식별자와 API 검증 흐름을 정리한다.

## iOS Appium 기준

식별자는 `KnitGether/Views/Shared/AppAccessibilityID.swift`에 모아 둔다.

핵심 시나리오:

- 탭 이동: `tab.home`, `tab.my_knitting`, `tab.tool`, `tab.library`, `tab.settings`
- 회원가입/로그인: `auth.mode`, `auth.email`, `auth.password`, `auth.display_name`, `auth.submit`, `auth.logout`
- 온보딩: `onboarding.login`, `onboarding.start`, `onboarding.complete`
- 프로젝트 CRUD: `project.add`, `project.form.name`, `project.form.status`, `project.form.yarn`, `project.form.needle`, `project.form.pattern`, `project.form.memo`, `project.save`, `project.delete`, `project.row.<uuid>`
- 작업공간 도안: `workspace.pattern.direct_import`, `workspace.pattern.library`, `workspace.pattern.manual`, `workspace.pattern.manual.title`, `workspace.pattern.manual.save`, `workspace.pattern.open_pdf`, `workspace.pattern.lookup`, `workspace.pattern.unlink`
- 단수/행안내: `workspace.counter.mode`, `workspace.counter.previous`, `workspace.counter.next`, `workspace.counter.edit_current`, `workspace.counter.edit_target`, `workspace.row_instruction.add`, `workspace.row_instruction.bulk`, `workspace.row_instruction.form.save`
- Library CRUD: `library.pattern.*`, `library.yarn.*`, `library.needle.*`, `library.tool.*`, `library.skill.*`
- 게이지: `tool.gauge.*`, `tool.gauge.target.*`, `tool.gauge.swatch.*`, `tool.gauge.measure.*`
- Settings: `settings.account`, `settings.profile`, `settings.statistics`, `settings.work_sessions`, `settings.backup`, `settings.data_management`

동적 row 식별자는 UUID를 포함한다. 테스트 데이터는 API 또는 앱에서 먼저 생성한 뒤 응답 UUID를 Appium 시나리오에 넘겨 사용한다.

## API/Postman 기준

기본 URL은 `http://127.0.0.1:3000/api/v1`이고 개발 토큰은 `Authorization: Bearer dev-token`을 사용한다.

우선 검증할 컬렉션:

- Health: `GET /health`
- Auth: `POST /auth/register`, `POST /auth/login`, `GET /auth/me`
- Projects: `GET/POST/PATCH/DELETE /projects`, row counter, row instructions, work sessions
- Library: patterns, yarns, needles, tools, project tool link/unlink
- Gauge: gauge records, gauge targets, swatches, measurements
- Dictionary/Skills: terms, skills, skill animations

## Charles 기준

수동 QA 중 확인할 네트워크 흐름:

- 로그인 이후 모든 요청에 bearer token이 붙는지
- 프로젝트 생성/수정/삭제가 `/api/v1/projects`로 나가는지
- 도안 PDF 업로드/다운로드가 파일 API를 타는지
- 진행 사진 업로드/다운로드가 project progress photo API를 타는지
- 400/404 응답 시 앱이 로컬 변경을 롤백하거나 이미 삭제된 상태로 처리하는지
- 서버 종료 후 앱이 로컬 캐시로 목록을 보여주는지

## 완료 판단

자동화는 빌드/테스트 통과만으로 충분하지 않다. 프로젝트, 도안, Library, Workspace, Gauge, Settings의 CRUD와 연결/해제 플로우를 실제 시뮬레이터에서 한 번씩 수행해야 완료로 판단한다.
