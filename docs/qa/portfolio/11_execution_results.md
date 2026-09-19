

## 11. 7차 전량 회귀 (2026-09-19, main `8bab32d`)

9/15에 main에 들어간 #14 잔존 수정(`3d76cb7`, `5582c3b`), AUTH-08 로그인 시도 제한(`2624a43`), DEF-23 케이스 확장(`1362481`)을 포함한 첫 전량 실행이다. 4개 층 모두 한 번에 통과했고 재실행한 파일이 없다.

| 층 | 결과 | 6차 대비 | 늘어난 케이스 |
| --- | --- | --- | --- |
| 서버 e2e | 147 passed, 0 failed | +4 | `auth.e2e-spec.ts` 4 → 8 (AUTH-08) |
| API 계약 | 69 passed, 0 failed | +5 | `test_20_login_attempt_limit.py` 신규 4, `test_03_create_idempotency.py` 1 → 2 (#14 409) |
| 앱 단위 | 351 passed, 0 failed (xcresult 기준) | +3 | `RemoteProjectRepositoryTests.swift` 21 → 24 |
| Appium | 82 passed, 0 failed, 1 skipped (3457초) | +1 | `test_def23_background_session.py` 1 → 2 |

skipped 1건은 UI-42b 실기기 문서 스캔으로 5차, 6차와 같다. 6차 1회차에 나온 fullReset 뒤 환경 증상은 이번에 나오지 않았다. 실행 조건은 6차와 같고 DB만 `knitgether_qa7`을 새로 만들어 이 커밋의 마이그레이션 전부를 적용했다.
