# 과거 문서와 실행 원본

현재 본문과 검증 결과는 [QA 문서 목차](README.md)에 정리했습니다. 반복 실행의 전체 로그·XML·화면과 이전 문서 묶음은 정리 전 시점에 보존했습니다.

- [전체 스냅샷: qa-history-2026-10-31](https://github.com/uhaeun/knitgether-app/tree/qa-history-2026-10-31)
- 기준 커밋: [`b2f916b`](https://github.com/uhaeun/knitgether-app/commit/b2f916bb9b248291a7f7ef421eb7739fda103d11)

| 원본 | 내용 |
|---|---|
| [날짜별 실행 묶음](https://github.com/uhaeun/knitgether-app/tree/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa-runs) | 수정 전 실패, 재시도, 화면·HTTP·SQL, 실행 스크립트와 환경 |
| [10월 4일 화면 검증](https://github.com/uhaeun/knitgether-app/tree/b2f916bb9b248291a7f7ef421eb7739fda103d11/docs/qa/submission/evidence/2026-10-04) | 도안 교체·페이지 복귀의 원본 PNG·XML·촬영 로그와 초기 시도 |
| [10월 4일 전체 재검증](https://github.com/uhaeun/knitgether-app/tree/b2f916bb9b248291a7f7ef421eb7739fda103d11/docs/qa/validation/2026-10-04) | 당시 자동화·의존성·CI 결과 |
| [초기 분석·수행 문서](https://github.com/uhaeun/knitgether-app/tree/b2f916bb9b248291a7f7ef421eb7739fda103d11/docs/qa/portfolio) | 배경, 도구 비교, 회차별 집계와 당시 릴리즈 검토 |
| [과거 API 진단 스크립트](https://github.com/uhaeun/knitgether-app/tree/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa/api-probes) · [초기 smoke 안내](https://github.com/uhaeun/knitgether-app/blob/b2f916bb9b248291a7f7ef421eb7739fda103d11/docs/qa/appium-charles-smoke.md) | 이전 API 계약과 개발 환경의 기록. 현재 실행은 `qa/api-tests/`와 `qa/appium/`의 안내를 사용 |
| [이전 기술 상세](https://github.com/uhaeun/knitgether-app/blob/b2f916bb9b248291a7f7ef421eb7739fda103d11/docs/qa/submission/technical-summary.md) | 충돌 보호·단위 정책의 당시 조건과 역할 |

현재 본문에 필요한 대표 화면·DB 관측과 최신 검증 자료는 기본 브랜치에 남겼습니다. 선별한 원본의 바이트는 변경하지 않았습니다. 과거 자료를 가리키는 링크는 고정 커밋을 사용합니다.

보존 자료의 “최신”, PR 진행 상태, 수치와 판단은 그 기록이 작성된 시점의 표현입니다. 현재 상태는 각 후속 보고서를 확인해야 합니다. 과거 스크립트를 재실행하려면 해당 커밋을 별도 경로에 체크아웃하고 당시 실행 안내를 따릅니다.
