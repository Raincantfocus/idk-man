"""Extract authored semantic parts without repacking or duplicating atlas textures.
Blender 4.x: -b --disable-autoexec --python-exit-code 1 PRIVATE.blend
  --python THIS -- PRIVATE_OUTPUT GROUP [KIT_RECIPES_JSON]
Exports individual authoring parts and a single-surface complete kit. These are
unreduced review assets, not accepted role kits. Godot supplies the shared material.
"""
import bpy
import bmesh
import hashlib
import json
import sys
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
args = sys.argv[sys.argv.index('--') + 1:]
out, group = Path(args[0]).resolve(), args[1]
assert not out.is_relative_to(repo), 'Purchased derivative art must remain private'
source = bpy.data.objects[group]
parts = json.loads(source['source_parts_json'])
attr = source.data.attributes['source_part_id']
assert attr.domain == 'FACE' and attr.data_type == 'INT'
assert set(v.value for v in attr.data) == {int(i) for i in parts}
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
assert 65 <= len(rig.data.bones) <= 75
assert len(source.data.materials) == 1
assert len(source.data.uv_layers) == 1
out.mkdir(parents=True, exist_ok=True)
source_triangle_count = sum(len(p.vertices) - 2 for p in source.data.polygons)
records = []
selections = [(name, {int(key)}) for key, name in parts.items()]
selections.append(('complete_kit', {int(key) for key in parts}))
if len(args) > 2:
    recipes = json.loads(Path(args[2]).read_text())
    inverse = {name: int(key) for key, name in parts.items()}
    used_names = {name for name, _ in selections}
    for name, members in recipes.items():
        assert name and all(c.isascii() and (c.isalnum() or c == '_') for c in name), 'Unsafe kit name'
        assert name not in used_names, 'Duplicate kit name'
        assert members and len(set(members)) == len(members), 'Empty or duplicated kit members'
        assert set(members) <= inverse.keys(), 'Unknown source part'
        selections.append((name, {inverse[part] for part in members}))
        used_names.add(name)
for name, selected in selections:
    obj = source.copy()
    obj.data = source.data.copy()
    obj.name = name
    bpy.context.collection.objects.link(obj)
    obj.modifiers.clear()
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    ids = bm.faces.layers.int['source_part_id']
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f[ids] not in selected], context='FACES')
    # Remove orphan vertices without touching seam splits/UVs or skin weights.
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    triangles = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    assert triangles > 0
    assert all(len(v.groups) <= 4 and abs(sum(g.weight for g in v.groups) - 1) < 1e-4 for v in obj.data.vertices)
    skin = obj.modifiers.new('HumanoidSkin', 'ARMATURE')
    skin.object = rig
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = obj
    path = out / f'{name}.glb'
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True,
        export_animations=False, export_skins=True, export_all_influences=False,
        export_morph=False, export_yup=True, export_cameras=False, export_lights=False,
        export_tangents=True, export_materials='NONE')
    records.append({'part': name, 'source_ids': sorted(selected), 'path': path.name,
        'triangles': triangles, 'vertices': len(obj.data.vertices), 'bones': len(rig.data.bones),
        'expected_visible_surfaces': 1, 'embedded_materials': 0,
        'shared_atlas_group': group, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    bpy.data.objects.remove(obj, do_unlink=True)
assert sum(r['triangles'] for r in records[:len(parts)]) == source_triangle_count
assert records[len(parts)]['triangles'] == source_triangle_count
report = {'schema': 1, 'production_ready': False, 'source_triangles': source_triangle_count,
    'part_count': len(parts), 'parts': records[:len(parts)+1], 'kits': records[len(parts)+1:],
    'budget_note': 'Individual parts share one material but require one surface each. Use a preassembled single-surface kit for runtime; these unreduced exports are not final LODs.',
    'blockers': ['Role kits incomplete', 'Fit and deformation unapproved', 'No corrective shapes or wound seams', 'Unreduced geometry; final LODs required']}
(out / 'modular_parts_report.json').write_text(json.dumps(report, indent=2) + '\n')
print('MODULAR_EXPORT_COMPLETE', len(parts), source_triangle_count, flush=True)
