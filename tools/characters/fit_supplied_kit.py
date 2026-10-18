"""Blender 4.x, private garment fit candidates on the existing humanoid skeleton.
Run with --disable-autoexec SOURCE.blend --python THIS -- PRIVATE_OUT GROUP SHAPE.
Preserves source UV samples and authored skin weights. This is a fitting starting
point, not artist-reviewed retopology or corrective shape generation.
"""
import bpy, json, sys, math, hashlib
from pathlib import Path
from collections import defaultdict
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
repo=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
from bake_supplied_atlas import bake
args=sys.argv[sys.argv.index('--')+1:];out=Path(args[0]).resolve();group=args[1];shape=args[2]
assert not out.is_relative_to(repo), 'Private output required'
cfg=json.loads((repo/'data/characters/supplied_kit_conversion.json').read_text())
cfg=dict(cfg,**cfg['groups'][group])
assert Path(bpy.data.filepath).name==cfg['source']
assert shape in ['standard','lean','broad','stocky','slender']
spec=cfg['groups'][group];out.mkdir(parents=True,exist_ok=True)
bpy.context.view_layer.update()
source_rig=bpy.data.objects[cfg.get('source_rig','MAKAROV RIG')]
rot=Matrix.Rotation(-math.pi/2,4,'Z');unit=cfg['source_meters_per_unit']
def source_point(p): return rot@(p*unit)
source_bones={b.name:(source_point(source_rig.matrix_world@b.head_local),source_point(source_rig.matrix_world@b.tail_local)) for b in source_rig.data.bones}
# Source Rigify segment names mapped to standard humanoid names. The two
# half-segments share a full-limb fit transform to avoid a split at twist joints.
mapping={'DEF-spine':'Hips','DEF-spine.001':'Spine','DEF-spine.002':'Chest','DEF-spine.003':'UpperChest','DEF-spine.004':'Neck','DEF-spine.005':'Neck','DEF-spine.006':'Head'}
fit_group={}
for side,prefix in [('L','Left'),('R','Right')]:
 for old,new in [('shoulder','Shoulder'),('upper_arm','UpperArm'),('forearm','LowerArm'),('hand','Hand'),('thigh','UpperLeg'),('shin','LowerLeg'),('foot','Foot'),('toe','Toes')]:
  key='DEF-'+old+'.'+side;mapping[key]=prefix+new
  if old in ['upper_arm','forearm','thigh','shin']:
   mapping[key+'.001']=prefix+new+'Twist';fit_group[key+'.001']=key
 for old in ['pelvis','breast']:mapping['DEF-'+old+'.'+side]='Hips' if old=='pelvis' else 'UpperChest'
 for finger,label in [('thumb','Thumb'),('f_index','Index'),('f_middle','Middle'),('f_ring','Ring'),('f_pinky','Little')]:
  stages=['Metacarpal','Proximal','Distal'] if finger=='thumb' else ['Proximal','Intermediate','Distal']
  for i,stage in enumerate(stages,1):mapping[f'DEF-{finger}.{i:02}.{side}']=prefix+label+stage
 for i,label in enumerate(['Index','Middle','Ring','Little'],1):mapping[f'DEF-palm.{i:02}.{side}']=prefix+label+'Metacarpal'
if cfg.get('merge_facial_weights_to_head',False):
 for bone in source_rig.data.bones:
  if bone.name.startswith('DEF-') and bone.name not in mapping:
   mapping[bone.name]='Head';fit_group[bone.name]='DEF-spine.006'
# Snapshot original rest mesh and its weights before deleting control rigs.
objects=[];raw={}
for part_id,name in enumerate(spec['objects'],1):
 obj=bpy.data.objects[name];world=obj.matrix_world.copy()
 # Semantic face IDs survive atlas baking and joining; never encode IDs as skin weights.
 attr=obj.data.attributes.get('source_part_id') or obj.data.attributes.new('source_part_id','INT','FACE')
 assert attr.domain=='FACE' and attr.data_type=='INT'
 for value in attr.data:value.value=part_id
 weights=[]
 for v in obj.data.vertices:
  row={obj.vertex_groups[g.group].name:g.weight for g in v.groups if g.weight>1e-6}
  if not row and name in cfg.get('rigid_source_bindings',{}):row={cfg['rigid_source_bindings'][name]:1.0}
  missing=set(row)-mapping.keys()
  assert not missing,(name,missing)
  assert row,(name,'unweighted vertex')
  weights.append(row)
 raw[name]=([source_point(world@v.co) for v in obj.data.vertices],weights)
 obj.modifiers.clear();obj.parent=None;obj.matrix_world=Matrix.Identity(4)
 objects.append(obj)
for obj in list(bpy.data.objects):
 if obj not in objects:bpy.data.objects.remove(obj,do_unlink=True)
