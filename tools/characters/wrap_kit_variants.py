"""Blender: wrap a baked standard garment to the five authored MakeHuman shapes.
UVs/textures remain unchanged. Shape deltas come from the authored CC0 targets,
not uniform scaling. Output is a candidate pending artist fit/deformation review.
blender -b --disable-autoexec --python-exit-code 1 PRIVATE_GROUP_STANDARD.blend --python THIS -- PRIVATE_OUT GROUP
"""
import bpy,json,sys,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.geometry import barycentric_transform
repo=Path(__file__).resolve().parents[2]
args=sys.argv[sys.argv.index('--')+1:];out=Path(args[0]).resolve();group=args[1]
assert not out.is_relative_to(repo)
cfg=json.loads((repo/'data/characters/supplied_kit_conversion.json').read_text())
spec=cfg['groups'][group]
obj=bpy.data.objects[group];rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
base=obj.data.copy();base_coords=[v.co.copy() for v in base.vertices]
with bpy.data.libraries.load(str(repo/'art/characters/standard.blend'),link=False) as (src,dst):dst.objects=['Body']
reference=dst.objects[0];reference.data.calc_loop_triangles()
points=[v.co.copy() for v in reference.data.vertices]
triangles=[list(t.vertices) for t in reference.data.loop_triangles]
bvh=BVHTree.FromPolygons(points,triangles,all_triangles=True)
wrap=[]
for point in base_coords:
 near,normal,index,distance=bvh.find_nearest(point)
 wrap.append((near.copy(),triangles[index]))
bpy.data.objects.remove(reference,do_unlink=True)
results=[]
for shape in ['standard','lean','broad','stocky','slender']:
 with bpy.data.libraries.load(str(repo/'art/characters'/f'{shape}.blend'),link=False) as (src,dst):dst.objects=['Body','HumanoidRig']
 body,target_rig=dst.objects
 assert len(body.data.vertices)==len(points),'Morph topology correspondence is required'
 deltas=[v.co-p for v,p in zip(body.data.vertices,points)]
 rig.data=target_rig.data.copy()
 fitted=[]
 for point,(near,ids) in zip(base_coords,wrap):
  fitted.append(point+barycentric_transform(near,*(points[i] for i in ids),*(deltas[i] for i in ids)))
 bpy.data.objects.remove(body,do_unlink=True);bpy.data.objects.remove(target_rig,do_unlink=True)
 lods=[]
 for lod,budget in enumerate(spec['lod_triangle_targets']):
  obj.data=base.copy();obj.modifiers.clear()
  for v,point in zip(obj.data.vertices,fitted):v.co=point
  obj.data.update()
  bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
  count=sum(len(p.vertices)-2 for p in obj.data.polygons)
  if budget<count:
   mod=obj.modifiers.new('CandidateReduction','DECIMATE');mod.ratio=budget/count;mod.use_collapse_triangulate=True
   bpy.ops.object.modifier_apply(modifier=mod.name)
  bpy.ops.object.vertex_group_limit_total(limit=4);bpy.ops.object.vertex_group_normalize_all(lock_active=False)
  skin=obj.modifiers.new('HumanoidSkin','ARMATURE');skin.object=rig;rig.select_set(True)
  path=out/f'{group}_{shape}_lod{lod}.glb'
  bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_influences=False,export_morph=False,export_yup=True,export_cameras=False,export_lights=False,export_tangents=True,export_materials='NONE')
  lods.append({'path':path.name,'triangles':sum(len(p.vertices)-2 for p in obj.data.polygons),'bones':len(rig.data.bones),'embedded_materials':0,'shared_atlas_group':group,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
 results.append({'shape':shape,'lods':lods,'production_ready':False})
(out/f'{group}_shape_variants.json').write_text(json.dumps({'fit_method':'Barycentric transfer of authored MakeHuman shape deltas; original baked UV atlas retained','variants':results},indent=2))
print('WRAP_COMPLETE',group,len(results),flush=True)
