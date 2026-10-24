"""Server/DB fallback evidence. No UI or draft-preservation claims."""
import sys,json,uuid,copy
from pathlib import Path
import requests,psycopg2
ROOT=Path(__file__).resolve().parents[2];E=Path(__file__).parent/'evidence'
sys.path.insert(0,str(ROOT/'qa/api-tests'))
from helpers import project_payload
base='http://127.0.0.1:3300/api/v1'
r=requests.post(base+'/auth/register',json={'email':'sequence-'+uuid.uuid4().hex[:10]+'@example.com','password':'qa-pass-123456','displayName':'Sequential QA'},timeout=15);r.raise_for_status()
h={'Authorization':'Bearer '+r.json()['accessToken']}
p=project_payload(name='Sequential baseline');pid=p['id'];out=[]
def state():
    with psycopg2.connect(host='127.0.0.1',port=55432,user='knitgether',dbname='knitgether_qa_20261022') as c:
        with c.cursor() as cur:
            cur.execute('SELECT memo,name,"isFavorite","updatedAt" FROM "Project" WHERE id=%s',(pid,));row=cur.fetchone()
            cur.execute('SELECT "currentRow" FROM "RowCounter" WHERE "projectId"=%s',(pid,));counter=cur.fetchone()[0]
    return dict(zip(['memo','name','isFavorite','updatedAt'],row))|{'currentRow':counter}
def save(label,method,body):
    r=requests.request(method,base+'/projects'+('' if method=='POST' else '/'+pid),headers=h,json=body,timeout=15)
    out.append({'step':label,'request':copy.deepcopy(body),'status':r.status_code,'response':r.json(),'db':state()});return r
r=save('create','POST',p);assert r.status_code==201
baseline=r.json()['updatedAt']
a=copy.deepcopy(p);a.update(baseUpdatedAt=baseline,memo='A first',name='A metadata kept',isFavorite=True);a['rowCounter']['currentRow']=7
r=save('A first save','PATCH',a);assert r.status_code==200
b=copy.deepcopy(p);b.update(baseUpdatedAt=baseline,memo='B pending')
r=save('B stale save','PATCH',b);assert r.status_code==409 and state()['memo']=='A first'
latest=requests.get(base+'/projects/'+pid,headers=h,timeout=15).json()
b=copy.deepcopy(a);b.update(baseUpdatedAt=latest['updatedAt'],memo='B explicit retry')
r=save('B retry using refreshed baseline and metadata','PATCH',b)
assert r.status_code==200 and state()['memo']=='B explicit retry' and state()['name']=='A metadata kept' and state()['currentRow']==7
(E/'api-sequential-db.json').write_text(json.dumps(out,ensure_ascii=False,indent=2,default=str))
print('PASS API sequential stale conflict / server A preservation / refreshed retry / metadata SQL verification. This is not iOS E2E.')
