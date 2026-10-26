import json,csv
from pathlib import Path
R=Path(__file__).parent;E=R/'evidence';rows=[]
for item in json.loads((E/'child-case-results.json').read_text()):
    rows.append({'layer':'HTTP + real PostgreSQL','device':'-','case':item['case'],'status':item['status'].upper(),'evidence':'evidence/child-verified.json'})
for device in ['A','B']:
    path=E/('ui03-results-'+device+'.json')
    if path.exists():
        for item in json.loads(path.read_text()):
            rows.append({'layer':'iOS native UI','device':device,'case':item['case'],'status':item['status'],'evidence':'evidence/ui03-results-'+device+'.json'})
with (R/'case-results.csv').open('w') as f:
    w=csv.DictWriter(f,fieldnames=['layer','device','case','status','evidence'],lineterminator='\n');w.writeheader();w.writerows(rows)
lines=['# TC별 실행 결과','','실제 DB와 iOS UI는 별도 층이다. 아래 TC 수에 서버147·API75·Swift359를 다시 합산하지 않는다. 과거626 앱의 SYNC-11 E2E는 기존 보고서의 당시 실행 근거다.','','| 층 | 기기 | TC | 판정 | 근거 |','|---|---|---|---|---|']
lines += ['| '+ ' | '.join(str(x[k]).replace('|','/') for k in ['layer','device','case','status','evidence'])+' |' for x in rows]
(R/'case-results.md').write_text('\n'.join(lines)+'\n')
print('cases',len(rows),'UI',sum(r['layer']=='iOS native UI' for r in rows))
