import json, csv, hashlib
from pathlib import Path

R=Path(__file__).parent; E=R/'evidence'
load=lambda n:json.loads((E/n).read_text())
core=load('sync-results.json');pure=load('pure-ui-results.json');boundary=load('boundary-ui-results.json')
assert len(core)==12 and len(pure)==7 and all(x['status']=='PASS' for x in core+pure)
assert all(x['status']=='PASS' for x in boundary if x['case'].startswith('UI78-'))
real=load('real-db-results.json');server=load('server-results.json')
assert real['numPassedTests']==18 and real['numFailedTests']==real['numPendingTests']==0
assert server['numPassedTests']==147 and server['numFailedTests']==0
race=load('api-concurrency-direct.json');assert len(race)==20 and all(x['pass'] for x in race)
observation=next(x['detail'] for x in core if x['case']=='SYNC11-NO-AUTO-RETRY');assert observation['observationSeconds']==300
life=next(x['detail'] for x in boundary if x['case']=='DRAFT-PROCESS-LIFETIME')
child=load('session-boundary.json')
rows=[]
for group,file in [('SYNC UI와 API 확장','sync-results.json'),('SYNC 화면 전용','pure-ui-results.json'),('초안 수명·오프라인','boundary-ui-results.json')]:
 for x in load(file):rows.append({'group':group,'case':x['case'],'status':x['status'],'detail':json.dumps(x['detail'],ensure_ascii=False),'evidence':'evidence/'+file})
