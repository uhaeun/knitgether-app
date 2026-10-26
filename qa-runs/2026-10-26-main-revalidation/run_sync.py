import sys, json, time, traceback, subprocess,os
from pathlib import Path
from datetime import datetime, timezone
import requests, psycopg2
from appium import webdriver
from appium.options.ios import XCUITestOptions

ROOT = Path(__file__).resolve().parents[2]
RUN = Path(__file__).resolve().parent
E = RUN/'evidence'
sys.path.insert(0,str(ROOT/'qa/appium'))
from pages.auth_page import AuthPage
from pages.my_knitting_page import MyKnittingPage
from pages.workspace_page import WorkspacePage
from pages.project_info_page import ProjectInfoPage
from pages.base_page import PRED
from support import server_api
server_api.BASE_URL = 'http://127.0.0.1:3300/api/v1'
BASE=server_api.BASE_URL
UDIDS=[os.environ.get('QA_UDID_A','840CB58F-9AD8-4403-A8C3-3E2D5F93B0C5'),os.environ.get('QA_UDID_B','311D4B83-D09B-4237-824C-ABCDD09264D1')]
drivers=[]; results=[]
prior_sessions=json.loads((E/'driver-sessions.json').read_text()) if (E/'driver-sessions.json').exists() else []
class Attached(webdriver.Remote):
    def start_session(self,capabilities):
        self.session_id=prior_sessions[len(drivers)]['session'];self.caps={'platformName':'iOS'}
def save_sessions():
    entries=[{'session':dr.session_id,'udid':u} for dr,u in zip(drivers,UDIDS)]
    if os.environ.get('QA_REUSE_SESSIONS')=='1':entries+=prior_sessions[len(entries):]
    (E/'driver-sessions.json').write_text(json.dumps(entries))
def activate_ready(d):
    for attempt in range(20):
        try:d.activate_app('com.uhaeun.KnitGether');return
        except Exception as exc:
            if 'installing or uninstalling' not in str(exc) and 'Busy' not in str(exc):raise
            time.sleep(1)
    raise RuntimeError('iOS installation did not become launchable')
def phase(stage,actor):
    event=dict(at=datetime.now(timezone.utc).isoformat(),stage=stage,actor=actor)
    (E/'phase.json').write_text(json.dumps(event))
    with (E/'events.jsonl').open('a') as f:f.write(json.dumps(event)+'\n')
