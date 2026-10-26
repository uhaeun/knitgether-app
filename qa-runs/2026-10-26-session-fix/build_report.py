from pathlib import Path
import json,csv,hashlib,re
R=Path(__file__).parent; E=R/'evidence'
product='75796633259a605d00b4d84bfc69abd4cbebe753'
checks=[]
for filename in ['sync-results.json','pure-ui-results.json','boundary-ui-results.json']:
 rows=json.loads((E/filename).read_text());assert rows and all(x['status']=='PASS' for x in rows), filename
 checks += [{'case':x['case'],'status':x['status'],'scope':'two independent iOS simulators' if filename!='boundary-ui-results.json' else 'iOS B + SQL','evidence':'evidence/'+filename} for x in rows]
assert len(checks)==24,len(checks)
visible=json.loads((E/'visible-draft-results.json').read_text())
assert len(visible)==3 and all(x['status']=='PASS' for x in visible)
assert '24 passed, 24 total' in (E/'green.log').read_text()
assert '147 passed, 147 total' in (E/'server-tests.log').read_text()
assert '75 passed' in (E/'api-tests.log').read_text()
assert '354 tests in 41 suites passed' in (E/'ios-unit.log').read_text()
trials=json.loads((E/'api-concurrency-direct.json').read_text())
assert len(trials)==20 and all(x['pass'] for x in trials)
for x in json.loads((E/'session-cases.json').read_text()):
 checks.append({'case':x['case'],'status':'PASS','scope':'real PostgreSQL + Nest HTTP','evidence':'evidence/session-cases.json'})
checks += [dict(case=k,status='PASS',scope=s,evidence='evidence/'+f) for k,s,f in [
 ('REAL-DB-ALL-24','real PostgreSQL + HTTP, includes 6 session regressions','green.log'),
 ('SERVER-147','server regression with mocks','server-tests.log'),
 ('API-75','HTTP + SQL + network regression','api-tests.log'),
 ('SWIFT-354','Swift tests, includes 3 draft regressions','ios-unit.log'),
 ('DIRECT-CONCURRENT-20-PAIRS','external HTTP + SQL','concurrency.log')]]
