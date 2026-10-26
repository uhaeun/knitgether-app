"""Characterize a known out-of-scope child route; does not invent a release gate."""
import copy, json, sys, uuid
from pathlib import Path
import requests, psycopg2

R=Path(__file__).resolve().parent
sys.path.insert(0,str(R.parents[1]/'qa/api-tests'))
from helpers import project_payload
base='http://127.0.0.1:3301/api/v1'
a=requests.post(base+'/auth/register',json={'email':uuid.uuid4().hex+'@example.com','password':'boundary-fixture-pass','displayName':'Boundary QA'},timeout=15)
a.raise_for_status();h={'Authorization':'Bearer '+a.json()['accessToken']}
body=project_payload(name='Session boundary QA')
sid=str(uuid.uuid4())
body['workSessions']=[{'id':sid,'projectId':body['id'],'startedAt':'2026-10-26T01:00:00Z','endedAt':'2026-10-26T01:01:00Z','memo':'baseline session'}]
r=requests.post(base+'/projects',headers=h,json=body,timeout=15);r.raise_for_status()
baseline=r.json()['updatedAt'];body['baseUpdatedAt']=baseline
events=[]
def state():
 with psycopg2.connect(host='127.0.0.1',port=55437,user='knitgether',dbname='knitgether_qa_sync11_revalidation_20261026') as c:
  with c.cursor() as cur:
   cur.execute('SELECT row_to_json(p) FROM "Project" p WHERE id=%s',(body['id'],));p=cur.fetchone()[0]
   cur.execute('SELECT row_to_json(s) FROM "WorkSession" s WHERE id=%s',(sid,));p['session']=cur.fetchone()[0]
   return p
deleted=requests.delete(base+'/projects/'+body['id']+'/work-sessions/'+sid,headers=h,timeout=15);assert deleted.status_code==204,deleted.text
events.append({'stage':'session deleted through child route','status':deleted.status_code,'db':state()})
assert events[-1]['db']['session']['deletedAt'] is not None
body['memo']='whole save from original baseline'
saved=requests.patch(base+'/projects/'+body['id'],headers=h,json=body,timeout=15)
events.append({'stage':'whole save with original session payload','request':body,'status':saved.status_code,'response':saved.json(),'db':state()})
result={'classification':'CHARACTERIZATION of existing aggregate-version gap; outside the counter-only fix','events':events,'wholeSaveAccepted':saved.status_code==200,'deletedSessionRestored':events[-1]['db']['session']['deletedAt'] is None}
# JSON timestamps have different display forms; compare via datetime explicitly.
from datetime import datetime
result['parentVersionChangedBySessionDelete']=datetime.fromisoformat(events[0]['db']['updatedAt']) != datetime.fromisoformat(baseline.rstrip('Z'))
(R/'evidence/session-boundary.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print({k:v for k,v in result.items() if k!='events'})
