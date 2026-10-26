import json,time,requests
from pathlib import Path
from appium import webdriver
from appium.options.ios import XCUITestOptions
E=Path(__file__).parent/'evidence';sessions=json.loads((E/'driver-sessions.json').read_text());new=[]
for i,s in enumerate(sessions):
 try:requests.delete('http://127.0.0.1:14723/session/'+s['session'],timeout=15)
 except Exception:pass
 o=XCUITestOptions()
 caps={'platformName':'iOS','appium:automationName':'XCUITest','appium:udid':s['udid'],'appium:platformVersion':'26.5','appium:bundleId':'com.uhaeun.KnitGether','appium:noReset':True,'appium:wdaLocalPort':18101+i,'appium:mjpegServerPort':19101+i,'appium:derivedDataPath':'/tmp/knitgether-ios-retest-20261022/'+('WDA' if i==0 else 'WDA-B'),'appium:usePrebuiltWDA':True,'appium:useNewWDA':True,'appium:skipLogCapture':True,'appium:showXcodeLog':True,'appium:waitForIdleTimeout':1.0,'appium:simulatorStartupTimeout':360000,'appium:wdaLaunchTimeout':300000,'appium:newCommandTimeout':3600,'appium:processArguments':{'args':['-knitgether.onboardingCompleted','YES'],'env':{'KNITGETHER_API_BASE_URL':'http://127.0.0.1:3300/api/v1','KNITGETHER_DISABLE_DEV_AUTH_TOKEN':'1'}}}
 o.load_capabilities(caps);d=webdriver.Remote('http://127.0.0.1:14723',options=o)
 d.update_settings({'boundElementsByIndex':True})
 new.append({'session':d.session_id,'udid':s['udid']});(E/'driver-sessions.json').write_text(json.dumps(new+sessions[len(new):]));print('RESTORED',i,d.session_id,flush=True)
 d.save_screenshot(str(E/('restored-'+str(i)+'.png')))
(E/'driver-sessions.json').write_text(json.dumps(new))
