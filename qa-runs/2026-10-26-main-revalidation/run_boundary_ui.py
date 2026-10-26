"""Draft lifetime characterization plus reuse of UI-78 offline/recovery criteria."""
import sys, json, time, traceback
from datetime import datetime, timezone
from pathlib import Path
import psycopg2
from appium import webdriver
from appium.options.ios import XCUITestOptions

ROOT=Path(__file__).resolve().parents[2];E=Path(__file__).parent/'evidence'
sys.path.insert(0,str(ROOT/'qa/appium'))
from pages.base_page import PRED
from pages.my_knitting_page import MyKnittingPage
from pages.workspace_page import WorkspacePage
from pages.project_info_page import ProjectInfoPage
from support.netgate import NetGate
from support import server_api

session=json.loads((E/'driver-sessions.json').read_text())[1]
class Attached(webdriver.Remote):
 def start_session(self,capabilities):self.session_id=session['session'];self.caps={'platformName':'iOS'}
d=Attached('http://127.0.0.1:14723',options=XCUITestOptions());results=[]
account=json.loads((E/'test-account.json').read_text());final=json.loads((E/'pure-07-final-db.json').read_text())
def phase(stage):
 event={'at':datetime.now(timezone.utc).isoformat(),'stage':'BOUNDARY_'+stage,'actor':'B'}
 (E/'phase.json').write_text(json.dumps(event))
 with (E/'events.jsonl').open('a') as f:f.write(json.dumps(event)+'\n')
def snap(name):
 d.save_screenshot(str(E/(name+'.png')));(E/(name+'.xml')).write_text(d.page_source)
def record(case,status,detail):
 results.append({'case':case,'status':status,'detail':detail});(E/'boundary-ui-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(results[-1],flush=True)
def projects(name):
 with psycopg2.connect(host='127.0.0.1',port=55437,user='knitgether',dbname='knitgether_qa_sync11_revalidation_20261026') as c:
  with c.cursor() as cur:
   cur.execute('SELECT row_to_json(p) FROM "Project" p WHERE "ownerId"=%s AND name=%s AND "deletedAt" IS NULL',(account['userId'],name));return [x[0] for x in cur.fetchall()]
def relaunch(base):
 d.terminate_app('com.uhaeun.KnitGether')
 d.execute_script('mobile: launchApp',{'bundleId':'com.uhaeun.KnitGether','arguments':['-knitgether.onboardingCompleted','YES'],'environment':{'KNITGETHER_API_BASE_URL':base,'KNITGETHER_DISABLE_DEV_AUTH_TOKEN':'1'}});time.sleep(2)
gate=NetGate(port=3999,forward_port=3300)
try:
 phase('PROCESS_LIFETIME')
 p=ProjectInfoPage(d);draft='Unsaved process lifetime draft';p.type_in('workspace.memo.field',draft);snap('lifetime-01-before-termination')
 assert p.memo_value()==draft
 before=projects(final['name'])[0]
 relaunch('http://127.0.0.1:3300/api/v1')
 MyKnittingPage(d).open().open_project(final['name']);WorkspacePage(d).show_info_tab();p.scroll_to_text('작업 메모')
 value=p.memo_value();snap('lifetime-02-after-relaunch');after=projects(final['name'])[0]
 assert before['memo']==after['memo'] and before['updatedAt']==after['updatedAt']
 record('DRAFT-PROCESS-LIFETIME','CHARACTERIZED',{'draftBefore':draft,'valueAfterRelaunch':value,'draftSurvives':value==draft,'serverUnchanged':True,'acceptance':'No product decision for persistence across process termination; not a PASS/FAIL gate'})
 phase('OFFLINE_SETUP')
 gate.open();assert server_api.health_ok(base_url=gate.base_url)
 relaunch(gate.base_url);lst=MyKnittingPage(d).open();name='OFFLINE replay QA'
 phase('OFFLINE_CREATE')
 gate.close();assert not server_api.health_ok(base_url=gate.base_url)
 lst.create_project(name);summary=lst.row_summary(name);snap('offline-01-local-only')
 rows=projects(name);(E/'offline-before-recovery-db.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
 record('UI78-OFFLINE-CREATE','PASS' if '이 기기에만 있음' in summary and len(rows)==0 else 'FAIL',{'summary':summary,'serverCount':len(rows)})
 phase('OFFLINE_RECOVERY')
 gate.open();assert server_api.health_ok(base_url=gate.base_url)
 for _ in range(12):
  if '이 기기에만 있음' not in lst.row_summary(name):break
  lst.retry_sync();lst.pull_to_refresh();time.sleep(2)
 summary=lst.row_summary(name);rows=projects(name);snap('offline-02-recovered');(E/'offline-after-recovery-db.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
 record('UI78-RECOVERY-UNIQUE','PASS' if '이 기기에만 있음' not in summary and lst.project_names().count(name)==1 and len(rows)==1 else 'FAIL',{'summary':summary,'serverCount':len(rows),'serverIds':[x['id'] for x in rows]})
except Exception:
 (E/'boundary-ui-error.txt').write_text(traceback.format_exc());snap('boundary-ui-error');raise
finally:
 gate.close()
 relaunch('http://127.0.0.1:3300/api/v1')
