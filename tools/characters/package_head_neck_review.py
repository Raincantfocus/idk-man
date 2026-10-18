"""Create a private, portable region review ZIP. Never copies purchased art to git.
python tools/characters/package_head_neck_review.py PRIVATE_REGION OUTPUT.zip
Includes packed Blender authoring/source files and runnable authoring helpers.
"""
import hashlib,json,shutil,subprocess,sys,tempfile,zipfile
from pathlib import Path
repo=Path(__file__).resolve().parents[2]
region=Path(sys.argv[1]).resolve();output=Path(sys.argv[2]).resolve()
assert not region.is_relative_to(repo) and not output.is_relative_to(repo)
output.parent.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='head-neck-package-') as work:
 root=Path(work)/'head-neck-review';root.mkdir()
 manifest=json.loads((region/'manifest.json').read_text())
 # Closed fracture is an exported blend shape; damaged is a shader mask.
 # Open and detached use the identical seam mesh with separate presentation.
 for state,entry in manifest['states'].items():
  canonical='HN_intact.glb' if state in ['intact','damaged','fractured_closed'] else 'HN_fractured_open.glb'
  entry['path']=canonical;entry['sha256']=hashlib.sha256((region/canonical).read_bytes()).hexdigest()
 (root/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 paths={'HN_intact.glb','HN_fractured_open.glb','HN_interiors.glb','project.godot','review.tscn','viewer.gd','head_neck_review.gd','neck_bruise_review.gdshader','validation.json','geometry_validation.json','godot_validation.json'}
 paths.update(p.name for p in region.glob('*contact_sheet.png'))
 for name in paths:shutil.copy(region/name,root/name)
 for folder in ['captures_blender','captures_godot']:
  shutil.copytree(region/folder,root/folder)
 for name in ['author_head_neck.py','inset_neck_ring.py','audit_head_neck_region.py','capture_head_neck_blender.py']:
  target=root/'tools/characters'/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy(repo/'tools/characters'/name,target)
 target=root/'data/characters/head_neck_authoring.json';target.parent.mkdir(parents=True,exist_ok=True);shutil.copy(repo/'data/characters/head_neck_authoring.json',target)
 # Pack texture images so the Blender files do not depend on cloud-only paths.
 helper=Path(work)/'pack_blend.py'
 helper.write_text("import bpy,sys\nbpy.ops.file.pack_all()\nbpy.context.preferences.filepaths.save_version=0\nbpy.ops.wm.save_as_mainfile(filepath=sys.argv[sys.argv.index('--')+1],compress=True)\n")
 sources={
  'authoring/head_neck_authoring.blend':region/'authoring/head_neck_authoring.blend',
  'source/head_standard.blend':region.parent/'soup_head/authoring/head_standard.blend'}
 for relative,source in sources.items():
  destination=root/relative;destination.parent.mkdir(parents=True,exist_ok=True);(destination.parent/'.gdignore').touch()
  subprocess.run(['blender','-b','--disable-autoexec','--python-exit-code','1',str(source),'-P',str(helper),'--',str(destination)],check=True,stdout=subprocess.DEVNULL)
 (root/'README.md').write_text('''# Head/neck region review — NOT production approved

Open project.godot in Godot 4.6, let imports finish, then press F5. Use the buttons
for state, view, pose and torn variant. Open/detached offsets are exploded review
positions, not physics. Interiors stay unloaded in the interactive presentation.

This is an isolated art review, not the playable shooter. No gameplay changes.
Read validation.json, geometry_validation.json and godot_validation.json for
actual failures and unverified checks. Software-rendered frame times are invalid.

Regenerate from the packed fitted source (Blender 4.3+):

    blender -b --disable-autoexec --python-exit-code 1 source/head_standard.blend -P tools/characters/author_head_neck.py -- ../head-neck-generated

Validate the generated geometry:

    blender -b --disable-autoexec --python-exit-code 1 ../head-neck-generated/authoring/head_neck_authoring.blend -P tools/characters/audit_head_neck_region.py -- ../head-neck-generated

Source and authoring .blend files include packed textures. Texture dimensions,
weights and anatomical dimensions remain candidates, not medical measurements.
The only converted supplied head here is Soup, on the shared fitted rig. Other
bodies and regions await the user's region review gate.

LICENSE: supplied soldier art is user-purchased; redistribution terms have not
been verified. Keep this package private. The shared rig derives from MakeHuman
CC0 assets; see LICENSE.MAKEHUMAN-ASSETS.md. Scripts are project code.
''')
 shutil.copy(repo/'assets/characters/licenses/LICENSE.ASSETS.md',root/'LICENSE.MAKEHUMAN-ASSETS.md')
 files=sorted(p for p in root.rglob('*') if p.is_file())
 hashes={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
 (root/'package_hashes.json').write_text(json.dumps(hashes,indent=2)+'\n')
 with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
  for p in sorted(root.rglob('*')):
   if p.is_file():archive.write(p,str(p.relative_to(root.parent)))
 with zipfile.ZipFile(output) as archive:assert archive.testzip() is None
 print(json.dumps({'zip':str(output),'bytes':output.stat().st_size,'hashed_files':len(hashes),'production_ready':False}))