with (R/'case-results.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=['case','status','scope','evidence']);w.writeheader();w.writerows(checks)
(R/'case-results.md').write_text('# 실행 항목별 결과\n\n확인 항목 수는 독립 TC 수나 테스트 층 간 합산 점수로 해석하지 않는다. 실제DB24에는 세션6개가 포함되며 Swift354에는 초안3개가 포함된다.\n\n| 항목 | 판정 | 실행 층 | 근거 |\n|---|---|---|---|\n'+''.join(f"| {x['case']} | {x['status']} | {x['scope']} | [{x['evidence']}]({x['evidence']}) |\n" for x in checks))
(R/'report.md').write_text(f'''# 작업 세션 경합·프로세스 종료 초안 후속 검증

제품 기준 커밋 `{product}`. 앞선71fc254에서 발견한 작업 세션 삭제 복원 경계를 수정했고, 종료 시 초안 소실에는 계정·프로젝트별 기기 보존안을 구현했다. PR48은 Draft이며 병합·배포하지 않았다. 기존 FAIL과 CHARACTERIZED 결과는 역사적 증거로 그대로 유지한다.

## 역할과 요구사항 결정

사용자가 정한 요구는 SYNC-11의 충돌 차단·서버 값 및 미저장 입력 보존·명시적 재저장, UI-03의 cm 고정, 실제 실행과 증거 기록이다. 후속 진행 지시로 Codex가 결함 수정·재검증을 수행했다. 앱 종료 후 수명은 이전에 명세 공백이었으며, **“계정·프로젝트별 기기에 보존하고 저장 성공·명시적 삭제 시 제거”는 사용자가 이번 실행 중 명시적으로 선택한 정책**이다. Codex는 명시적 삭제를 초안 버리기와 프로젝트 삭제의 정리로 구현했다. Codex가 구현·시험·판정을 수행했다. 사용자 직접 시험·리뷰·릴리즈 승인으로 표현하지 않는다.

초안은 서버 동기화 큐와 분리한 atomic 파일이다. 소유자 없는 프로젝트는 영구 초안 대상이 아니며, 로그아웃은 파일을 지우지 않고 같은 계정으로 돌아올 때만 같은 소유자·프로젝트 키로 복구한다. 다른 계정/다른 프로젝트 격리는 Swift 테스트로 확인했다. 계정 전환 UI 전체와 익명 초안 보존은 이번 E2E 수용 범위에 포함하지 않는다. 앱 데이터 삭제·제거 후의 복구를 보장하지 않는다.

## 결과

| 실행 | 결과 | 범위 |
|---|---|---|
| 수정 전 세션 생성·수정·삭제 후 오래된 전체 저장 | 3 FAIL, 모두200 | red.log/red.json, 제품 결함 재현 |
| 수정 후 실제 PostgreSQL+HTTP | 24 PASS/0 SKIP | 기존18 + 신규 세션6 |
| 서버 회귀 | 147 PASS | Prisma mock 기반 회귀 포함 |
| 별도 API·DB·네트워크 회귀 | 75 PASS | 서버 실제 실행 |
| 로컬 Swift | 354 PASS/41 suites | 초안 재생성·저장 정리·계정/프로젝트 격리·버리기·충돌/재조회 유지·프로젝트 삭제 포함 |
| 외부 동시 요청 | 20쌍 PASS | 매 쌍200/409 및 승자 데이터 일치 |
| 두 기기 SYNC-11 | 12 + 화면 전용7 PASS | 동일 계정·동일 기준 버전·409·A 값·B 초안/안내·직접 재저장·타 필드·재충돌 |
| 프로세스 수명 | 3 PASS | 실제 terminate/relaunch에서 복구, 버리기 후 복구 안 됨, 직접 저장 후 저장값 유지 |
| UI78 오프라인 | 2 PASS | 서버0개/로컬 전용→복구 후 중복 없이 서버1개 |
| UI03 cm 정책 | 앞선 main12 PASS 증거 유지 | 이번 UI03 전체 재실행 아님. 새 Swift 전체 실행과 혼동하지 않음 |

[항목별 판정](case-results.md) · [재현 환경/명령](RUNBOOK.md) · [환경 및 기준 커밋](evidence/environment.json) · [실제 세션 SQL](evidence/verification.sql) · [SQL 결과](evidence/sql-output.txt).

## 원인과 수정

세션 API가 자식 행만 바꿔 Project.updatedAt을 유지했으므로, 삭제 이전 baseline의 전체 저장이 CAS를 통과한 뒤 workSessions upsert로 deletedAt을 null로 되돌렸다. 생성·수정도 같은 버전 공백이었다. 이제 세션 생성·수정·삭제와 카운터가 같은 부모 CAS 잠금 helper를 사용한다. READ COMMITTED 트랜잭션에서 부모 버전 증가·자식 변경이 함께 commit/rollback한다. 부분 API 자체의 baseline 없는 기존 계약을 모든 세션 편집의 충돌 방지로 확대해 설명하지 않는다.

신규6개 실제DB 검사는 생성/수정/삭제 후 오래된 전체 저장409 및 전체 SQL 상태 보존3건, 전체 조회와 CAS 사이 세션 삭제1건, 없는 세션 삭제404의 부모 rollback1건, 미commit 전체 저장 뒤 실제 PostgreSQL lock 대기·세션 삭제 직렬화1건이다. 기존 삭제 복원은 제품 결함이다. 중간 fixture의 ownerId 때문에400이 나온 건은 테스트 문제, Appium 준비 전 연결 거절은 환경 문제로 구분했다.

미저장 메모는 ViewModel 수명에만 있어 프로세스 종료 시 사라졌다. 초안을 파일에 기록·복원하고 저장 상태 재조회와 다른 필드 저장 시에도 입력을 유지한다. 저장 중 사용자가 새로 입력한 내용도 서버에 저장된 메모와 다르면 초안으로 남긴다. 초기 삭제204→전체200→복원 관찰은 이번 변경 전 결함 근거로 보존한다.

## 증거와 제한

초안 수명 최초 캡처 일부에서 메모 영역이 화면 밖에 있어, capture_visible_draft.py로 실제 종료/복구·버리기·저장을 반복하고 메모 전체가 보이는 보완 스크린샷을 남겼다. 최초 캡처와 JSON/XML은 보존하며, 보완3개를 독립 TC 수에 중복 합산하지 않았다. [복구된 초안](evidence/visible-draft-02-restored.png) · [버리기 후](evidence/visible-draft-03-discarded.png) · [직접 저장 후](evidence/visible-draft-04-explicit-save.png).

새 앱을 두 전용 iOS26.5 시뮬레이터에 설치하고 설치 dylib UUID를 기록했다. 충돌 화면·재저장·종료 전후 스크린샷/XML, 마스킹 HTTP, SQL·JSON, 로그를 evidence에 저장했다. 자동 재저장 없음은300초 관찰 범위다. API 확장으로 다른 필드를 바꾸는 기본12항목과, 두 사용자의 수정/저장을 모두 화면에서 수행하는 보완7항목은 구분한다. Swift/API 통과를 E2E 통과로 대신하지 않았다.

다른 자식 API 전부의 통합 버전, 모든 업로드 경로·과거 고아 파일 일괄 정리, 물리 iPhone, 장기·대량 경합 SLA는 미실행/별도 범위다. 개인 iPhone은 사용하지 않았다. 전용 새DB를 사용하고 기존 DB는 보존했다. 세션/토큰·dump·원본 Appium 로그는 공유 대상에서 제외한다. 원격 CI는 별도 CI 상태 파일의 대상 SHA와 완료 상태로 판정한다.

## SPEC·RTM·포트폴리오 보완

SYNC-11 보호 경로에 작업 세션 생성·수정·삭제를 추가하고, 위6개를 기본 실제DB 게이트로 추적한다. 앱 종료 초안 보존은 이번 사용자 답변으로 확정된 후속 정책으로 추적한다. 사용자의 명세 결정과 Codex 구현·실행을 분리한다. 포트폴리오에는 “통과 결과만 수집하지 않고 자식 API의 버전 공백을 추가 재현한 뒤, 수정 전3실패·수정 후24개 실제DB 회귀와 두 기기 화면/SQL 증거로 검증 범위를 설명했다”고 기록할 수 있다. 총 검사 수를 중복 합산하거나 전체 릴리즈 승인을 선언하지 않는다.
''')
files=[p for p in E.rglob('*') if p.is_file() and 'private' not in p.name and 'sessions' not in p.name and p.suffix!='.dump' and p.name!='SHA256SUMS.txt']
(E/'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+str(p.relative_to(R))+'\n' for p in sorted(files)))
print('report built',len(checks),'rows',len(files),'evidence files')