with bpy.data.libraries.load(str(repo/'art/characters'/f'{shape}.blend'),link=False) as (src,dst):dst.objects=['HumanoidRig','Body']
rig=dst.objects[0];bpy.context.collection.objects.link(rig)
reference=dst.objects[1]
reference_bvh=BVHTree.FromPolygons([v.co for v in reference.data.vertices],[list(p.vertices) for p in reference.data.polygons])
bpy.data.objects.remove(reference,do_unlink=True)
clearance_report={'adjusted_vertices':0,'unresolved_deep_vertices':0,'max_displacement_m':0.0}
target=rig.data.bones
transforms={}
for old,new in mapping.items():
 if old not in source_bones:continue
 key=fit_group.get(old,old);mapped=mapping[key]
 sh,st=source_bones[key]
 # Fit full limb endpoints; retain segment-specific skin weights separately.
 if key+'.001' in source_bones:st=source_bones[key+'.001'][1]
 th=target[mapped].head_local.copy();tt=target[mapped].tail_local.copy()
 # Torso Rigify bones differ in their construction from the shared rig.
 # Use translation there rather than rotating cloth around a horizontal pelvis.
 if key.startswith(('DEF-spine','DEF-pelvis','DEF-breast')):
  if key.startswith('DEF-pelvis'):th=target['Hips'].head_local.copy();sh=source_bones['DEF-spine'][0]
  if key.startswith('DEF-breast'):th=target['UpperChest'].head_local.copy();sh=source_bones['DEF-spine.003'][0]
  transforms[old]=(sh,th,None,1.0)
 else:
  a=st-sh;b=tt-th
  transforms[old]=(sh,th,a.rotation_difference(b),b.length/a.length)
for obj in objects:
 coords,weights=raw[obj.name]
 obj.vertex_groups.clear()
 for b in target:obj.vertex_groups.new(name=b.name)
 for i,(point,row) in enumerate(zip(coords,weights)):
  fitted=Vector();new_weights=defaultdict(float);total=sum(row.values())
  for old,w in row.items():
   sh,th,q,ratio=transforms[old]
   # Longitudinal rest fitting; perpendicular garment volume is preserved.
   offset=point-sh
   if q is not None:
    axis=(source_bones[fit_group.get(old,old)][1]-sh).normalized()
    offset=q@(offset+axis*offset.dot(axis)*(ratio-1))
   fitted+=(th+offset)*(w/total);new_weights[mapping[old]]+=w/total
  near,normal,face,distance=reference_bvh.find_nearest(fitted)
  signed=(fitted-near).dot(normal)
  correction=cfg['fit_clearance_m']-signed
  if cfg.get('apply_clearance',True) and correction>0:
   if correction<=cfg['max_clearance_correction_m']:
    fitted+=normal*correction
    clearance_report['adjusted_vertices']+=1
    clearance_report['max_displacement_m']=max(clearance_report['max_displacement_m'],correction)
   else:clearance_report['unresolved_deep_vertices']+=1
  obj.data.vertices[i].co=fitted
  kept=sorted(new_weights.items(),key=lambda item:-item[1])[:4];normal=sum(w for _,w in kept)
  for name,w in kept:obj.vertex_groups[name].add([i],w/normal,'REPLACE')
 obj.data.update()
bpy.ops.object.select_all(action='DESELECT')
for obj in objects:obj.select_set(True)
bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();obj=bpy.context.object;obj.name=group
obj['source_parts_json']=json.dumps({str(i):name for i,name in enumerate(spec['objects'],1)})
source_tris=sum(len(p.vertices)-2 for p in obj.data.polygons)
bake(obj,out,dict(cfg,force_metallic_zero=spec.get('force_metallic_zero',False)),group)
base=obj.data.copy();lods=[]
for index,target_tris in enumerate(spec['lod_triangle_targets']):
 obj.data=base.copy();obj.modifiers.clear()
 bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
 triangles=sum(len(p.vertices)-2 for p in obj.data.polygons)
 if target_tris<triangles:
  dec=obj.modifiers.new('CandidateReduction','DECIMATE');dec.ratio=target_tris/triangles;dec.use_collapse_triangulate=True
  bpy.ops.object.modifier_apply(modifier=dec.name)
 bpy.ops.object.vertex_group_limit_total(limit=4);bpy.ops.object.vertex_group_normalize_all(lock_active=False)
 skin=obj.modifiers.new('HumanoidSkin','ARMATURE');skin.object=rig;obj.parent=rig
 rig.select_set(True)
 path=out/f'{group}_{shape}_lod{index}.glb'
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_influences=False,export_morph=False,export_yup=True,export_cameras=False,export_lights=False,export_tangents=True)
 lods.append({'path':path.name,'triangles':sum(len(p.vertices)-2 for p in obj.data.polygons),'materials':1,'bones':len(target),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
obj.data=base.copy()
for text in list(bpy.data.texts):bpy.data.texts.remove(text)
bpy.context.scene.world=bpy.data.worlds.new('ReviewWorld')
if bpy.context.scene.node_tree:bpy.context.scene.node_tree.nodes.clear()
for collection in [bpy.data.images,bpy.data.materials,bpy.data.meshes,bpy.data.armatures,bpy.data.node_groups,bpy.data.actions]:
 for block in collection:block.use_fake_user=False
bpy.data.orphans_purge(do_recursive=True)
authoring=out/'authoring';authoring.mkdir(exist_ok=True);(authoring/'.gdignore').touch()
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(authoring/f'{group}_{shape}.blend'))
report={'group':group,'shape':shape,'source_objects':spec['objects'],'semantic_parts':{str(i):name for i,name in enumerate(spec['objects'],1)},'source_triangles':source_tris,'clearance':clearance_report,'lods':lods,'production_ready':False,'blockers':['Joint topology still triangulated','Correctives absent','Wound boundaries absent','Fitting and deformation not approved','Combined soldier budgets unverified']}
(out/f'{group}_{shape}.json').write_text(json.dumps(report,indent=2));print('KIT_COMPLETE',json.dumps(report),flush=True)
