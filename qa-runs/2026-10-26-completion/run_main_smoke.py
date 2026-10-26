import json,requests,psycopg2,uuid,subprocess
from pathlib import Path
from datetime import datetime,timezone
BASE='http://127.0.0.1:3303/api/v1'
OUT=Path(__file__).parent/'evidence/main-smoke.json'
records=[]
def clean(x):
    if isinstance(x,dict):return {k:('[REDACTED]' if any(t in k.lower() for t in ['token','password','secret']) else clean(v)) for k,v in x.items()}
    if isinstance(x,list):return [clean(v) for v in x]
    return x
def call(method,path,body=None,status=200):
    r=requests.request(method,BASE+path,json=body,headers={'Authorization':'Bearer '+token} if token else {},timeout=20)
    try:response=r.json()
    except ValueError:response=r.text
    records.append({'method':method,'path':path,'request':clean(body),'status':r.status_code,'response':clean(response)})
    assert r.status_code==status,(method,path,r.status_code,response)
    return response
token=None
call('GET','/health')
account=call('POST','/auth/register',{'email':'main-smoke-'+uuid.uuid4().hex+'@example.com','password':uuid.uuid4().hex,'displayName':'Main QA'},201)
token=account['accessToken']
id=str(uuid.uuid4());counter=str(uuid.uuid4())
body={'id':id,'name':'Main merge verification','status':'WIP','isFavorite':False,'memo':'','startDate':'2026-10-26T00:00:00.000Z','relatedSkillIds':[],'rowCounter':{'id':counter,'projectId':id,'name':'Main','currentRow':0,'rowInstructions':[]},'workSessions':[],'patternCopy':None}
created=call('POST','/projects',body,201)
original=created['updatedAt'];body.update(baseUpdatedAt=original,memo='A committed',isFavorite=True);body['rowCounter']['currentRow']=7
saved=call('PATCH','/projects/'+id,body)
stale={**body,'memo':'B stale'};call('PATCH','/projects/'+id,stale,409)
assert call('GET','/projects/'+id)['memo']=='A committed'
body.update(baseUpdatedAt=saved['updatedAt'],memo='B explicit retry')
retried=call('PATCH','/projects/'+id,body)
instruction={'id':str(uuid.uuid4()),'rowCounterId':counter,'rowNumber':3,'instructionText':'Child preserved','skillTags':''}
call('POST','/projects/'+id+'/row-instructions',instruction,201)
body['baseUpdatedAt']=retried['updatedAt'];call('PATCH','/projects/'+id,body,409)
with psycopg2.connect(host='127.0.0.1',port=55439,user='knitgether',dbname='knitgether_qa_sync11_completion_20261026') as db:
    with db.cursor() as c:
        c.execute('SELECT p.id,p.memo,p."isFavorite",r."currentRow",i."instructionText" FROM "Project" p JOIN "RowCounter" r ON r."projectId"=p.id JOIN "RowInstruction" i ON i."projectId"=p.id WHERE p.id=%s',(id,));state=c.fetchone()
assert state[1:]==('B explicit retry',True,7,'Child preserved'),state
result={'status':'PASS','at':datetime.now(timezone.utc).isoformat(),'mainCommit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'requests':records,'sql':state}
OUT.parent.mkdir(exist_ok=True);OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2));print('PASS main local HTTP409/manual retry/child preservation + SQL')
