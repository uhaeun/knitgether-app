# KnitGether QA Smoke Guide

이 문서는 서버-클라이언트-DB 구조에서 Appium, Postman, Charles로 빠르게 확인할 핵심 흐름을 정리한다.

## 준비

- API 서버: `http://127.0.0.1:3000/api/v1`
- 개발 토큰: `Authorization: Bearer dev-token`
- Xcode 실행 전 서버 health 확인: `GET /health`
- 시뮬레이터 문서 스캔은 VisionKit 미지원일 수 있다. 스캔은 iPhone 실기기에서 확인하고, 시뮬레이터는 PDF 파일 선택 흐름으로 대체한다.

## Appium Smoke Flow

1. 온보딩/계정
   - 회원가입 또는 로그인 화면 진입
   - 스킬 테스트 카드 진입
   - `몰라요`, `헷갈려요`, `잘 알아요` 중 하나씩 선택
   - 저장 후 Tool 또는 Settings에서 프로필/계정 상태 확인

2. 프로젝트 CRUD
   - `project.add` 탭
   - `project.form.name`, `project.form.status`, `project.form.memo` 입력
   - `project.save` 저장
   - 프로젝트 카드 선택 후 작업공간 진입
   - `workspace.project.edit`로 수정/삭제 검증

3. 도안 등록/연결
   - `workspace.pattern.direct_import`로 PDF 선택
   - 보관 분기에서 `도안창고에 보관하고 연결` 선택
   - 작업공간 PDF 미리보기 노출 확인
   - `workspace.pattern.scan`은 실기기에서 문서 스캔으로 PDF 생성 후 같은 보관 분기 확인
   - `workspace.pattern.library`에서 Library 원본 재사용 확인

4. 도안 보면서 학습 연결
   - `workspace.pattern.lookup` 진입
   - PDF에 포함된 스킬 약어가 작업공간 관련 스킬로 표시되는지 확인
   - 행안내 모드에서 `workspace.row_instruction.suggestion.add.{rowNumber}` 버튼으로 PDF/OCR 후보를 행안내에 추가
   - 행안내 스킬 칩을 눌러 사전/뜨개니메이션 상세로 이동

5. Library/Tool CRUD
   - 도안/실/바늘/도구 각각 추가, 수정, 삭제
   - 프로젝트 작업공간에서 실/바늘/도구 연결과 해제 확인
   - 실 사용 기록 저장 후 수량 차감/복구 확인

6. 게이지
   - 게이지 타깃 생성
   - 스와치/측정 기록 저장
   - 세탁 전/후 기록 연결 후 비교 표시 확인
   - 사진 4점 측정은 사진 선택, 4점 지정, 결과 저장까지 확인

## Charles 확인 포인트

- 로그인/회원가입 요청이 `/api/v1/auth/*`로 나가는지 확인
- 프로젝트 저장 시 `/api/v1/projects` 또는 `/api/v1/projects/{id}` payload에 row instruction, work session, pattern copy 상태가 들어가는지 확인
- 도안 창고 저장 선택 시 `/api/v1/patterns` 업로드 후 프로젝트 copy 연결 요청이 이어지는지 확인
- 프로젝트에만 연결 선택 시 Library 목록에는 새 원본이 생기지 않는지 확인
- 오프라인 전환 후 생성/수정한 항목이 앱 캐시에 남고, 서버 복구 후 재시도되는지 확인

## Postman 확인

- `docs/qa/postman/knitgether-local.postman_collection.json`을 import한다.
- `baseUrl`은 `http://127.0.0.1:3000/api/v1`, `token`은 `dev-token`으로 둔다.
- Health, Projects, Patterns, Library, Skills, Dictionary, Gauge 순서로 smoke 요청을 실행한다.
