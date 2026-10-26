import copy,concurrent.futures,json,os,sys,threading,uuid,time
from pathlib import Path
import requests,psycopg2
R=Path(__file__).resolve().parent;sys.path.insert(0,str(R.parents[1]/'qa/api-tests'))
from helpers import project_payload
base=os.environ.get('QA_API_URL','http://127.0.0.1:3301/api/v1');path='direct' if ':3301/' in base else 'proxy'
a=requests.post(base+'/auth/register',json={'email':'cas-'+uuid.uuid4().hex+'@example.com','password':'qa-sync11-pass','displayName':'CAS QA'},timeout=15);a.raise_for_status();token=a.json()['accessToken'];h={'Authorization':'Bearer '+token}
out=[]
for i in range(20):
 b=project_payload(name='CAS '+str(i));res=requests.post(base+'/projects',headers=h,json=b,timeout=15);res.raise_for_status();b['baseUpdatedAt']=res.json()['updatedAt']
 bodies=[]
 for marker,n in [('A',11),('B',22)]:
  p=copy.deepcopy(b);p.update(name=marker,memo=marker,isFavorite=marker=='A');p['rowCounter']['currentRow']=n
  p['rowCounter']['rowInstructions']=[{'id':str(uuid.uuid4()),'rowCounterId':b['rowCounter']['id'],'rowNumber':1,'instructionText':marker}]
  p['workSessions']=[{'id':str(uuid.uuid4()),'projectId':b['id'],'startedAt':'2026-10-24T00:00:00Z','endedAt':'2026-10-24T00:01:00Z','memo':marker}]
  p['patternCopy']={'id':str(uuid.uuid4()),'projectId':b['id'],'sourcePatternDocumentId':None,'titleSnapshot':marker,'copiedAt':'2026-10-24T00:00:00Z'}
  bodies.append(p)
 gate=threading.Barrier(2)
 def send(p):
  with requests.Session() as client:
   gate.wait(timeout=5);start=time.monotonic();r=client.patch(base+'/projects/'+b['id'],headers=h,json=p,timeout=15)
   return {'request':p,'status':r.status_code,'response':r.json(),'elapsedSeconds':time.monotonic()-start}
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex: replies=list(ex.map(send,bodies))
 with psycopg2.connect(host='127.0.0.1',port=55437,user='knitgether',dbname='knitgether_qa_sync11_revalidation_20261026') as conn:
  with conn.cursor() as cur:
   cur.execute('SELECT row_to_json(p) FROM "Project" p WHERE id=%s',(b['id'],));db=cur.fetchone()[0]
   for table,key in [('RowCounter','counter'),('RowInstruction','instructions'),('WorkSession','sessions'),('ProjectPatternCopy','pattern')]:
    cur.execute('SELECT row_to_json(t) FROM "'+table+'" t WHERE "projectId"=%s ORDER BY id',(b['id'],));db[key]=[x[0] for x in cur.fetchall()]
 winner=next((x['request'] for x in replies if x['status']==200),None)
 ok=sorted(x['status'] for x in replies)==[200,409] and bool(winner)
 if ok:
  ok=(db['memo']==winner['memo'] and db['name']==winner['name'] and db['isFavorite']==winner['isFavorite'] and db['counter'][0]['currentRow']==winner['rowCounter']['currentRow'] and [x['id'] for x in db['instructions']]==[winner['rowCounter']['rowInstructions'][0]['id']] and [x['id'] for x in db['sessions']]==[winner['workSessions'][0]['id']] and [x['id'] for x in db['pattern']]==[winner['patternCopy']['id']] and next(x for x in replies if x['status']==409)['response']['code']=='PROJECT_CONFLICT')
 out.append({'trial':i+1,'baseline':b['baseUpdatedAt'],'replies':replies,'db':db,'pass':ok})
 (R/f'evidence/api-concurrency-{path}.json').write_text(json.dumps(out,ensure_ascii=False,indent=2))
print({'path':path,'trials':len(out),'pass':sum(x['pass'] for x in out)},flush=True)
assert all(x['pass'] for x in out),'Concurrency regression failed'