rows.append({'group':'실제 DB','case':'CAS·카운터·파일 18개','status':'PASS','detail':'18 PASS / 0 SKIP','evidence':'evidence/real-db-results.json'})
rows.append({'group':'서버 외부 경합','case':'20쌍 원자성','status':'PASS','detail':'모두 200/409 및 승자 부모·자식 일치','evidence':'evidence/api-concurrency-direct.json'})
rows.append({'group':'미해소 경계','case':'작업 세션 삭제 후 오래된 전체 저장','status':'CHARACTERIZED','detail':'부모 버전 유지, 204 삭제 뒤 전체200, 세션 복원','evidence':'evidence/session-boundary.json'})
with (R/'case-results.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=['group','case','status','detail','evidence']);w.writeheader();w.writerows(rows)
table='| 범위 | 케이스 | 판정 | 증거 |\n|---|---|---|---|\n'+'\n'.join(f"| {x['group']} | {x['case']} | {x['status']} | [원본]({x['evidence']}) |" for x in rows)
(R/'case-results.md').write_text('# 수정 후보 재검증 케이스\n\n같은 요구의 반복·보완 실행은 독립 요구사항 수로 합산하지 않는다.\n\n'+table+'\n')
text='''# 최신 main 통합 후보의 SYNC11 재검증

2026-10-26 KST. 수정 브랜치 `0ae2c64484542fcf19be6edd10839e2d578e6589`에 최신 main `6df5c4ef9473ac97437e3022a602eddd9ce92bbe`를 충돌 없이 합친 후보를 검증했다. main 추가분은 문서이며 제품 소스는0ae2c64와 동일하다. 이번 작업에서 새 제품 구현을 덧붙이지 않고 기존 CAS·카운터·파일 정리 구현을 검토했다. SPEC·RTM·포트폴리오와 재현 명령을 수정했다. 기존 Draft PR #48을 검토 대상으로 유지하며 main 병합·운영 배포는 하지 않는다.

## 수정 전후 결과

| 층 | 실제 결과 | 근거 |
|---|---|---|
| 최신 main 외부 동시 저장 대조 | 20쌍 모두200/200, FAIL | [앞선 실행 원본의 동일 바이트 사본](evidence/main-red-concurrency.json) |
| 수정 후보 외부 동시 저장 | 20쌍 모두 정확히200/409, 승자 부모·자식 일치 | [HTTP·SQL](evidence/api-concurrency-direct.json) |
| 수정 후보 실제 PostgreSQL+Nest HTTP | 18 PASS / 0 FAIL / 0 SKIP | [결과](evidence/real-db-results.json), [상세 증거](evidence/real-db-evidence.json) |
| 기존 서버 회귀 | 12 suites / 147 PASS | [결과](evidence/server-results.json); Prisma mock 기반 포함 |
| 별도 API·네트워크·DB 회귀 | 75 PASS / 0 FAIL / 0 SKIP | [JUnit](evidence/api-results.xml), [로그](evidence/api.log) |
| 두 시뮬레이터 SYNC11 | 기본12항목 + 화면 전용7항목 PASS | [기본](evidence/sync-results.json), [화면 전용](evidence/pure-ui-results.json) |
| 기존 UI78 오프라인 생성·복구 | 2항목 PASS | [화면·SQL 판정](evidence/boundary-ui-results.json) |
| UI03 cm 정책 | 앞선 최신 main12 PASS를 기준선으로 보존, 이번 전체 미재실행 | [기준선 JSON](evidence/ui03-main-baseline.json), [원본 해시](evidence/baseline-evidence-copy.json) |

[케이스 표](case-results.md)와 [CSV](case-results.csv)를 제공한다. 실제 DB18개에는 같은 버전 동시 읽기를 맞춘 결정적 경합, 단조 버전 증가, 권한·계약, 부모·자식 rollback, 카운터 잠금, 파일 보상·교체·연결 해제·재시도 검사가 포함된다. 고의 실패 주입의500을 자연 발생 제품 결함으로 집계하지 않는다. 외부 시작 barrier만으로 서버 내부 읽기 시점의 겹침을 단정하지 않는다. 각 층의 개수를 E2E 통과율로 합산하지 않는다.

## 코드 검토와 실제 두 기기 흐름

전체 PATCH는 ownerId·deletedAt·updatedAt을 조건으로 한 updateMany CAS와 자식 저장을 같은 READ COMMITTED 트랜잭션으로 처리한다. 정확한 baseline 일치를 요구하고 성공 버전을 max(시각, 이전+1ms)로 증가시킨다. 거부 요청은 자식을 변경하지 않는다. 카운터 전용 PATCH도 같은 부모 행을 먼저 잠그고 버전을 올린다. 파일 생성 실패 보상과 참조 해제 후 정리·durable marker 재시도는 기존 수정 구현을 재사용했다. 카운터 이외 자식 API와 모든 파일 경로까지 보호한 것으로 확대하지 않는다.

A/B는 같은 테스트 계정과 프로젝트를 실제 UI로 열었다. B 미저장 메모→A 저장→B409→서버 A값·B초안·안내 유지→B 직접 저장→재충돌→직접 복구를 HTTP·화면·SQL로 대조했다. 기본 흐름의 이름·즐겨찾기·단수 변경과 중간 쓰기는 API_EXTENSION이며, 별도 화면 전용 흐름은 A의 이름·즐겨찾기·메모 변경까지 실제 UI로 수행했다. phase actor는 실행기 주석이며 네트워크 자체의 기기 인증값은 아니다.

자동 재저장 관찰은 이번300초다. 대상 PATCH 수는 '''+str(observation['before'])+'→'+str(observation['after'])+'''로 유지됐다. 이 시간은 Codex가 선택한 관찰 구간이며 사용자 지정 SLA나 무기한 보장이 아니다. 최종 화면 전용 DB는 [snapshot](evidence/pure-07-final-db.json)에 보존했다.

## 추가 경계 관찰과 남는 결정

명시적 앱 프로세스 종료·재실행 뒤 미저장 메모 초안의 관찰값은 다음과 같다.

```json
'''+json.dumps(life,ensure_ascii=False,indent=2)+'''
```

종료 전후 서버 메모·버전이 같은지 직접 SQL로 확인했다. 이 수명은 기존 SPEC의 공백이므로 PASS/FAIL 수용 게이트로 만들지 않았다. 종료 후 복구가 필요하다면 초안의 저장 위치·유효기간·계정 전환/로그아웃·충돌 기준을 먼저 정해야 한다. 오프라인 검사는 UI78을 재사용해 회선 단절 중 새 프로젝트가 로컬 전용이며 서버0개, 회선 복구와 재시도 후 같은 프로젝트가 서버1개인지를 확인했다. 이것이 충돌 초안의 오프라인/종료 영속성을 증명하지는 않는다.

카운터 이외 작업 세션의 잔여 위험을 실제로 확인했다. 세션 DELETE204가 부모 updatedAt을 바꾸지 않았고, 원래 baseline과 세션을 가진 전체 PATCH200이 삭제한 세션을 되살렸다. [요청·응답·SQL](evidence/session-boundary.json). 기존에 별도 범위로 남긴 통합 버전 공백의 새 재현이다. 이번 카운터 수정 PASS를 전체 자식 API 보호로 해석하지 않는다. 모든 aggregate 쓰기의 부모 버전·잠금 규약을 공유할지, 세션 삭제의 tombstone을 전체 저장이 복원할 수 있는지에 대한 정책과 별도 구현·회귀가 남는다.

실물 iPhone은 전용 테스트 기기·서명 환경을 확정하지 않아 미실행이다. 연결 가능한 기기가 없었다고 주장하지 않는다. [기기 가용성](evidence/physical-device-availability.json). 모든 자식 엔드포인트 경합 조합, 장기·부하 SLA, OS 강제 종료 중 파일 작업의 모든 경로도 미실행이다.

## 환경과 증거

macOS26.5.1 / Xcode26.6 / iOS26.5 / Appium3.1.2 / xcuitest12.3.4. 기존 전용 QA A(840CB58F-9AD8-4403-A8C3-3E2D5F93B0C5)와 B(311D4B83-D09B-4237-824C-ABCDD09264D1)의 별도 앱 컨테이너를 사용했다. iOS 제품 소스는 최신 main과 동일하므로 앞서 빌드한 정상 서명 앱을 재사용하고 설치 UUID를 기록했다. 서버는 후보 소스에서 새로 빌드했다.

이전 전용 클러스터를 localhost55437로 기동하고 새 DB knitgether_qa_sync11_revalidation_20261026을 만들었다. 이전 DB와 사용자5432/5433은 초기화하지 않았다. API3301, 기록 프록시3300, B 오프라인 관문3999, Appium14723, WDA18101/18102를 사용했다. 원본 HTTP의 인증 헤더는 저장하지 않으며 token/password/secret 필드를 마스킹했다. dump·세션·Appium 원본·기기 인벤토리는 로컬 전용이다.

처음 WDA 준비 요청은 부팅 완료 전에 driver-sessions.json이 없어 실패했다. 부팅 완료 후 재실행해 두 세션을 복구했다. 작업 세션 probe 첫 시도는 30자를 넘는 테스트 이름으로400이었고, 올바른 fixture로 보완한 뒤 재현했다. 이 두 건은 제품 결함으로 집계하지 않으며 원본 로그를 보존한다. 이번 컨테이너 조회는 두 기기 모두10초 내 성공해 서비스 강제 재시작은 하지 않았다.

## 사용자 결정과 Codex 수행

사용자는 선행 데이터·초안 보존, 수동 재저장, cm 고정, API와 E2E의 구분·격리·증거 기준을 정하고 남은 수정·재검증·문서 반영의 진행을 지시했다. Codex는 기존 수정·원격 CI 검토, 최신 main 통합 후보 준비, 코드 검토, 실제 실행·증거 수집·판정과 문서 정정을 수행했다. 이번 단계에서 사용자가 테스트를 직접 실행하거나 결과를 검토·릴리즈 승인했다고 기재하지 않는다. 앱 종료 초안 수명이나 모든 자식 API의 새로운 정책을 사용자 결정으로 만들어 넣지 않았다.

포트폴리오 보완 문안: 나는 동시 수정과 단위 정책의 수용 기준을 정했다. Codex는 최신 main의 경합 FAIL과 수정 후보의200/409를 대조하고, 실제 DB18개·두 시뮬레이터19항목·오프라인 복구를 실행했다. 검증한 수정과 함께 작업 세션 삭제 복원 및 앱 종료 초안 수명이라는 잔여 범위를 공개했다. 사용자 판단과 Codex 실행, 통과한 범위와 미실행·미결정 범위를 구분했다.
'''
(R/'report.md').write_text(text)
print('report and case records generated',len(rows))
