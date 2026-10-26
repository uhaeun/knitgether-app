# 수정 후보 재검증 케이스

같은 요구의 반복·보완 실행은 독립 요구사항 수로 합산하지 않는다.

| 범위 | 케이스 | 판정 | 증거 |
|---|---|---|---|
| SYNC UI와 API 확장 | SYNC11-B-DRAFT-NOT-SAVED | PASS | [원본](evidence/sync-results.json) |
| SYNC UI와 API 확장 | SYNC11-A-SAVE | PASS | [원본](evidence/sync-results.json) |
| SYNC UI와 API 확장 | SYNC11-409 | PASS | [원본](evidence/sync-results.json) |
| SYNC UI와 API 확장 | SYNC11-SAME-BASELINE | PASS | [원본](evidence/sync-results.json) |
| SYNC UI와 API 확장 | SYNC11-SERVER-A-KEPT | PASS | [원본](evidence/sync-results.json) |
| SYNC UI와 API 확장 | SYNC11-B-INPUT | PASS | [원본](evidence/sync-results.json) |
| SYNC UI와 API 확장 | SYNC11-B-NOTICE | PASS | [원본](evidence/sync-results.json) |
| SYNC UI와 API 확장 | SYNC11-NO-AUTO-RETRY | PASS | [원본](evidence/sync-results.json) |
| SYNC UI와 API 확장 | SYNC11-EXPLICIT-RESAVE | PASS | [원본](evidence/sync-results.json) |
| SYNC UI와 API 확장 | SYNC11-OTHER-FIELDS | PASS | [원본](evidence/sync-results.json) |
| SYNC UI와 API 확장 | SYNC11-RECONFLICT | PASS | [원본](evidence/sync-results.json) |
| SYNC UI와 API 확장 | SYNC11-RECONFLICT-RECOVERY | PASS | [원본](evidence/sync-results.json) |
| SYNC 화면 전용 | PURE-A-UI-OTHER-FIELDS-SAVE | PASS | [원본](evidence/pure-ui-results.json) |
| SYNC 화면 전용 | PURE-B-CONFLICT | PASS | [원본](evidence/pure-ui-results.json) |
| SYNC 화면 전용 | PURE-B-DRAFT-KEPT | PASS | [원본](evidence/pure-ui-results.json) |
| SYNC 화면 전용 | PURE-A-INTERVENING-SAVE | PASS | [원본](evidence/pure-ui-results.json) |
| SYNC 화면 전용 | PURE-B-RECONFLICT | PASS | [원본](evidence/pure-ui-results.json) |
| SYNC 화면 전용 | PURE-B-RECOVERY | PASS | [원본](evidence/pure-ui-results.json) |
| SYNC 화면 전용 | PURE-B-OTHER-FIELDS-PRESERVED | PASS | [원본](evidence/pure-ui-results.json) |
| 초안 수명·오프라인 | DRAFT-PROCESS-LIFETIME | CHARACTERIZED | [원본](evidence/boundary-ui-results.json) |
| 초안 수명·오프라인 | UI78-OFFLINE-CREATE | PASS | [원본](evidence/boundary-ui-results.json) |
| 초안 수명·오프라인 | UI78-RECOVERY-UNIQUE | PASS | [원본](evidence/boundary-ui-results.json) |
| 실제 DB | CAS·카운터·파일 18개 | PASS | [원본](evidence/real-db-results.json) |
| 서버 외부 경합 | 20쌍 원자성 | PASS | [원본](evidence/api-concurrency-direct.json) |
| 미해소 경계 | 작업 세션 삭제 후 오래된 전체 저장 | CHARACTERIZED | [원본](evidence/session-boundary.json) |
