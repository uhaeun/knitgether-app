"""Device-local draft acceptance plus reuse of UI-78 offline/recovery criteria."""
import sys, json, time, traceback, subprocess, base64
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
 with psycopg2.connect(host='127.0.0.1',port=55438,user='knitgether',dbname='knitgether_qa_sync11_session_20261026') as c:
  with c.cursor() as cur:
   cur.execute('SELECT row_to_json(p) FROM "Project" p WHERE "ownerId"=%s AND name=%s AND "deletedAt" IS NULL',(account['userId'],name));return [x[0] for x in cur.fetchall()]
def relaunch(base):
 d.terminate_app('com.uhaeun.KnitGether')
 d.execute_script('mobile: launchApp',{'bundleId':'com.uhaeun.KnitGether','arguments':['-knitgether.onboardingCompleted','YES'],'environment':{'KNITGETHER_API_BASE_URL':base,'KNITGETHER_DISABLE_DEV_AUTH_TOKEN':'1'}});time.sleep(2)
container=Path(subprocess.check_output(['xcrun','simctl','get_app_container',session['udid'],'com.uhaeun.KnitGether','data'],text=True,timeout=10).strip())
owner_key=base64.b64encode(account['userId'].encode()).decode().replace('/','_').replace('+','-')
draft_path=container/'Library/Application Support/ProjectMemoDrafts'/f"{owner_key}.{final['id'].upper()}.txt"
gate=NetGate(port=3999,forward_port=3300)
try:
 phase('PROCESS_LIFETIME')
 p=ProjectInfoPage(d);draft='Unsaved process lifetime draft';p.type_in('workspace.memo.field',draft);snap('lifetime-01-before-termination')
 assert p.memo_value()==draft
 before=projects(final['name'])[0]
 (E/'lifetime-before-db.json').write_text(json.dumps(before,ensure_ascii=False,indent=2))
 assert draft_path.read_text()==draft
 relaunch('http://127.0.0.1:3300/api/v1')
 MyKnittingPage(d).open().open_project(final['name']);WorkspacePage(d).show_info_tab();p.scroll_to_text('작업 메모')
 value=p.memo_value();snap('lifetime-02-after-relaunch');after=projects(final['name'])[0]
 (E/'lifetime-after-db.json').write_text(json.dumps(after,ensure_ascii=False,indent=2))
 assert before['memo']==after['memo'] and before['updatedAt']==after['updatedAt']
 record('DRAFT-PROCESS-LIFETIME','PASS' if value==draft else 'FAIL',{'draftBefore':draft,'valueAfterRelaunch':value,'draftSurvives':value==draft,'serverUnchanged':True,'policy':'User confirmed device-local account/project draft'})
 assert value==draft
 p.tap('workspace.memo.discard');snap('lifetime-03-discarded')
 assert p.memo_value()==before['memo'] and not draft_path.exists()
 relaunch('http://127.0.0.1:3300/api/v1')
 MyKnittingPage(d).open().open_project(final['name']);WorkspacePage(d).show_info_tab();p.scroll_to_text('작업 메모')
 assert p.memo_value()==before['memo']
 record('DRAFT-DISCARD-RELAUNCH','PASS',{'memo':p.memo_value(),'serverUnchanged':projects(final['name'])[0]==after,'draftFileRemoved':not draft_path.exists()})
 p.save_memo('Draft saved explicitly');time.sleep(2)
 assert not draft_path.exists()
 (E/'lifetime-saved-db.json').write_text(json.dumps(projects(final['name'])[0],ensure_ascii=False,indent=2))
 relaunch('http://127.0.0.1:3300/api/v1')
 MyKnittingPage(d).open().open_project(final['name']);WorkspacePage(d).show_info_tab();p.scroll_to_text('작업 메모')
 snap('lifetime-04-saved-relaunch')
 assert p.memo_value()=='Draft saved explicitly' and projects(final['name'])[0]['memo']=='Draft saved explicitly'
 record('DRAFT-EXPLICIT-SAVE-RELAUNCH','PASS',{'memo':p.memo_value(),'draftFileRemoved':not draft_path.exists()})
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
