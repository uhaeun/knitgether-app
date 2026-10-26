import json,hashlib,re,sys
from pathlib import Path
R=Path(__file__).resolve().parent;src=R.parents[1];rel=R.relative_to(src);E=R/'evidence'
dst=Path(sys.argv[1])
docs=['docs/qa/portfolio/'+x for x in ['02_functional_spec.md','09_test_case_master.md','10_defect_catalog.md','15_release_decision.md']]+['docs/qa/submission/portfolio.md','qa-runs/README.md']
files=[rel/p.name for p in R.iterdir() if p.is_file() and p.suffix in ['.md','.py','.csv']]+[rel/'.gitignore']
names=['migrate.log','child-red.log','child-red.json','scope-red.log','scope-red.json','child-verified.log','child-verified.json','child-jest-results.json','child-case-results.json','server-final.log','api-verified.log','server-build.log','swift-results.log','completion-audit.json','review-source-audit.json','http.jsonl','events.jsonl','phase.json','test-account.json','installed-app-0.txt','installed-app-1.txt','ui03-results-A.json','ui03-results-B.json','ui03-A.log','ui03-B.log']
files += [rel/'evidence'/name for name in names]
files += [rel/'evidence'/p.name for p in E.iterdir() if p.suffix in ['.png','.xml'] and p.name.startswith(('A-ui03-','B-ui03-','native-','setup-B-failure'))]
files += [Path(p) for p in docs]
manifest=[]
for f in sorted(set(files)):
 data=(src/f).read_bytes()
 assert not re.search(rb'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}',data),f
 assert 'private' not in str(f) and not (f.suffix=='.json' and 'sessions' in f.name) and f.suffix!='.dump',f
 target=dst/f;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
 manifest.append({'path':str(f),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
def audit(value):
 if isinstance(value,dict):
  for key,v in value.items():
   if any(s in key.lower() for s in ['token','password','secret']):assert v=='[REDACTED]',key
   else:audit(v)
 elif isinstance(value,list):
  for item in value:audit(item)
for line in (E/'http.jsonl').read_text().splitlines():
 row=json.loads(line);audit(row['request']);audit(row['response'])
meta={'scope':'Public candidate evidence only; raw logs/sessions/dump/builds excluded','files':manifest}
for root in [src,dst]:
 (root/rel/'evidence/public-manifest.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2))
print('public files',len(manifest),'bytes',sum(x['bytes'] for x in manifest),'secret-value audit PASS')
