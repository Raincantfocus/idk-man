"""Package the private F5 inspector, excluding originals, Blender files and caches.
Usage: python tools/characters/package_supplied_review.py PRIVATE_PROJECT OUTPUT.zip
The archive is for the supplying asset owner; it is not a production game build.
"""
import sys,json,hashlib,zipfile,re
from pathlib import Path
repo=Path(__file__).resolve().parents[2]
root=Path(sys.argv[1]).resolve();output=Path(sys.argv[2]).resolve()
assert not root.is_relative_to(repo) and not output.is_relative_to(repo)
files=[root/name for name in ['project.godot','humanoid_bone_map.tres','review.tscn','viewer.gd','candidate_report.json','kit_godot_metrics.json','kit_front.png','candidate_shapes_color.png','candidate_shapes_grayscale.png','candidate_gameplay_20m_color.png','candidate_gameplay_20m_grayscale.png']]
files+=list((root/'scripts/characters').glob('*.gd'))+list((root/'scripts/characters').glob('*.gdshader'))
files+=list((root/'candidates').glob('*.tres'))+list((root/'shared_materials').glob('*.tres'))
for group in ['head','fatigues','carrier']:
 for channel in ['albedo','normal','orm']:files.append(root/f'{group}_{channel}.png')
 for shape in ['standard','lean','broad','stocky','slender']:
  for lod in range(4):files.append(root/f'{group}_{shape}_lod{lod}.glb')
for path in list(files):
 if Path(str(path)+'.import').is_file():files.append(Path(str(path)+'.import'))
 if Path(str(path)+'.uid').is_file():files.append(Path(str(path)+'.uid'))
assert all(p.is_file() for p in files)
selected={p.relative_to(root).as_posix() for p in files}
for path in files:
 if path.suffix in ['.tres','.tscn','.gd','.gdshader','.godot']:
  for dependency in re.findall(r'res://([^"\\]+)',path.read_text()):
   if '%' not in dependency and not dependency.endswith('/'):
    assert dependency in selected, (path.name,'missing packaged dependency',dependency)
manifest={'production_ready':False,'purpose':'Private art inspector for the supplying asset owner; not a game update','source_assets':['User-supplied Makarov (shaded soldier)','User-supplied Soup_masked','CC0 MakeHuman rig and authored shape targets'],'license_note':'User reports purchase of supplied soldier assets; redistribution terms not verified. MakeHuman CC0 license included.','files':[]}
output.parent.mkdir(parents=True,exist_ok=True)
prefix='zero-line-phase1-art-review/'
with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
 for path in sorted(set(files)):
  name=path.relative_to(root).as_posix()
  archive.write(path,prefix+name)
  manifest['files'].append({'path':name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
 archive.writestr(prefix+'MANIFEST.json',json.dumps(manifest,indent=2))
 archive.write(repo/'assets/characters/licenses/LICENSE.ASSETS.md',prefix+'licenses/MakeHuman-CC0.md')
 archive.writestr(prefix+'README.md','''# ZERO-LINE Phase 1 art review

This is a standalone inspector, not a playable game update. It contains one
unapproved tactical outfit in five body-shape fits, with four candidate LODs.

1. Extract the entire folder.
2. Open project.godot in Godot 4.6 and wait for imports to finish.
3. Press F5. Use Next shape, Front / side and Close / gameplay 20 m.

Command line: first run `godot --headless --editor --path . --import`, then
`godot --path .` from this folder. Blender is not needed to inspect the assets.

Phase 1 remains incomplete: role kits, individual appearance options, a final
single atlas, deformation topology/correctives and wound seams need authored
artwork and acceptance. No animations or gore were added. Software-rendered
captures cannot establish the hardware frame-time target.

The 12-degree shape-sheet images are zoomed fitting comparisons. Images named
candidate_gameplay_20m use 86-degree gameplay FOV and LOD1. Neither is the
required twenty-look, five-role motion acceptance sheet.
''')
with zipfile.ZipFile(output) as archive:assert archive.testzip() is None
print(json.dumps({'archive':str(output),'bytes':output.stat().st_size,'verified_entries':len(manifest['files'])}))
