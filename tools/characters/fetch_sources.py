"""Fetch pinned CC0 data only; never execute upstream MakeHuman code."""
import hashlib, json, subprocess, urllib.request
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
REV = 'a8bc2d54ff0ac92e78ff71431b1023eda42bf482'
BASE = f'https://raw.githubusercontent.com/makehumancommunity/makehuman/{REV}/'
FILES = [
 'LICENSE.md','LICENSE.ASSETS.md',
 'makehuman/data/3dobjs/base.obj',
 'makehuman/data/rigs/default.mhskel',
 'makehuman/data/rigs/default_weights.mhw',
 'makehuman/data/targets/macrodetails/caucasian-male-young.target',
 'makehuman/data/targets/macrodetails/universal-male-young-averagemuscle-averageweight.target',
 'makehuman/data/targets/macrodetails/universal-male-young-averagemuscle-maxweight.target',
 'makehuman/data/targets/measure/measure-shoulder-dist-incr.target',
 'makehuman/data/targets/measure/measure-shoulder-dist-decr.target',
 'makehuman/data/targets/hip/hip-scale-horiz-incr.target',
 'makehuman/data/targets/hip/hip-scale-horiz-decr.target',
]
manifest = {'schema':1,'upstream_revision':REV,'assets':[], 'production_ready':False,
 'missing':['licensed tactical garments and gear','authored skin and garment PBR atlases','joint corrective shapes','authored wound boundary loops and fitted LODs']}
for source in FILES:
 dest = ROOT/'assets/characters'/('licenses' if source.startswith('LICENSE') else 'source')/Path(source).name
 dest.parent.mkdir(parents=True,exist_ok=True)
 try:
  data=subprocess.check_output(['git','-C','/tmp/zero-line-makehuman','show',REV+':'+source],stderr=subprocess.DEVNULL)
 except (subprocess.CalledProcessError,FileNotFoundError):
  data=urllib.request.urlopen(BASE+source,timeout=60).read()
 dest.write_bytes(data)
 manifest['assets'].append({'path':str(dest.relative_to(ROOT)), 'source':BASE+source,
  'license':'CC0-1.0' if not source.startswith('LICENSE') else 'upstream license documentation',
  'authors':'MakeHuman contributors; copyright notices retained in source data',
  'sha256':hashlib.sha256(data).hexdigest(),'modifications':'None; unmodified source data'})
existing=ROOT/'assets/characters/provenance.json'
if existing.exists():
 previous=json.loads(existing.read_text())
 manifest['assets'] += [a for a in previous.get('assets',[]) if a.get('generated',False)]
 if 'external_supplied_assets' in previous: manifest['external_supplied_assets']=previous['external_supplied_assets']
(ROOT/'assets/characters/provenance.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Pinned CC0 source files:',len(FILES))
