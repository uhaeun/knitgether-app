import json,time,subprocess,os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];RUN=Path(__file__).parent;E=RUN/'evidence'
PY='/tmp/knitgether-completion-python/bin/python'
log=E/'swift-verified-private.log'; deadline=time.time()+900
while time.time()<deadline:
    content=log.read_text() if log.exists() else ''
    if '** TEST FAILED **' in content: raise RuntimeError('Swift gate failed')
    if '** TEST SUCCEEDED **' in content: break
    time.sleep(2)
else: raise RuntimeError('Swift gate timed out')
steps=[('restore_sessions.py',{}),('setup_devices.py',{'QA_REUSE_SESSIONS':'1','QA_REINSTALL_APP':'1','QA_APP_PATH':'/tmp/knitgether-qa-completion-build-20261026/Build/Products/Debug-iphonesimulator/KnitGether.app','QA_PLATFORM_VERSION':'26.5'}),('run_ui03.py',{'QA_DEVICE_INDEX':'0'}),('run_ui03.py',{'QA_DEVICE_INDEX':'1'})]
for index,(script,extra) in enumerate(steps):
    state={'step':index,'script':script,'state':'running','started':time.time()};(E/'final-ui-workflow.json').write_text(json.dumps(state))
    name=['restore-final-private.log','setup-final-private.log','ui03-A.log','ui03-B.log'][index]
    with (E/name).open('w') as out:
        subprocess.run([PY,'-u',str(RUN/script)],cwd=ROOT,env={**os.environ,**extra},stdout=out,stderr=subprocess.STDOUT,check=True,timeout=1800)
    print('COMPLETED',index,script,flush=True)
(E/'final-ui-workflow.json').write_text(json.dumps({'state':'complete','at':time.time()}))
