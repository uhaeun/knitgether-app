import sys,json,time,traceback
from pathlib import Path
import psycopg2
from appium import webdriver
from appium.options.ios import XCUITestOptions
ROOT=Path(__file__).resolve().parents[2]; E=Path(__file__).parent/'evidence'
sys.path.insert(0,str(ROOT/'qa/appium'))
from pages.base_page import BasePage,ID,PRED
from pages.auth_page import AuthPage
sessions=json.loads((E/'driver-sessions.json').read_text())
class Attached(webdriver.Remote):
    def start_session(self,capabilities):
        self.session_id=sessions[0]['session']; self.caps={}
d=Attached('http://127.0.0.1:14723',options=XCUITestOptions()); p=BasePage(d)
results=[]
def record(case,ok,detail):
    results.append(dict(case=case,status='PASS' if ok else 'FAIL',detail=detail))
    (E/'ui03-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(results[-1],flush=True)
def snap(name):
    d.save_screenshot(str(E/(name+'.png'))); xml=d.page_source; (E/(name+'.xml')).write_text(xml); return xml
def no_unit(case,name):
    xml=snap(name)
    bad=[s for s in ['Metric','Imperial','기본 단위','이름 / 단위','게이지와 길이 입력에서 사용할'] if s in xml]
    record(case,not bad,{'unexpected':bad,'texts':p.texts()})
def visible(locator):
    for _ in range(10):
        els=d.find_elements(ID,locator)
        if els and els[0].is_displayed(): return els[0]
        d.execute_script('mobile: swipe',{'direction':'up'});time.sleep(.4)
    raise AssertionError('Visible field missing: '+locator)
try:
    p.go_tab('설정'); assert p.exists('settings.profile'); no_unit('UI03-SETTINGS','ui03-01-settings')
    p.tap('settings.profile');time.sleep(2);assert p.exists('settings.profile.name');no_unit('UI03-PROFILE','ui03-02-profile')
    account=json.loads((E/'test-account.json').read_text())
    for unit in ['Metric','Imperial','US','cm']:
        with psycopg2.connect(host='127.0.0.1',port=55432,user='knitgether',dbname='knitgether_qa_20261022') as c:
            with c.cursor() as cur:
                cur.execute('UPDATE "UserProfile" SET "preferredUnits"=%s WHERE id=(SELECT id FROM "UserAccount" WHERE email=%s) RETURNING id,"preferredUnits"',(unit,account['email'])); profile=cur.fetchone()
        d.terminate_app('com.uhaeun.KnitGether');d.activate_app('com.uhaeun.KnitGether');time.sleep(2)
        p.go_tab('설정');p.tap('settings.profile');time.sleep(1)
        snap('ui03-profile-'+unit)
        calls=[json.loads(line) for line in (E/'http.jsonl').read_text().splitlines()]
        reads=[x for x in calls if x['method']=='GET' and x['path']=='/api/v1/profile' and x['status']==200]
        assert reads and reads[-1]['response']['preferredUnits']==unit, 'Legacy profile not fetched by app'
        p.go_tab('도구');p.tap('tool.gauge_calculator');time.sleep(1)
        for key,value in [('sample_width','8'),('sample_height','10'),('sample_stitches','20'),('sample_rows','30'),('target_width','40'),('target_height','55')]:
            f=visible('tool.gauge.'+key);f.clear();f.send_keys(value)
        try:d.hide_keyboard()
        except Exception:pass
        p.scroll_to_text('예상 필요 코/단 수')
        # 결과가 화면에 들어오도록 추가 스크롤. 정적 텍스트의 실제 값으로 판정한다.
        d.execute_script('mobile: swipe',{'direction':'up'});time.sleep(.5)
        snap('ui03-gauge-'+unit);texts=p.texts()
        record('UI03-CM-'+unit,all(x in texts for x in ['25코','30단','약 100코','약 165단']),{'dbProfile':profile,'input':{'sampleCm':[8,10],'counts':[20,30],'targetCm':[40,55]},'texts':texts})
    AuthPage(d).open().logout();time.sleep(1)
    AuthPage(d).select_mode('회원가입');assert p.exists('auth.display_name');no_unit('UI03-SIGNUP','ui03-03-signup')
    d.terminate_app('com.uhaeun.KnitGether')
    d.execute_script('mobile: launchApp',{'bundleId':'com.uhaeun.KnitGether','arguments':[], 'environment':{'KNITGETHER_API_BASE_URL':'http://127.0.0.1:3300/api/v1','KNITGETHER_DISABLE_DEV_AUTH_TOKEN':'1','KNITGETHER_UI_TEST_RESET_ONBOARDING':'1'}})
    time.sleep(2)
    for i in range(5):
        no_unit('UI03-ONBOARDING-'+str(i),'ui03-onboarding-'+str(i))
        if d.find_elements(ID,'onboarding.complete'):break
        p.tap('onboarding.start');time.sleep(.7)
except Exception:
    (E/'ui03-error.txt').write_text(traceback.format_exc());snap('ui03-error');raise
