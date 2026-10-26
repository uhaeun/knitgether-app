"""Supplement screenshots with memo fully visible; preserves original execution evidence."""
from pathlib import Path
source=(Path(__file__).parent/'run_boundary_ui.py').read_text()
exec(compile(source.split('gate=NetGate')[0],str(Path(__file__).parent/'run_boundary_ui.py'),'exec'))
results=[]
def visible_shot(name):
 for _ in range(10):
  field=p.find('workspace.memo.field');r=field.rect;h=d.get_window_size()['height']
  if field.is_displayed() and r['y']>=100 and r['y']+r['height']<h-50:break
  d.execute_script('mobile: swipe',{'direction':'up'});time.sleep(.5)
 else:raise AssertionError('Memo not fully visible')
 snap(name)
def reopen():
 relaunch('http://127.0.0.1:3300/api/v1')
 MyKnittingPage(d).open().open_project(final['name']);WorkspacePage(d).show_info_tab()
p=ProjectInfoPage(d)
try:
 phase('VISIBLE_DRAFT_SUPPLEMENT')
 MyKnittingPage(d).open().open_project(final['name']);WorkspacePage(d).show_info_tab()
 baseline=projects(final['name'])[0]
 draft='Visible process lifetime draft'
 p.type_in('workspace.memo.field',draft);visible_shot('visible-draft-01-before-termination')
 assert draft_path.read_text()==draft
 reopen();assert p.memo_value()==draft and projects(final['name'])[0]==baseline
 visible_shot('visible-draft-02-restored')
 results.append({'case':'VISIBLE-PROCESS-RESTORE','status':'PASS','draft':draft,'serverUnchanged':True})
 p.tap('workspace.memo.discard');assert not draft_path.exists()
 reopen();assert p.memo_value()==baseline['memo'];visible_shot('visible-draft-03-discarded')
 results.append({'case':'VISIBLE-DISCARD-REMOVED','status':'PASS','memo':p.memo_value(),'draftFileRemoved':True})
 p.save_memo('Visible draft explicitly saved');assert not draft_path.exists()
 reopen();assert p.memo_value()=='Visible draft explicitly saved'
 visible_shot('visible-draft-04-explicit-save')
 rows=projects(final['name']);assert rows[0]['memo']==p.memo_value()
 (E/'visible-draft-final-db.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
 results.append({'case':'VISIBLE-SAVE-REMOVED','status':'PASS','memo':p.memo_value(),'draftFileRemoved':True})
finally:
 (E/'visible-draft-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(results,flush=True)
