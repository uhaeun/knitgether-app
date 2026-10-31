# 동시 수정 충돌: 화면과 DB

2026-10-26 두 시뮬레이터 후속 자동화에서 확인한 SYNC-11의 대표 근거입니다. 제품 기준 커밋은 `75796633259a605d00b4d84bfc69abd4cbebe753`입니다. iOS 26.5 전용 시뮬레이터 2대와 새 PostgreSQL DB를 사용했습니다. 구현·실행·증거 수집에는 AI를 활용했습니다.

| 순서 | 판정 기준 | 근거 |
|---|---|---|
| B가 입력한 뒤 A 저장, B 저장 | 충돌 안내와 B의 미저장 메모 유지 | [화면](sync-04-b-conflict.png) |
| B 저장에 HTTP 409 | DB에는 A의 선행 저장값 유지 | [충돌 후 DB](sync-04-after-conflict-db.json) |
| B가 재조회 후 직접 재저장 | DB에 B 메모 저장, 시험한 다른 필드 유지 | [재저장 후 DB](sync-05-final-db.json) |

기본 12개는 UI·API 혼합, 보완 7개는 양쪽 변경을 화면에서 수행했습니다. 자동 재저장 없음은 300초 관찰입니다. 실물 iPhone이나 메모·단수 외 모든 입력의 보존까지 보장한 결과는 아닙니다.

세 파일은 [원본 폴더](https://github.com/uhaeun/knitgether-app/tree/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa-runs/2026-10-26-session-fix/evidence)에서 바이트를 변경하지 않고 옮겼습니다.

[당시 전체 보고서](https://github.com/uhaeun/knitgether-app/blob/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa-runs/2026-10-26-session-fix/report.md) · [항목별 판정](https://github.com/uhaeun/knitgether-app/blob/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa-runs/2026-10-26-session-fix/case-results.md) · [환경·재현 명령](https://github.com/uhaeun/knitgether-app/blob/b2f916bb9b248291a7f7ef421eb7739fda103d11/qa-runs/2026-10-26-session-fix/RUNBOOK.md)
