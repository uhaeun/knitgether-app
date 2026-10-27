# main 병합 후 완료 근거

2026-10-27 완료 정리 시 보존한 상태 스냅샷입니다. 검증 제품은 `0d0ba222078f4e58cd7acc24ff1133e0590285d8`, PR 검토 head는 `fc08532e1332a7a71d59ac851d9d4fe4f9676af8`입니다. 이 폴더를 문서 변경으로 추가한 시점에 제품 시험을 새로 실행한 것은 아닙니다.

| 파일 | 의미 |
|---|---|
| [CI-status.json](CI-status.json) | PR 최종 head CI 4개 job 성공 |
| [main-CI-status.json](main-CI-status.json) | 병합 후 main CI 4개 job 성공 |
| [main-build-status.json](main-build-status.json) | 병합 main의 로컬 서버 빌드 종료 코드 0 |
| [main-smoke.json](main-smoke.json) | 실제 HTTP·SQL의 409·선행 값 보존·직접 재저장·자식 변경 보호 |
| [main-source-audit.json](main-source-audit.json) | 검토 후보·병합 트리와 시험한 제품 소스 대조 |
| [main-native.json](main-native.json) | 같은 제품 소스의 앱을 두 시뮬레이터에서 실행. 전체 E2E 재실행 아님 |

기존 로컬 공개 전달본에서 복사했습니다. HTTP 인증 값은 마스킹했고 원본 세션·DB dump·서버 로그는 포함하지 않았습니다. `at`의 UTC와 문서의 한국 시간 날짜를 구분합니다. 현재 CI 상태는 JSON의 run 링크에서 확인합니다.
