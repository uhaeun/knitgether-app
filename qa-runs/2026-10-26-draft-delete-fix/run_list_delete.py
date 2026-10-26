import sys,json,time,subprocess,base64,os
from pathlib import Path
import psycopg2
from appium import webdriver
from appium.options.ios import XCUITestOptions
R=Path(__file__).resolve().parents[2];E=Path(__file__).parent/'evidence';sys.path.insert(0,str(R/'qa/appium'))
from pages.my_knitting_page import MyKnittingPage
from pages.workspace_page import WorkspacePage
from pages.project_info_page import ProjectInfoPage
session=json.loads((E/'driver-sessions.json').read_text())[0]
class Attached(webdriver.Remote):
 def start_session(self,capabilities):self.session_id=session['session'];self.caps={'platformName':'iOS'}
d=Attached('http://127.0.0.1:14723',options=XCUITestOptions());mode=os.environ['KG_DELETE_MODE'];name='Draft list delete '+mode
account=json.loads((R/'qa-runs/2026-10-26-session-fix/evidence/test-account.json').read_text())
def launch():
 d.terminate_app('com.uhaeun.KnitGether');d.execute_script('mobile: launchApp',{'bundleId':'com.uhaeun.KnitGether','arguments':['-knitgether.onboardingCompleted','YES'],'environment':{'KNITGETHER_API_BASE_URL':'http://127.0.0.1:3300/api/v1','KNITGETHER_DISABLE_DEV_AUTH_TOKEN':'1'}});time.sleep(2)
def row():
 with psycopg2.connect(host='127.0.0.1',port=55438,user='knitgether',dbname='knitgether_qa_sync11_session_20261026') as c:
  with c.cursor() as cur:
   cur.execute('SELECT row_to_json(p) FROM "Project" p WHERE "ownerId"=%s AND name=%s',(account['userId'],name));rows=cur.fetchall();assert len(rows)==1;return rows[0][0]
def snap(label):d.save_screenshot(str(E/(mode+'-'+label+'.png')));(E/(mode+'-'+label+'.xml')).write_text(d.page_source)
if os.environ.get('KG_DELETE_INSTALL')=='1':
 d.terminate_app('com.uhaeun.KnitGether');d.install_app('/tmp/knitgether-qa-draft-20261026/Build/Products/Debug-iphonesimulator/KnitGether.app')
installed=Path(subprocess.check_output(['xcrun','simctl','get_app_container',session['udid'],'com.uhaeun.KnitGether','app'],text=True,timeout=10).strip())
(E/(mode+'-installed-app.txt')).write_text(subprocess.check_output(['dwarfdump','--uuid',str(installed/'KnitGether.debug.dylib')],text=True))
launch();lst=MyKnittingPage(d).open();lst.create_project(name);lst.open_project(name);WorkspacePage(d).show_info_tab();p=ProjectInfoPage(d);p.type_in('workspace.memo.field','Draft before explicit list deletion');snap('01-draft')
before=row();container=Path(subprocess.check_output(['xcrun','simctl','get_app_container',session['udid'],'com.uhaeun.KnitGether','data'],text=True,timeout=10).strip());key=base64.b64encode(account['userId'].encode()).decode().replace('/','_').replace('+','-');file=container/'Library/Application Support/ProjectMemoDrafts'/f"{key}.{before['id'].upper()}.txt";assert file.read_text()=='Draft before explicit list deletion'
launch();lst=MyKnittingPage(d).open();lst.long_press_menu(name,'삭제');snap('02-delete-confirm');lst.confirm_delete();time.sleep(3);after=row();snap('03-deleted-list')
result={'case':'DRAFT-LIST-PROJECT-DELETE','status':'PASS' if after['deletedAt'] and not file.exists() else 'FAIL','mode':mode,'before':before,'after':after,'draftFileRemains':file.exists(),'UIProjectAbsent':not lst.has_project(name)}
(E/(mode+'-ui-result.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2));print(result,flush=True)
assert after['deletedAt'] and result['UIProjectAbsent']
if mode=='red':assert result['status']=='FAIL' and file.exists()
else:assert result['status']=='PASS'
