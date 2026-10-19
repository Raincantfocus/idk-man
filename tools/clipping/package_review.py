"""Bundle the isolated review, exact retarget sidecars and reproducible audit inputs."""
import json,sys,zipfile,hashlib
from pathlib import Path
repo=Path(__file__).resolve().parents[2];work=Path(sys.argv[1]);dest=Path(sys.argv[2]);project=work/'project';files={}
for p in project.rglob('*'):
 if not p.is_file():continue
 rel=p.relative_to(project)
 if any(x in ['.godot','__pycache__','captures'] for x in rel.parts):continue
 if p.suffix in ['.uid','.pyc'] or (p.suffix=='.import' and not p.name.endswith('.glb.import')):continue
 if p.name in ['run_loop.mp4','animation_contact_sheet.jpg']:continue
 files[str(rel)]=p
for folder in ['tools/clipping','scripts/clipping','data/clipping']:
 for p in (repo/folder).rglob('*'):
  if p.is_file() and p.suffix not in ['.uid','.pyc']:files[str(p.relative_to(repo))]=p
for stage in ['baseline','stage_a_bind','stage_b','stage_c','stage_d','stage_e','stage_e_raw','stage_f','stage_f_raw']:
 for p in (work/stage).glob('*'):
  if p.suffix in ['.json','.csv','.png'] and p.name!='patch.json':files['audit/'+stage+'/'+p.name]=p
for name in ['baseline_input.json','bone_parents.json']:files['audit/'+name]=work/name
for p in (work/'captures').glob('*'):
 if p.is_file():files['audit/captures/'+p.name]=p
for p in (work/'lods').glob('*'):
 if p.is_file():files['models/covered_lods/'+p.name]=p
for name in ['assets/characters/provenance.json','assets/characters/licenses/LICENSE.md','assets/characters/licenses/LICENSE.ASSETS.md']:files[name]=repo/name
files['docs/BODY_GEAR_CLIPPING_REVIEW.md']=repo/'docs/BODY_GEAR_CLIPPING_REVIEW.md'
files['README.md']=work/'README.md'
files['audit/body_caps_manifest.json']=Path('/workspace/private-soldier-intake/converted/body_caps/manifest.json')
for lod in [1,2,3]:files[f'models/unmasked_lods/standard_lod{lod}.glb']=repo/f'assets/characters/generated/standard_lod{lod}.glb'
files['audit/.gdignore']=work/'.gdignore'
hashes={k:hashlib.sha256(v.read_bytes()).hexdigest() for k,v in files.items()}
dest.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for key,p in sorted(files.items()):z.write(p,'clipping-review/'+key)
 z.writestr('clipping-review/package_hashes.json',json.dumps(hashes,indent=2))
with zipfile.ZipFile(dest) as z:assert z.testzip() is None
print(json.dumps({'archive':str(dest),'bytes':dest.stat().st_size,'hashed_files':len(hashes)}))
