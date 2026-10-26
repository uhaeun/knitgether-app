# TC별 실행 결과

실제 DB와 iOS UI는 별도 층이다. 아래 TC 수에 서버147·API75·Swift359를 다시 합산하지 않는다. 과거626 앱의 SYNC-11 E2E는 기존 보고서의 당시 실행 근거다.

| 층 | 기기 | TC | 판정 | 근거 |
|---|---|---|---|---|
| HTTP + real PostgreSQL | - | has exactly one winner with no loser children after both read the same baseline | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | rolls back parent/version and early children when row instruction replacement fails | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | rolls back all SQL children when an error follows actual pattern upsert | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | advances every version even when the stored clock is ahead and rejects future client tokens | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | returns fresh 409/latest when another write commits between read and CAS | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | returns 404 when the project is deleted between read and CAS | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | preserves 409 even if the latest project has no convertible row counter | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | preserves validation, ownership and row-counter compatibility contracts | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | Regression: rejects a stale whole save after a child-only counter save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | Regression: detects a child API write between the whole save read and CAS | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | session create invalidates a stale whole save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | session update invalidates a stale whole save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | session delete invalidates a stale whole save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | session deletion between whole read and CAS rejects the stale whole save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | rolls back the parent version if the session mutation fails | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | serializes session deletion behind an uncommitted whole save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | Regression: removes materialized files when the SQL transaction rolls back | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | Regression: cleans an unreferenced PDF after pattern copy replacement | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | serializes a child write after a whole-save CAS without losing the child | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | rolls back the parent version if the child update fails | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | keeps the old PDF and drawing on rollback, then removes both on detach | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | retries durable failed removals and preserves referenced files after restart | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | blocks the counter on the parent lock while a whole save is uncommitted | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | compensates files when project creation rolls back | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | protects row instruction create from a stale whole save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | protects row instruction update from a stale whole save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | protects row instruction delete from a stale whole save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | protects pattern pdf from a stale whole save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | protects pattern drawing from a stale whole save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | protects pattern delete-drawing from a stale whole save | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | preserves committed drawing bytes if dedicated upload SQL rolls back | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | preserves committed drawing bytes if dedicated delete SQL rolls back | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | serializes duplicate instruction creates and rolls back the rejected parent version | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | preserves independent usage, photo and material links across whole saves | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | rejects instruction ID reuse from another project (foreign owner: false) without changing either project | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | rejects session ID reuse from another project (foreign owner: false) without changing either project | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | rejects whole-session ID reuse from another project (foreign owner: false) without changing either project | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | rejects instruction ID reuse from another project (foreign owner: true) without changing either project | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | rejects session ID reuse from another project (foreign owner: true) without changing either project | PASSED | evidence/child-verified.json |
| HTTP + real PostgreSQL | - | rejects whole-session ID reuse from another project (foreign owner: true) without changing either project | PASSED | evidence/child-verified.json |
| iOS native UI | A | UI03-SETTINGS | PASS | evidence/ui03-results-A.json |
| iOS native UI | A | UI03-PROFILE | PASS | evidence/ui03-results-A.json |
| iOS native UI | A | UI03-CM-Metric | PASS | evidence/ui03-results-A.json |
| iOS native UI | A | UI03-CM-Imperial | PASS | evidence/ui03-results-A.json |
| iOS native UI | A | UI03-CM-US | PASS | evidence/ui03-results-A.json |
| iOS native UI | A | UI03-CM-cm | PASS | evidence/ui03-results-A.json |
| iOS native UI | A | UI03-SIGNUP | PASS | evidence/ui03-results-A.json |
| iOS native UI | A | UI03-ONBOARDING-0 | PASS | evidence/ui03-results-A.json |
| iOS native UI | A | UI03-ONBOARDING-1 | PASS | evidence/ui03-results-A.json |
| iOS native UI | A | UI03-ONBOARDING-2 | PASS | evidence/ui03-results-A.json |
| iOS native UI | A | UI03-ONBOARDING-3 | PASS | evidence/ui03-results-A.json |
| iOS native UI | A | UI03-ONBOARDING-4 | PASS | evidence/ui03-results-A.json |
| iOS native UI | B | UI03-SETTINGS | PASS | evidence/ui03-results-B.json |
| iOS native UI | B | UI03-PROFILE | PASS | evidence/ui03-results-B.json |
| iOS native UI | B | UI03-CM-Metric | PASS | evidence/ui03-results-B.json |
| iOS native UI | B | UI03-CM-Imperial | PASS | evidence/ui03-results-B.json |
| iOS native UI | B | UI03-CM-US | PASS | evidence/ui03-results-B.json |
| iOS native UI | B | UI03-CM-cm | PASS | evidence/ui03-results-B.json |
| iOS native UI | B | UI03-SIGNUP | PASS | evidence/ui03-results-B.json |
| iOS native UI | B | UI03-ONBOARDING-0 | PASS | evidence/ui03-results-B.json |
| iOS native UI | B | UI03-ONBOARDING-1 | PASS | evidence/ui03-results-B.json |
| iOS native UI | B | UI03-ONBOARDING-2 | PASS | evidence/ui03-results-B.json |
| iOS native UI | B | UI03-ONBOARDING-3 | PASS | evidence/ui03-results-B.json |
| iOS native UI | B | UI03-ONBOARDING-4 | PASS | evidence/ui03-results-B.json |