def record(case, ok, detail):
    results.append(dict(case=case,status='PASS' if ok else 'FAIL',detail=detail,at=datetime.now(timezone.utc).isoformat()))
    (E/'sync-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
    print(results[-1],flush=True)
def shot(d,name):
    d.save_screenshot(str(E/(name+'.png')))
    (E/(name+'.xml')).write_text(d.page_source)
def db_state(pid,label):
    with psycopg2.connect(host='127.0.0.1',port=55437,user='knitgether',dbname='knitgether_qa_sync11_revalidation_20261026') as c:
        with c.cursor() as cur:
            cur.execute('SELECT row_to_json(p) FROM "Project" p WHERE id=%s',(pid,)); state=cur.fetchone()[0]
            cur.execute('SELECT row_to_json(r) FROM "RowCounter" r WHERE "projectId"=%s',(pid,)); state['rowCounter']=cur.fetchone()[0]
    (E/(label+'-db.json')).write_text(json.dumps(state,ensure_ascii=False,indent=2)); return state
def patches(pid):
    return [x for line in (E/'http.jsonl').read_text().splitlines() if (x:=json.loads(line))['method']=='PATCH' and x['path']==f'/api/v1/projects/{pid}']
def open_info(d,name):
    MyKnittingPage(d).open().open_project(name)
    WorkspacePage(d).show_info_tab()
    p=ProjectInfoPage(d); p.scroll_to_text('작업 메모'); return p
def dismiss_conflict(d):
    alerts=d.find_elements(PRED,'type == "XCUIElementTypeAlert"')
    if alerts:
        buttons=alerts[0].find_elements(PRED,'type == "XCUIElementTypeButton" AND label IN {"확인", "OK"}')
        assert buttons,'Conflict alert confirmation missing'
        buttons[0].click();time.sleep(.5)
try:
    for attempt in range(30):
        try:
            if requests.get('http://127.0.0.1:14723/status',timeout=2).status_code==200: break
        except requests.RequestException: pass
        time.sleep(1)
    else: raise RuntimeError('Appium readiness timeout')
    phase('GIVEN_ACCOUNT_AND_PROJECT','API_SETUP')
    account=server_api.register(display_name='SYNC11 QA')
    me=requests.get(BASE+'/auth/me',headers={'Authorization':'Bearer '+account['token']},timeout=15);me.raise_for_status();account['userId']=me.json()['id']
    pid=server_api.create_project(account['token'],'SYNC11 공동 프로젝트')
    (E/'test-account.json').write_text(json.dumps({k:v for k,v in account.items() if k not in ('token','password')},ensure_ascii=False))
    for i,udid in enumerate(UDIDS):
        o=XCUITestOptions()
        o.udid=udid; o.app=os.environ.get('QA_APP_PATH',str(RUN/'build/Build/Products/Debug-iphonesimulator/KnitGether.app'))
        o.no_reset=True
        o.platform_version=os.environ.get('QA_PLATFORM_VERSION','26.5')
        o.set_capability('appium:wdaLocalPort',18101+i)
        o.set_capability('appium:mjpegServerPort',19101+i)
        o.set_capability('appium:derivedDataPath',os.environ.get('QA_WDA_DERIVED_DATA',str(RUN/f'wda-{i}')))
        if os.environ.get('QA_WDA_DERIVED_DATA'):
            o.set_capability('appium:usePrebuiltWDA',True)
        if os.environ.get('QA_WDA_APP_PATH'):
            o.set_capability('appium:usePreinstalledWDA',True)
            o.set_capability('appium:prebuiltWDAPath',os.environ['QA_WDA_APP_PATH'])
        o.set_capability('appium:wdaLaunchTimeout',600000)
        o.set_capability('appium:showXcodeLog',True)
        o.set_capability('appium:newCommandTimeout',3600)
        o.set_capability('appium:useNewWDA',True)
        o.set_capability('appium:processArguments',{'args':['-knitgether.onboardingCompleted','YES'],'env':{'KNITGETHER_API_BASE_URL':BASE,'KNITGETHER_DISABLE_DEV_AUTH_TOKEN':'1'}})
        phase('NATIVE_LOGIN','A' if i==0 else 'B')
        d=Attached('http://127.0.0.1:14723',options=o) if os.environ.get('QA_REUSE_SESSIONS')=='1' else webdriver.Remote('http://127.0.0.1:14723',options=o)
        if os.environ.get('QA_REINSTALL_APP')=='1':
            d.terminate_app('com.uhaeun.KnitGether');d.install_app(o.app)
        d.terminate_app('com.uhaeun.KnitGether')
        d.execute_script('mobile: launchApp',{'bundleId':'com.uhaeun.KnitGether','arguments':['-knitgether.onboardingCompleted','YES'],'environment':{'KNITGETHER_API_BASE_URL':BASE,'KNITGETHER_DISABLE_DEV_AUTH_TOKEN':'1'}})
        time.sleep(2)
        drivers.append(d)
        save_sessions()
        AuthPage(d).ensure_logged_out()
        AuthPage(d).open().login(account['email'],account['password'])
        AuthPage(d).open()
        assert AuthPage(d).logged_in(), 'Native login did not reach authenticated UI on '+str(i)
        shot(d,'native-'+('A' if i==0 else 'B')+'-authenticated')
        app_container=subprocess.check_output(['xcrun','simctl','get_app_container',udid,'com.uhaeun.KnitGether','app'],text=True).strip()
        identity=subprocess.check_output(['dwarfdump','--uuid',str(Path(app_container)/'KnitGether.debug.dylib')],text=True)
        (E/('installed-app-'+str(i)+'.txt')).write_text(udid+'\n'+identity)
        print('Logged in',i,flush=True)
    a,b=drivers
    phase('OPEN_PROJECT','A');pa=open_info(a,'SYNC11 공동 프로젝트')
    phase('OPEN_PROJECT','B');pb=open_info(b,'SYNC11 공동 프로젝트')
    shot(a,'sync-01-a-baseline'); shot(b,'sync-01-b-baseline')
    phase('B_DRAFT','B');pb.type_in('workspace.memo.field','B unsaved memo 20261026')
    shot(b,'sync-02-b-unsaved')
    record('SYNC11-B-DRAFT-NOT-SAVED',db_state(pid,'sync-02-b-unsaved')['memo']=='','B draft present on UI; server memo remains empty')
    phase('A_FIRST_SAVE','A')
    pa.save_memo('A first saved memo 20261026'); time.sleep(2)
    a_baseline=patches(pid)[-1]['request'].get('baseUpdatedAt')
    state=db_state(pid,'sync-03-a-saved')
    record('SYNC11-A-SAVE',state['memo']=='A first saved memo 20261026',state['memo'])
    # A의 저장과 같은 요청 본문으로 별도 필드 변경을 추가한다. UI 수정 검증과 구분한다.
    phase('INJECT_OTHER_FIELDS','API_EXTENSION')
    body=patches(pid)[-1]['request'].copy(); body.update(name='SYNC11 preserved name',isFavorite=True,baseUpdatedAt=requests.get(f'{BASE}/projects/{pid}',headers={'Authorization':'Bearer '+account['token']},timeout=15).json()['updatedAt'])
    body['rowCounter']['currentRow']=7
    r=requests.patch(f'{BASE}/projects/{pid}',headers={'Authorization':'Bearer '+account['token']},json=body,timeout=15)
    assert r.status_code==200,r.text
    phase('B_SAVE_STALE','B');pb.tap('workspace.memo.save'); time.sleep(3)
    shot(b,'sync-04-b-conflict')
    notice=pb.has_text('입력하신 내용은 그대로 있어요');notice_texts=pb.texts()
    dismiss_conflict(b)
    shot(b,'sync-04-b-input-after-dismiss')
    state=db_state(pid,'sync-04-after-conflict')
    record('SYNC11-409',patches(pid)[-1]['status']==409,patches(pid)[-1]['response'])
    record('SYNC11-SAME-BASELINE',bool(a_baseline) and patches(pid)[-1]['request'].get('baseUpdatedAt')==a_baseline,{'A':a_baseline,'B':patches(pid)[-1]['request'].get('baseUpdatedAt')})
    record('SYNC11-SERVER-A-KEPT',state['memo']=='A first saved memo 20261026',state['memo'])
    record('SYNC11-B-INPUT',pb.memo_value()=='B unsaved memo 20261026',pb.memo_value())
    record('SYNC11-B-NOTICE',notice,notice_texts)
    phase('OBSERVE_NO_AUTOMATIC_RETRY','B');before=len(patches(pid)); time.sleep(300)
    record('SYNC11-NO-AUTO-RETRY',len(patches(pid))==before,{'observationSeconds':300,'before':before,'after':len(patches(pid))})
    phase('B_EXPLICIT_RETRY','B');pb.tap('workspace.memo.save'); time.sleep(3)
    shot(b,'sync-05-b-explicit-resave'); state=db_state(pid,'sync-05-final')
    record('SYNC11-EXPLICIT-RESAVE',state['memo']=='B unsaved memo 20261026' and patches(pid)[-1]['status']==200,state['memo'])
    record('SYNC11-OTHER-FIELDS',state['name']=='SYNC11 preserved name' and state['isFavorite'] and state['rowCounter']['currentRow']==7,{'name':state['name'],'isFavorite':state['isFavorite'],'currentRow':state['rowCounter']['currentRow']})
    # B가 재조회한 기준 이후 다시 다른 쓰기가 발생하는 경합. API 쓰기임을 증거에 명시한다.
    phase('RECONFLICT_DRAFT','B');pb.type_in('workspace.memo.field','B repeated conflict pending')
    phase('INTERVENING_WRITE_1','API_EXTENSION')
    body=patches(pid)[-1]['request'].copy(); body.update(baseUpdatedAt=requests.get(f'{BASE}/projects/{pid}',headers={'Authorization':'Bearer '+account['token']},timeout=15).json()['updatedAt'],memo='Intervening writer 1')
    r=requests.patch(f'{BASE}/projects/{pid}',headers={'Authorization':'Bearer '+account['token']},json=body,timeout=15); assert r.status_code==200,r.text
    phase('RECONFLICT_SAVE_1','B');pb.tap('workspace.memo.save'); time.sleep(2)
    dismiss_conflict(b)
    state=db_state(pid,'sync-06-first-reconflict')
    phase('INTERVENING_WRITE_2','API_EXTENSION');body.update(baseUpdatedAt=requests.get(f'{BASE}/projects/{pid}',headers={'Authorization':'Bearer '+account['token']},timeout=15).json()['updatedAt'],memo='Intervening writer 2')
    r=requests.patch(f'{BASE}/projects/{pid}',headers={'Authorization':'Bearer '+account['token']},json=body,timeout=15); assert r.status_code==200,r.text
    phase('RECONFLICT_SAVE_2','B');pb.tap('workspace.memo.save'); time.sleep(2); shot(b,'sync-07-repeated-conflict')
    dismiss_conflict(b)
    state=db_state(pid,'sync-07-reconflict')
    record('SYNC11-RECONFLICT',patches(pid)[-1]['status']==409 and state['memo']=='Intervening writer 2' and pb.memo_value()=='B repeated conflict pending',{'serverMemo':state['memo'],'input':pb.memo_value()})
    phase('RECONFLICT_MANUAL_RECOVERY','B');pb.tap('workspace.memo.save'); time.sleep(2); state=db_state(pid,'sync-08-recovered')
    record('SYNC11-RECONFLICT-RECOVERY',patches(pid)[-1]['status']==200 and state['memo']=='B repeated conflict pending',state['memo'])
    save_sessions()
except Exception:
    save_sessions()
    (E/'sync-error.txt').write_text(traceback.format_exc()); print(traceback.format_exc(),flush=True)
    for i,d in enumerate(drivers):
        try: shot(d,f'sync-error-{i}')
        except Exception: pass
    raise
