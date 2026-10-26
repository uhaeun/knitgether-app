import json,re,hashlib,xml.etree.ElementTree as ET
from pathlib import Path
R=Path(__file__).parent;E=R/'evidence';checks={}
def check(name,value):
    checks[name]=bool(value)
    assert value,name
j=json.loads((E/'child-jest-results.json').read_text())
check('real_db_40',j['numTotalTests']==40 and j['numPassedTests']==40 and j['numPendingTests']==0 and j['success'])
check('server_147',bool(re.search(r'Tests:\s+147 passed, 147 total',(E/'server-final.log').read_text())))
check('api_75','75 passed' in (E/'api-verified.log').read_text())
s=(E/'swift-results.log').read_text()
check('swift_359_41_suites','Test run with 359 tests in 41 suites passed' in s and '** TEST SUCCEEDED **' in s)
account=json.loads((E/'test-account.json').read_text()); rows=[]
http=[json.loads(x) for x in (E/'http.jsonl').read_text().splitlines()]
visual=[]
for device in ['A','B']:
    result=json.loads((E/('ui03-results-'+device+'.json')).read_text())
    check('ui03_'+device,len(result)==12 and all(x['status']=='PASS' for x in result))
    rows+=result
    for unit in ['Metric','Imperial','US','cm']:
        row=next(x for x in result if x['case']=='UI03-CM-'+unit)
        check('legacy_sql_'+device+'_'+unit,row['detail']['dbProfile']==[account['userId'],unit])
        reads=[x for x in http if x['method']=='GET' and x['path']=='/api/v1/profile' and x['status']==200 and x['context'].get('actor')==device and x['context'].get('stage')=='UI03_LEGACY_'+unit and x['response'].get('preferredUnits')==unit and x['response'].get('id')==account['userId']]
        check('legacy_native_http_'+device+'_'+unit,bool(reads))
        xml=ET.parse(E/(device+'-ui03-gauge-'+unit+'.xml'))
        app=next(x for x in xml.iter() if x.get('type')=='XCUIElementTypeApplication')
        height=float(app.get('height'))
        positions=[]
        for label in ['25코','30단','약 100코','약 165단']:
            elements=[x for x in xml.iter() if x.get('type')=='XCUIElementTypeStaticText' and x.get('label')==label]
            shown=[x for x in elements if x.get('visible')=='true' and 0<=float(x.get('y')) and float(x.get('y'))+float(x.get('height'))<=height]
            check('visible_'+device+'_'+unit+'_'+label,bool(shown))
            positions.append({'label':label,'y':shown[0].get('y'),'height':shown[0].get('height')})
        visual.append({'device':device,'unit':unit,'positions':positions})
    for file in E.glob(device+'-ui03-*.xml'):
        if 'gauge' in file.name:continue
        text=file.read_text()
        bad=[x for x in ['Metric','Imperial','기본 단위','이름 / 단위','게이지와 길이 입력에서 사용할','인치','단위 선택'] if x in text]
        check('unit_absence_'+file.stem,not bad)
    check('installed_uuid_'+device,'A4EAA2CF-FBDA-38E2-ACC2-930BC3563327' in (E/('installed-app-'+str(0 if device=='A' else 1)+'.txt')).read_text())
audit=json.loads((E/'review-source-audit.json').read_text())
check('review_source_matches',all(x['buildSourceMatches'] for x in audit['files']))
result={'status':'PASS','checks':checks,'uiCases':len(rows),'realDbCases':40,'serverCases':147,'apiCases':75,'swiftCases':359,'swiftSuites':41,'visibleGaugeResults':visual}
(E/'completion-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print('PASS',len(checks),'audit checks; UI24 / SQL40 / server147 / API75 / Swift359')
