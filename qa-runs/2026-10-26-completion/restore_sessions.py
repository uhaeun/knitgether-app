import json,time,requests,os
from pathlib import Path
from appium import webdriver
from appium.options.ios import XCUITestOptions
E=Path(__file__).parent/'evidence';E.mkdir(exist_ok=True)
sessions=json.loads((E/'driver-sessions.json').read_text()) if (E/'driver-sessions.json').exists() else [{'session':None,'udid':os.environ.get('QA_UDID_A','840CB58F-9AD8-4403-A8C3-3E2D5F93B0C5')},{'session':None,'udid':os.environ.get('QA_UDID_B','311D4B83-D09B-4237-824C-ABCDD09264D1')}]
new=[]
for i,s in enumerate(sessions):
 try:
  if s.get('session'): requests.delete('http://127.0.0.1:14723/session/'+s['session'],timeout=15)
 except Exception:pass
 o=XCUITestOptions()
 caps={'platformName':'iOS','appium:automationName':'XCUITest','appium:udid':s['udid'],'appium:platformVersion':'26.5','appium:bundleId':'com.uhaeun.KnitGether','appium:noReset':True,'appium:wdaLocalPort':18101+i,'appium:mjpegServerPort':19101+i,'appium:derivedDataPath':'/tmp/knitgether-ios-retest-20261022/'+('WDA' if i==0 else 'WDA-B'),'appium:usePrebuiltWDA':True,'appium:useNewWDA':True,'appium:skipLogCapture':True,'appium:showXcodeLog':True,'appium:waitForIdleTimeout':1.0,'appium:simulatorStartupTimeout':360000,'appium:wdaLaunchTimeout':300000,'appium:newCommandTimeout':3600,'appium:processArguments':{'args':['-knitgether.onboardingCompleted','YES'],'env':{'KNITGETHER_API_BASE_URL':'http://127.0.0.1:3300/api/v1','KNITGETHER_DISABLE_DEV_AUTH_TOKEN':'1'}}}
 o.load_capabilities(caps);d=webdriver.Remote('http://127.0.0.1:14723',options=o)
 d.update_settings({'boundElementsByIndex':True})
 new.append({'session':d.session_id,'udid':s['udid']});(E/'driver-sessions.json').write_text(json.dumps(new+sessions[len(new):]));print('RESTORED',i,d.session_id,flush=True)
 d.save_screenshot(str(E/('restored-'+str(i)+'.png')))
(E/'driver-sessions.json').write_text(json.dumps(new))
