"""Portable ZIP with content-deduplicated embedded glTF images and real checksums."""
import sys,struct,json,hashlib,shutil,tempfile,zipfile
from pathlib import Path
repo=Path(__file__).resolve().parents[2];source=Path(sys.argv[1]).resolve();output=Path(sys.argv[2]).resolve()
assert not source.is_relative_to(repo) and not output.is_relative_to(repo)
def deduplicate_glb(path,folder):
 data=path.read_bytes();n=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+n]);binary=data[28+n:]
 removed=set()
 for image in doc.get('images',[]):
  if 'bufferView' not in image:continue
  index=image.pop('bufferView');view=doc['bufferViews'][index];payload=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
  ext='.png' if image.get('mimeType')=='image/png' else '.jpg';name=hashlib.sha256(payload).hexdigest()+ext
  tex=folder/'textures'/name;tex.parent.mkdir(exist_ok=True);tex.write_bytes(payload);image['uri']='textures/'+name;removed.add(index)
 if not removed:return
 packed=bytearray();views=[];mapping={}
 for old,view in enumerate(doc['bufferViews']):
  if old in removed:continue
  while len(packed)%4:packed.append(0)
  clone=dict(view);clone['byteOffset']=len(packed);clone['buffer']=0;mapping[old]=len(views);views.append(clone)
  packed.extend(binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']])
 for a in doc.get('accessors',[]):
  if 'bufferView' in a:a['bufferView']=mapping[a['bufferView']]
  if 'sparse' in a:
   for member in ['indices','values']:a['sparse'][member]['bufferView']=mapping[a['sparse'][member]['bufferView']]
 doc['bufferViews']=views
 while len(packed)%4:packed.append(0)
 doc['buffers']=[{'byteLength':len(packed)}]
 text=json.dumps(doc,separators=(',',':')).encode()
 while len(text)%4:text+=b' '
 total=12+8+len(text)+8+len(packed)
 path.write_bytes(struct.pack('<4sII',b'glTF',2,total)+struct.pack('<I4s',len(text),b'JSON')+text+struct.pack('<I4s',len(packed),b'BIN\0')+packed)
with tempfile.TemporaryDirectory(prefix='neck-rework-package-') as tmp:
 root=Path(tmp)/'neck-rework-review';root.mkdir()
 for f in source.iterdir():
  if f.is_file() and f.suffix in ['.glb','.json','.gd','.gdshader','.tscn','.godot'] and f.name!='latest.png':shutil.copy(f,root/f.name)
 for pattern in ['tissue_*.png','pool_*.png']:
  for f in source.glob(pattern):shutil.copy(f,root/f.name)
 for folder in ['scripts','data','captures','captures_blender','sheets','authoring']:
  if (source/folder).exists():shutil.copytree(source/folder,root/folder,ignore=shutil.ignore_patterns('*.import','*.uid','__pycache__'))
 for path in root.glob('*.glb'):deduplicate_glb(path,root)
 (root/'tools/trauma').mkdir(parents=True)
 for f in (repo/'tools/trauma').glob('*'):
  if f.is_file() and f.suffix in ['.py','.gd']:shutil.copy(f,root/'tools/trauma'/f.name)
 (root/'docs').mkdir()
 for name in ['NECK_REWORK_REVIEW.md','TRAUMA_CROSS_SECTIONS.md']:
  if (repo/'docs'/name).exists():shutil.copy(repo/'docs'/name,root/'docs'/name)
 (root/'README.md').write_text('''# Head/neck cap rework review

Open project.godot in Godot 4.6.3, wait for import, press F5. Controls cycle 12
variants, three distances, two light rigs and LODs. Pulse, Drop head and Head pop
exercise isolated cosmetic effects. Jolt is selected for the review project.

This review is not yet an approved live-game replacement. See docs/NECK_REWORK_REVIEW.md
for actual checks, measured counts and remaining visual/integration failures.
Compatibility uses a surface-mesh blood-pool fallback. Forward+ Decal rendering
and GPU frame cost were not validated on this software-rendered host.

Includes native captures, packed authoring .blend and runnable scripts. Purchased
source assets remain subject to their original terms. The user explicitly approved
public GitHub delivery of these review archives.

The authoring .blend contains all generated meshes and packed images. Rebuilding
from the original fitted region also requires the previous head/neck package's
source .blend plus its manifest.json; the generator usage is documented in the
review report. No external cloud-only texture paths are required to inspect/edit
this packed authoring file.
''')
 files=sorted(p for p in root.rglob('*') if p.is_file());hashes={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
 (root/'package_hashes.json').write_text(json.dumps(hashes,indent=2))
 output.parent.mkdir(exist_ok=True,parents=True)
 with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for f in sorted(root.rglob('*')):
   if f.is_file():z.write(f,str(f.relative_to(root.parent)))
 with zipfile.ZipFile(output) as z:assert z.testzip() is None
 print(json.dumps({'path':str(output),'bytes':output.stat().st_size,'hashes':len(hashes)}))
