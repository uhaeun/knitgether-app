# 목록에서 프로젝트 삭제 시 초안 정리 보완

앞선 [세션·초안 검증](../2026-10-26-session-fix/report.md)을 마친 뒤 삭제 진입점을 대조해, 작업 화면과 달리 프로젝트 목록의 삭제에 초안 파일 정리가 없는 것을 발견했다. 사용자 확정 정책은 “계정·프로젝트별 기기에 보존하고 저장 성공·명시적 삭제 시 제거”다. 정책 선택은 사용자, 누락 발견·수정·실행·판정은 Codex의 수행이다.

## 실행 결과

| 항목 | 수정 전 | 수정 후 | 근거 |
|---|---|---|---|
| 목록 삭제 성공의 초안 정리 | Swift12 중1 FAIL, 파일이 남음 | 전체354 PASS | red.log / green-unit.log |
| 목록 삭제 실패의 초안 유지 | 유지 PASS | 유지 PASS | 기존 실패 경로 테스트에 파일 내용 단언 추가 |
| 실제 iOS 목록 삭제 | 프로젝트 SQL은 soft-delete, 초안 파일 잔존 FAIL | SQL soft-delete와 화면 제거, 초안 파일 제거 PASS | red-ui-result.json / green-ui-result.json, 스크린샷/XML·HTTP |

기존 MyKnittingViewModelTests 12개 중 성공/실패 삭제2개를 보강했으며 새 TC 수로 더하지 않는다. 전체 Swift354는 앞선354와 같은 테스트 목록의 재실행이며708개로 합산하지 않는다. 이 추가 iOS 확인1건은 앞선 두 기기19·초안3·오프라인2와 구분한다.

원인: ProjectWorkspaceViewModel.deleteProject에는 초안 정리가 있었지만 MyKnittingViewModel.deleteProject에는 없었다. 목록의 프로젝트 삭제가 성공한 직후 같은 ownerId/projectId의 초안을 제거하도록 보완했다. 삭제 호출이 실패하면 제거에 도달하지 않으므로 초안이 유지된다. 저장소는 테스트별 임시 폴더를 주입해 검증한다.

## 기준과 재현

수정 전 실제 앱은 b86041c의 제품7579663과 같은 이전 빌드(UUID는 red-installed-app.txt)다. Swift RED는 저장소 주입 연결만 추가하고 정리 동작을 넣기 전 실행했다. 그 다음 정리1줄을 추가한 원본으로 전체 Swift354를 실행했다. 검증한 두 소스의 SHA256은 source-sha256.json이며 최종 배포 커밋은 전달 묶음 published-commit.txt에 기록한다. 수정 앱 UUID는 green-installed-app.txt다.

기존 전용 QA DB knitgether_qa_sync11_session_20261026만55438에 재시작했고 이전 계정·데이터를 보존했다. 새 red/green 프로젝트는 화면에서 각각 생성해 독립 UUID를 사용했다. 서버3301·마스킹 프록시3300·Appium14723·QA B(311D4B83-D09B-4237-824C-ABCDD09264D1)로 실행했다. 새 앱은 /tmp/knitgether-qa-draft-20261026에서 빌드했다. 서버 제품 코드는7579663 이후 바뀌지 않았다. 이전 실제DB24·서버147·API75·외부20쌍의 적용 범위를 유지하며 이번 추가 실행으로 재실행했다고 세지 않는다.

Python은 기존 qa-runs/2026-10-22/venv를 사용한다. /status ready 후 restore_sessions.py로 B만 연결한다. KG_DELETE_MODE=red로 run_list_delete.py를 실행해 이전 앱의 파일 잔존을 재현하고, 수정 앱의 전체 Swift 테스트 후 KG_DELETE_MODE=green KG_DELETE_INSTALL=1로 다시 실행한다. 새 실행은 새 폴더·프로젝트 이름을 사용하며 이미 삭제한 red/green fixture를 덮어쓰지 않는다. 목록 롱프레스→삭제→확인 모두 화면 조작이고 SQL과 파일은 관측 수단이다.

[수정 전 결과](evidence/red-ui-result.json) · [수정 후 결과](evidence/green-ui-result.json) · [삭제 확인](evidence/green-02-delete-confirm.png) · [삭제 후 목록](evidence/green-03-deleted-list.png). 비공개 세션·원본 Appium 로그·DB dump는 공유하지 않는다. 이전 FAIL 증거는 그대로 보존한다. 물리 기기·모든 자식 API·장기 SLA 및 main 병합/배포는 이번 범위가 아니다.
