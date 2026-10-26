"""Reflect completed evidence without rewriting earlier execution results."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
E=Path(__file__).parent/'evidence'
assert (Path(__file__).parent/'report.md').exists()
assert len(json.loads((E/'pure-ui-results.json').read_text()))==7
assert all(x['status']=='PASS' for x in json.loads((E/'boundary-ui-results.json').read_text()) if x['case'].startswith('UI78-'))
link='../../../qa-runs/2026-10-26-main-revalidation/report.md'
title='## 2026-10-26 최신 main 통합 후보 재검증'
def append(path,text):
 p=ROOT/path;s=p.read_text();assert title not in s,path;p.write_text(s.rstrip()+'\n\n'+title+'\n\n'+text.strip()+'\n')
append('docs/qa/portfolio/02_functional_spec.md',f'''[실행 근거]({link}). 최신 main6df5c4e의 경합20쌍은 두200으로 FAIL이었고, 수정0ae2c64에 최신 main 문서를 합친 후보는 실제DB18 PASS/0 SKIP 및 외부20쌍 모두200/409다. 두 기기 메모 복구12+7항목과300초 자동 재저장 없음, 오프라인 생성·복구를 확인했다. UI-03은 앞선 최신 main12 PASS의 원본을 별도 기준선으로 보존했으며 이번 전체 재실행으로 합산하지 않는다.

SYNC-11의 현재 구현 범위는 전체 PATCH와 카운터 전용 저장이다. 카운터도 같은 부모 버전·잠금에 참여하지만, 나머지 자식 API의 통합 버전은 아직 별도다. 작업 세션 삭제204 뒤 이전 전체 저장200이 세션을 되살리는 경계를 실제 재현했다. 모든 자식 쓰기에 같은 보호를 요구할지와 삭제 tombstone 우선순위는 별도 요구 결정·구현 항목이다. 앱 종료 후 미저장 초안 수명은 관찰 결과를 남기되 새 수용 조건으로 확정하지 않았다. 기존 SPEC ID 수와 과거 판정은 변경하지 않았다.''')
p=ROOT/'docs/qa/portfolio/02_functional_spec.md';s=p.read_text().replace('자식 전용 API·창고 항목의 통합 충돌 보호는 별도 범위','카운터 전용 저장은 같은 부모 버전·잠금에 참여한다. 나머지 자식 API·창고 항목의 통합 충돌 보호는 별도 범위');p.write_text(s)
append('docs/qa/portfolio/09_test_case_master.md',f'''[수정 후보 보고서]({link}). 기존 실행의 FAIL·SKIP 수는 당시 이력으로 유지한다.

| 추적 | 이번 판정 | 근거 |
|---|---|---|
| SYNC-11 전체 저장·카운터·rollback·파일 | 실제DB18 PASS/0 SKIP | projects-concurrency.real-db-spec.ts 기본 게이트 |
| SYNC-11 실제 외부 경합 | 20쌍 모두200/409 및 승자 일관성 | probe_concurrency.py; main의20쌍200/200과 별도 대조 |
| SYNC-11 두 기기 메모 복구 | 기본12+화면 전용7 PASS | run_sync.py·run_pure_ui.py, 자동 재저장 관찰300초 |
| SYNC-11 기존 회귀 | 서버147 / API75 PASS | mock·HTTP·DB 층을 구분하며 E2E 수에 합산하지 않음 |
| UI-78 오프라인 생성·복구 | 2확인 항목 PASS | 로컬 전용/서버0개→복구 후 중복 없이 서버1개 |
| UI-03 cm 정책 | 앞선 main12 PASS, 이번 전체 미재실행 | ui03-main-baseline.json, iOS 제품 소스 동일 |
| 초안 종료 수명 | CHARACTERIZED, 수용 기준 공백 유지 | 종료 전후 화면·서버 버전 대조 |
| 작업 세션 삭제와 전체 저장 | CHARACTERIZED, 잔여 데이터 복원 위험 | 삭제204→이전 전체200→세션 복원; 카운터 보호와 분리 |

물리 iPhone·모든 자식 API 조합·장기 SLA는 미실행이다. 기존 원격0ae2c64의4개 job success는 해당 커밋 결과이며 새 문서 통합 커밋의 CI와 별도 추적한다.''')
append('docs/qa/portfolio/10_defect_catalog.md',f'''[최신 main 대조·수정 후보 검증]({link}). QA-SYNC11-RACE는 main6df5c4e에서 재현되지만 수정 후보의 실제DB·외부20쌍·두 시뮬레이터 범위에서는 수정 검증 PASS다. 카운터의 CHILD-01/02와 FILES-01/02를 포함한18개는 기본 게이트에서0 SKIP으로 통과했다. main 병합·운영 배포 완료를 의미하지 않는다.

추가 위험: 작업 세션 삭제는 부모 버전을 바꾸지 않아 오래된 전체 저장이 삭제를 복원했다. 기존에 범위 밖으로 둔 통합 버전 공백의 새 재현으로 기록하며, 카운터 유실 수정 PASS를 모든 자식 경로의 해결로 확대하지 않는다. 앱 종료 후 미저장 초안은 수명 요구가 정해지지 않아 제품 결함 PASS/FAIL로 임의 확정하지 않는다.''')
append('docs/qa/submission/portfolio.md',f'''나는 선행 데이터·입력 보존, 직접 재저장, cm 고정과 API/E2E 구분의 수용 기준을 정하고 남은 수정 검토·재검증·문서 반영을 지시했다. Codex는 기존 수정0ae2c64와 최신 main6df5c4e를 대조하고 통합 후보를 실제로 실행했다. main의 경합20쌍 모두200/200과 후보의20쌍 모두200/409를 분리해 보존했다. 실제DB18개, 서버147개, API75개, 두 기기19개 확인 항목, 오프라인 복구2개 확인 항목의 통과는 서로 다른 층으로 보고했다. 자동 재저장 없음은300초 관찰이다.

Codex가 실행한 앱 종료 초안 수명과 작업 세션 삭제 복원은 잔여 범위로 공개했다. 사용자 직접 수동 실행이나 결과 검토·릴리즈 승인을 이미 한 것으로 기재하지 않는다. 이번에는 기존 구현을 재검토·검증했으며 새 제품 구현을 추가했다고 표현하지 않는다. [실행·역할·범위와 증거]({link}).''')
append('docs/qa/portfolio/15_release_decision.md',f'''[이번 판정 근거]({link}). 검증한 전체 PATCH·카운터 동시성 및 메모 복구는 수정 후보에서 PASS다. main의 경합 FAIL과 수정 후보 PASS는 서로 다른 기준선이다. 작업 세션 삭제 복원, 모든 자식 API의 통합 버전, 종료 후 초안 수명, 물리 기기·장기 SLA는 이번 수정의 일괄 승인 범위가 아니다. Draft PR #48 검토와 main 병합·배포 결정은 별도이며, CI 녹색을 전체 제품 릴리즈 승인으로 해석하지 않는다.''')
print('Updated SPEC, RTM, defect catalog, portfolio and release decision')
