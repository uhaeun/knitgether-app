"""Supplement: both actors write only through iOS UI; SQL/HTTP are observers."""
import sys,json,time,traceback
from pathlib import Path
from datetime import datetime,timezone
import psycopg2
from appium import webdriver
from appium.options.ios import XCUITestOptions
ROOT=Path(__file__).resolve().parents[2];E=Path(__file__).parent/'evidence'
sys.path.insert(0,str(ROOT/'qa/appium'))
from pages.base_page import PRED
from pages.my_knitting_page import MyKnittingPage
from pages.workspace_page import WorkspacePage
from pages.project_info_page import ProjectInfoPage
from pages.project_form_page import ProjectFormPage
sessions=json.loads((E/'driver-sessions.json').read_text());results=[]
def attach(i):
 class Attached(webdriver.Remote):
  def start_session(self,capabilities):self.session_id=sessions[i]['session'];self.caps={'platformName':'iOS'}
 return Attached('http://127.0.0.1:14723',options=XCUITestOptions())
a,b=attach(0),attach(1);pa,pb=ProjectInfoPage(a),ProjectInfoPage(b)
pid=json.loads((E/'sync-08-recovered-db.json').read_text())['id']
def phase(stage,actor):
 event=dict(at=datetime.now(timezone.utc).isoformat(),stage='PURE_UI_'+stage,actor=actor)
 (E/'phase.json').write_text(json.dumps(event))
 with (E/'events.jsonl').open('a') as f:f.write(json.dumps(event)+'\n')
def snap(d,name):
 d.save_screenshot(str(E/(name+'.png')));(E/(name+'.xml')).write_text(d.page_source)
def state(label):
 with psycopg2.connect(host='127.0.0.1',port=55434,user='knitgether',dbname='knitgether_qa_sync11_20261024') as c:
  with c.cursor() as cur:
   cur.execute('SELECT row_to_json(p) FROM "Project" p WHERE id=%s',(pid,));s=cur.fetchone()[0]
 (E/(label+'-db.json')).write_text(json.dumps(s,ensure_ascii=False,indent=2));return s
def last_patch():
 rows=[json.loads(line) for line in (E/'http.jsonl').read_text().splitlines()]
 return [r for r in rows if r['method']=='PATCH' and r['path']=='/api/v1/projects/'+pid][-1]
def dismiss(d):
 alerts=d.find_elements(PRED,'type == "XCUIElementTypeAlert"')
 assert alerts,'Expected a native conflict alert'
 btn=alerts[0].find_elements(PRED,'type == "XCUIElementTypeButton" AND label IN {"확인","OK"}')
 assert btn;btn[0].click();time.sleep(.5)
def record(case,ok,detail):
 results.append(dict(case=case,status='PASS' if ok else 'FAIL',detail=detail,at=datetime.now(timezone.utc).isoformat()))
 (E/'pure-ui-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(results[-1],flush=True)
try:
 phase('B_DRAFT','B');pb.type_in('workspace.memo.field','B pure UI verified draft')
 initial=state('pure-00-initial');snap(b,'pure-01-B-draft')
 phase('A_REFRESH_PROJECT','A');a.terminate_app('com.uhaeun.KnitGether');a.activate_app('com.uhaeun.KnitGether');time.sleep(2)
 MyKnittingPage(a).open().open_project(initial['name']);WorkspacePage(a).show_info_tab()
 phase('A_EDIT_OTHER_FIELDS','A');WorkspacePage(a).open_edit_form();form=ProjectFormPage(a)
 form.enter_name('SYNC11 A UI final verified')
 done=a.find_elements(PRED,'type == "XCUIElementTypeButton" AND name == "Done"')
 if done:done[-1].click();time.sleep(.7)
 for _ in range(5):
  outer=form.find('type == "XCUIElementTypeSwitch" AND label CONTAINS "즐겨찾기"',PRED)
  if outer.is_displayed() and outer.rect['y']<600:break
  a.execute_script('mobile: swipe',{'direction':'up'});time.sleep(.5)
 if form.favorite_on():
  outer=form.find('type == "XCUIElementTypeSwitch" AND label CONTAINS "즐겨찾기"',PRED)
  inner=outer.find_elements(PRED,'type == "XCUIElementTypeSwitch"')
  assert inner,'Actual favorite switch missing'
  form.tap_at(inner[-1]);time.sleep(.5)
 assert not form.favorite_on(),'Native favorite switch did not change before save' 
 snap(a,'pure-02-A-edit-form');form.tap_at_locator('project.save');time.sleep(3)
 assert not form.exists('project.form.name',timeout=1),'Edit form remained open after save'
 s=state('pure-03-A-other-fields');snap(a,'pure-03-A-fields-saved')
 record('PURE-A-UI-OTHER-FIELDS-SAVE',s['name']=='SYNC11 A UI final verified' and not s['isFavorite'] and last_patch()['status']==200,{'name':s['name'],'isFavorite':s['isFavorite']})
 phase('B_CONFLICT_AFTER_A_FIELDS','B');pb.tap('workspace.memo.save');time.sleep(2);snap(b,'pure-04-B-conflict')
 record('PURE-B-CONFLICT',last_patch()['status']==409 and pb.has_text('입력하신 내용은 그대로 있어요'),last_patch()['response'])
 dismiss(b);record('PURE-B-DRAFT-KEPT',pb.memo_value()=='B pure UI verified draft',pb.memo_value())
 phase('A_INTERVENING_MEMO','A');pa.scroll_to_text('작업 메모');pa.save_memo('A intervening UI memo');time.sleep(2)
 s=state('pure-05-A-intervening');snap(a,'pure-05-A-memo-saved')
 record('PURE-A-INTERVENING-SAVE',last_patch()['status']==200 and s['memo']=='A intervening UI memo',s['memo'])
 phase('B_RECONFLICT','B');pb.tap('workspace.memo.save');time.sleep(2);snap(b,'pure-06-B-reconflict')
 record('PURE-B-RECONFLICT',last_patch()['status']==409 and state('pure-06-reconflict')['memo']=='A intervening UI memo',last_patch()['response'])
 dismiss(b);assert pb.memo_value()=='B pure UI verified draft'
 phase('B_MANUAL_RECOVERY','B');pb.tap('workspace.memo.save');time.sleep(2);s=state('pure-07-final');snap(b,'pure-07-B-recovered')
 record('PURE-B-RECOVERY',last_patch()['status']==200 and s['memo']=='B pure UI verified draft',s['memo'])
 record('PURE-B-OTHER-FIELDS-PRESERVED',s['name']=='SYNC11 A UI final verified' and not s['isFavorite'],{'name':s['name'],'isFavorite':s['isFavorite']})
except Exception:
 (E/'pure-ui-error.txt').write_text(traceback.format_exc());snap(a,'pure-error-A');snap(b,'pure-error-B');raise
