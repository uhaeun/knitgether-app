import json,hashlib,re,subprocess
from pathlib import Path
from datetime import datetime,timezone
R=Path(__file__).parent.resolve();E=R/'evidence';ROOT=R.parents[1]
results={a:json.loads((E/f'ui03-results-{a}.json').read_text()) for a in 'AB'}
http=[json.loads(l) for l in (E/'http.jsonl').read_text().splitlines()]
reads=[]
for a in 'AB':
 for unit in ['Metric','Imperial','US','cm']:
  result=next(r for r in results[a] if r['case']=='UI03-CM-'+unit)
  matches=[r for r in http if r['method']=='GET' and r['path']=='/api/v1/profile' and r['status']==200 and r.get('context',{}).get('actor')==a and r.get('context',{}).get('stage')=='UI03_LEGACY_'+unit and r['response'].get('id')==result['detail']['dbProfile'][0] and r['response'].get('preferredUnits')==unit and r['at']<=result['at'] and r['at']>='2026-10-24']
  assert matches,(a,unit,'No matching live profile GET')
  reads.append(dict(device=a,unit=unit,resultAt=result['at'],dbReturnedProfile=result['detail']['dbProfile'],profileGET=matches[-1]))
(E/'ui03-profile-db-http-proof.json').write_text(json.dumps(reads,ensure_ascii=False,indent=2))
for a in 'AB':
 for suffix in ['ui03-01-settings','ui03-02-profile','ui03-03-signup',*[f'ui03-onboarding-{i}' for i in range(5)],*[f'ui03-gauge-{u}' for u in ['Metric','Imperial','US','cm']]]:
  for ext in ['png','xml']:
   p=E/f'{a}-{suffix}.{ext}';assert p.is_file() and p.stat().st_size>100,p
missing=[]
for md in [R/'report.md',R/'case-results.md',R/'SPEC-RTM-proposal.md']:
 for link in re.findall(r'\]\(([^)]+)\)',md.read_text()):
  if link in ['evidence/final-integrity.json','evidence/SHA256SUMS.txt']:continue # written by final audit/manifest step
  if not link.startswith(('http:','https:','#')) and not (md.parent/link).exists():missing.append(str(md)+': '+link)
assert not missing,missing
check=subprocess.run(['git','diff','--exit-code','HEAD','--'],cwd=ROOT,capture_output=True,text=True)
assert check.returncode==0,'Tracked source changed'
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
(E/'final-integrity.json').write_text(json.dumps(dict(at=datetime.now(timezone.utc).isoformat(),commit=commit,trackedDiffEmpty=True,ui03ProfileCases=len(reads),requiredUI03Screenshots=24,markdownLinksExist=True),indent=2))
print('Verified: 8 live profile/DB cases, 24 screenshot/XML pairs, links, clean tracked source')
