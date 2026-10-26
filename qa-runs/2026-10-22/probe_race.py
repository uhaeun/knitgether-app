"""Additional API concurrency probe; never counted as iOS E2E."""
import sys,json,threading,concurrent.futures,os,uuid
from pathlib import Path
import requests,psycopg2
ROOT=Path(__file__).resolve().parents[2]; E=Path(__file__).parent/'evidence'
sys.path.insert(0,str(ROOT/'qa/api-tests'))
from helpers import project_payload
base=os.environ.get('QA_API_URL','http://127.0.0.1:3300/api/v1')
r=requests.post(base+'/auth/register',json={'email':'race-'+uuid.uuid4().hex[:12]+'@example.com','password':'qa-pass-123456','displayName':'QA race'},timeout=10);r.raise_for_status()
h={'Authorization':'Bearer '+r.json()['accessToken']}
out=[]
for i in range(10):
    body=project_payload(name='Race '+str(i));pid=body['id']
    r=requests.post(base+'/projects',headers=h,json=body,timeout=10);r.raise_for_status()
    body['baseUpdatedAt']=r.json()['updatedAt']
    barrier=threading.Barrier(2)
    def write(memo):
        barrier.wait()
        r=requests.patch(base+'/projects/'+pid,headers=h,json={**body,'memo':memo},timeout=15)
        return {'memo':memo,'status':r.status_code,'response':r.json()}
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:
        replies=list(ex.map(write,['Concurrent A','Concurrent B']))
    with psycopg2.connect(host='127.0.0.1',port=55432,user='knitgether',dbname='knitgether_qa_20261022') as c:
        with c.cursor() as cur:
            cur.execute('SELECT memo,"updatedAt" FROM "Project" WHERE id=%s',(pid,));db=cur.fetchone()
    out.append({'trial':i+1,'id':pid,'baseline':body['baseUpdatedAt'],'responses':replies,'db':db,'pass':sorted(x['status'] for x in replies)==[200,409]})
(E/('api-concurrency-direct.json' if ':3301/' in base else 'api-concurrency.json')).write_text(json.dumps(out,ensure_ascii=False,indent=2,default=str))
print({'trials':len(out),'pass':sum(x['pass'] for x in out),'statuses':[[r['status'] for r in x['responses']] for x in out]})
