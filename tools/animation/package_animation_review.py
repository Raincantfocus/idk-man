"""Package native retarget settings alongside the sources: never omit GLB.import."""
from pathlib import Path
import sys,json,shutil,tempfile,zipfile,hashlib
repo=Path(__file__).resolve().parents[2];source=Path(sys.argv[1]).resolve();destination=Path(sys.argv[2]).resolve()
assert not destination.is_relative_to(repo)
with tempfile.TemporaryDirectory(prefix='animation-review-package-') as tmp:
 root=Path(tmp)/'animation-review';root.mkdir()
 for name in ['project.godot','review.tscn','retarget_report.json','animation_test_report.json','capture_report.json','animation_contact_sheet.jpg','run_loop.mp4']:
  shutil.copy(source/name,root/name)
 for folder in ['scripts/animation','tools/animation','data/animation']:
  (root/folder).mkdir(parents=True,exist_ok=True)
  for f in (source/folder).glob('*'):
   if f.is_file() and f.suffix in ['.gd','.py','.tres','.res','.json']:shutil.copy(f,root/folder/f.name)
 for folder in ['motions','models']:
  (root/folder).mkdir()
  for f in (source/folder).glob('*'):
   selected=f.suffix in ['.glb','.json'] or f.name.endswith('.glb.import') or f.name in [f'{kind}_{channel}.png' for kind in ['carrier','fatigues'] for channel in ['albedo','normal','orm']]
   if f.is_file() and selected:shutil.copy(f,root/folder/f.name)
 shutil.copytree(source/'captures',root/'captures',ignore=shutil.ignore_patterns('*.import','*.uid'));(root/'captures/.gdignore').touch()
 for name in ['docs/ANIMATION_INTEGRATION_REVIEW.md','assets/characters/provenance.json','assets/characters/licenses/LICENSE.md','assets/characters/licenses/LICENSE.ASSETS.md']:
  target=root/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy(repo/name,target)
 (root/'README.md').write_text('# Animation integration review\n\nOpen project.godot in Godot 4.6.3, allow import, press F5. Keep the GLB.import files: they contain required humanoid retarget settings.\n\nEight supplied mocap clips plus an explicitly static hold pose. Controls expose run blending, upper-body fire/reload, full clips, pause, Focus, rotation and gear visibility. See docs/ANIMATION_INTEGRATION_REVIEW.md for the failed acceptance items.\n\nThis is an isolated review, not the playable wave shooter. Clothing intersections, weapon/foot contact, missing role clips, over-budget geometry and ragdoll integration remain unresolved. Original supplied-asset license terms apply.\n')
 files=sorted(p for p in root.rglob('*') if p.is_file());hashes={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files};(root/'package_hashes.json').write_text(json.dumps(hashes,indent=2))
 destination.parent.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(destination,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for f in sorted(root.rglob('*')):
   if f.is_file():z.write(f,str(f.relative_to(root.parent)))
 with zipfile.ZipFile(destination) as z:assert z.testzip() is None
 print(json.dumps({'archive':str(destination),'bytes':destination.stat().st_size,'hashed_files':len(hashes)}))
