"""Package the body-zone review, source body, license records and hash manifest."""
from pathlib import Path
import json,hashlib,shutil,sys,tempfile,zipfile
repo=Path(__file__).resolve().parents[2];source=Path(sys.argv[1]).resolve();destination=Path(sys.argv[2]).resolve()
assert not destination.is_relative_to(repo)
with tempfile.TemporaryDirectory(prefix='body-review-') as tmp:
 root=Path(tmp)/'body-zone-review';root.mkdir()
 for f in source.iterdir():
  if f.is_file() and f.suffix in ['.glb','.json','.png','.tscn','.godot']:shutil.copy(f,root/f.name)
 for folder in ['scripts','data','tools','captures','sheets','authoring']:
  if (source/folder).exists():shutil.copytree(source/folder,root/folder,ignore=shutil.ignore_patterns('.godot','__pycache__','*.import','*.uid','*.blend1'))
 for name in ['assets/characters/generated/standard_lod0.glb','assets/characters/provenance.json','assets/characters/licenses/LICENSE.md','assets/characters/licenses/LICENSE.ASSETS.md','docs/BODY_ZONE_REVIEW.md','docs/TRAUMA_CROSS_SECTIONS.md']:
  target=root/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy(repo/name,target)
 (root/'README.md').write_text('# Body-zone review\n\nOpen project.godot in Godot 4.6.3 and press F5.\n\n45 rest-pose caps, 22 zone definitions and cavity logic. This is an isolated art review, not the playable shooter. See docs/BODY_ZONE_REVIEW.md for failed acceptance items.\n\nThe packed Blender file, CC0-derived source body, atlas, authoring scripts and provenance are included. No animation or full-body cloth joins are claimed.\n')
 files=sorted(p for p in root.rglob('*') if p.is_file());hashes={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files};(root/'package_hashes.json').write_text(json.dumps(hashes,indent=2))
 destination.parent.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(destination,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for f in sorted(root.rglob('*')):
   if f.is_file():z.write(f,str(f.relative_to(root.parent)))
 with zipfile.ZipFile(destination) as z:assert z.testzip() is None
 print(json.dumps({'bytes':destination.stat().st_size,'hashed_files':len(hashes),'archive':str(destination)}))
