# 실행 항목별 결과

확인 항목 수는 독립 TC 수나 테스트 층 간 합산 점수로 해석하지 않는다. 실제DB24에는 세션6개가 포함되며 Swift354에는 초안3개가 포함된다.

| 항목 | 판정 | 실행 층 | 근거 |
|---|---|---|---|
| SYNC11-B-DRAFT-NOT-SAVED | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| SYNC11-A-SAVE | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| SYNC11-409 | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| SYNC11-SAME-BASELINE | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| SYNC11-SERVER-A-KEPT | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| SYNC11-B-INPUT | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| SYNC11-B-NOTICE | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| SYNC11-NO-AUTO-RETRY | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| SYNC11-EXPLICIT-RESAVE | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| SYNC11-OTHER-FIELDS | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| SYNC11-RECONFLICT | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| SYNC11-RECONFLICT-RECOVERY | PASS | two independent iOS simulators | [evidence/sync-results.json](evidence/sync-results.json) |
| PURE-A-UI-OTHER-FIELDS-SAVE | PASS | two independent iOS simulators | [evidence/pure-ui-results.json](evidence/pure-ui-results.json) |
| PURE-B-CONFLICT | PASS | two independent iOS simulators | [evidence/pure-ui-results.json](evidence/pure-ui-results.json) |
| PURE-B-DRAFT-KEPT | PASS | two independent iOS simulators | [evidence/pure-ui-results.json](evidence/pure-ui-results.json) |
| PURE-A-INTERVENING-SAVE | PASS | two independent iOS simulators | [evidence/pure-ui-results.json](evidence/pure-ui-results.json) |
| PURE-B-RECONFLICT | PASS | two independent iOS simulators | [evidence/pure-ui-results.json](evidence/pure-ui-results.json) |
| PURE-B-RECOVERY | PASS | two independent iOS simulators | [evidence/pure-ui-results.json](evidence/pure-ui-results.json) |
| PURE-B-OTHER-FIELDS-PRESERVED | PASS | two independent iOS simulators | [evidence/pure-ui-results.json](evidence/pure-ui-results.json) |
| DRAFT-PROCESS-LIFETIME | PASS | iOS B + SQL | [evidence/boundary-ui-results.json](evidence/boundary-ui-results.json) |
| DRAFT-DISCARD-RELAUNCH | PASS | iOS B + SQL | [evidence/boundary-ui-results.json](evidence/boundary-ui-results.json) |
| DRAFT-EXPLICIT-SAVE-RELAUNCH | PASS | iOS B + SQL | [evidence/boundary-ui-results.json](evidence/boundary-ui-results.json) |
| UI78-OFFLINE-CREATE | PASS | iOS B + SQL | [evidence/boundary-ui-results.json](evidence/boundary-ui-results.json) |
| UI78-RECOVERY-UNIQUE | PASS | iOS B + SQL | [evidence/boundary-ui-results.json](evidence/boundary-ui-results.json) |
| session-create-stale-whole | PASS | real PostgreSQL + Nest HTTP | [evidence/session-cases.json](evidence/session-cases.json) |
| session-update-stale-whole | PASS | real PostgreSQL + Nest HTTP | [evidence/session-cases.json](evidence/session-cases.json) |
| session-delete-stale-whole | PASS | real PostgreSQL + Nest HTTP | [evidence/session-cases.json](evidence/session-cases.json) |
| session-delete-between-read-and-cas | PASS | real PostgreSQL + Nest HTTP | [evidence/session-cases.json](evidence/session-cases.json) |
| missing-session-parent-rollback | PASS | real PostgreSQL + Nest HTTP | [evidence/session-cases.json](evidence/session-cases.json) |
| session-delete-blocked-on-whole-parent-lock | PASS | real PostgreSQL + Nest HTTP | [evidence/session-cases.json](evidence/session-cases.json) |
| REAL-DB-ALL-24 | PASS | real PostgreSQL + HTTP, includes 6 session regressions | [evidence/green.log](evidence/green.log) |
| SERVER-147 | PASS | server regression with mocks | [evidence/server-tests.log](evidence/server-tests.log) |
| API-75 | PASS | HTTP + SQL + network regression | [evidence/api-tests.log](evidence/api-tests.log) |
| SWIFT-354 | PASS | Swift tests, includes 3 draft regressions | [evidence/ios-unit.log](evidence/ios-unit.log) |
| DIRECT-CONCURRENT-20-PAIRS | PASS | external HTTP + SQL | [evidence/concurrency.log](evidence/concurrency.log) |
