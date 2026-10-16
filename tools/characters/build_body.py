"""Blender 4.x: derive skinned test bodies from pinned CC0 MakeHuman data.
No character primitives or procedural body animation. Body-only LODs are
pipeline candidates, not accepted soldier assets. Run from tools/characters/build.sh.
"""
import bpy, json, math, hashlib, struct
from pathlib import Path
from collections import defaultdict
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'assets/characters/source'
OUT=ROOT/'assets/characters/generated'
OUT.mkdir(parents=True,exist_ok=True)
AUTHORING=ROOT/'art/characters'
AUTHORING.mkdir(parents=True,exist_ok=True)
(AUTHORING/'.gdignore').touch()
bpy.context.preferences.filepaths.save_version=0
CFG=json.loads((ROOT/'data/characters/pipeline.json').read_text())
RIG=json.loads((SRC/'default.mhskel').read_text())
WEIGHTS=json.loads((SRC/'default_weights.mhw').read_text())['weights']
vertices=[];uvs=[];faces=[];face_uvs=[];group=''
for line in (SRC/'base.obj').read_text().splitlines():
 fields=line.split()
 if not fields:continue
 if fields[0]=='v':vertices.append(Vector(map(float,fields[1:4])))
 elif fields[0]=='vt':uvs.append(tuple(map(float,fields[1:3])))
 elif fields[0]=='g':group=fields[1]
 elif fields[0]=='f' and group=='body':
  corners=[v.split('/') for v in fields[1:]]
  faces.append([int(v[0])-1 for v in corners]);face_uvs.append([int(v[1])-1 for v in corners])
assert all(len(f)==4 for f in faces),'Authored body source must be quad-only'
used=sorted(set(i for f in faces for i in f));remap={old:new for new,old in enumerate(used)}

def target(name):
 result={}
 for line in (SRC/name).read_text().splitlines():
  p=line.split()
  if len(p)==4 and p[0].isdigit():result[int(p[0])]=Vector(map(float,p[1:]))
 return result

def apply(vs,deltas,strength):
 for i,d in deltas.items():vs[i]+=d*strength

# Retain authored limb segmentation/twist weights, merge surplus face/toe bones
# into their nearest retained ancestor, and use standard humanoid names.
BMAP={'root':'Hips','spine04':'Spine','spine02':'Chest','spine01':'UpperChest',
 'neck01':'Neck','head':'Head','jaw':'Jaw','eye.L':'LeftEye','eye.R':'RightEye'}
for side,prefix in [('L','Left'),('R','Right')]:
 for old,new in [('clavicle','Shoulder'),('upperarm01','UpperArm'),('upperarm02','UpperArmTwist'),
  ('lowerarm01','LowerArm'),('lowerarm02','LowerArmTwist'),('wrist','Hand'),
  ('upperleg01','UpperLeg'),('upperleg02','UpperLegTwist'),('lowerleg01','LowerLeg'),
  ('lowerleg02','LowerLegTwist'),('foot','Foot'),('toe1-1','Toes')]:BMAP[old+'.'+side]=prefix+new
 for finger in range(1,6):
  label=['Thumb','Index','Middle','Ring','Little'][finger-1]
  stages=['Metacarpal','Proximal','Distal'] if finger==1 else ['Proximal','Intermediate','Distal']
  for segment in range(1,4):BMAP[f'finger{finger}-{segment}.{side}']=prefix+label+stages[segment-1]
 for i,label in enumerate(['Index','Middle','Ring','Little'],1):BMAP[f'metacarpal{i}.{side}']=prefix+label+'Metacarpal'
assert len(BMAP)+1==72

def retained(old):
 while old and old not in BMAP:old=RIG['bones'][old]['parent']
 return BMAP.get(old,'Hips')

merged=defaultdict(lambda:defaultdict(float))
for name,entries in WEIGHTS.items():
 for index,weight in entries:
  if index in remap:merged[remap[index]][retained(name)]+=weight
for index in range(len(used)):
 entries=sorted(merged[index].items(),key=lambda x:-x[1])[:CFG['max_skin_influences']]
 total=sum(w for _,w in entries)
 merged[index]={n:w/total for n,w in entries} if total else {'Hips':1.0}

manifest={'source_revision':json.loads((ROOT/'assets/characters/provenance.json').read_text())['upstream_revision'],
 'production_ready':False,'body_only':True,'bones':72,'source_quads':len(faces),'source_deformation_triangles':0,
 'missing':['tactical garments/gear','UV-specific PBR textures','joint corrective shapes','wound boundary seams'],
 'lod_method':'Blender collapse candidates; require artist-retopologized deformation loops and seam review',
 'variants':{}}
for shape in CFG['body_shapes']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 coords=[v.copy() for v in vertices]
 apply(coords,target('caucasian-male-young.target'),1)
 apply(coords,target('universal-male-young-averagemuscle-averageweight.target'),1-shape['soft_tissue'])
 apply(coords,target('universal-male-young-averagemuscle-maxweight.target'),shape['soft_tissue'])
 for field,stem in [('shoulders','measure-shoulder-dist'),('pelvis','hip-scale-horiz')]:
  value=shape[field];apply(coords,target(stem+('-incr.target' if value>=0 else '-decr.target')),abs(value))
 floor=min(coords[i].y for i in used);height=max(coords[i].y for i in used)-floor
 scale=CFG['height_m']/height
 def converted(v):return Vector((v.x*scale,-v.z*scale,(v.y-floor)*scale))
 def joint(key):
  ids=RIG['joints'][key]
  return converted(sum((coords[i] for i in ids),Vector())/len(ids))
 arm=bpy.data.armatures.new('Humanoid72');rig=bpy.data.objects.new('HumanoidRig',arm)
 bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True)
 bpy.ops.object.mode_set(mode='EDIT')
 root=arm.edit_bones.new('Root');root.head=(0,0,0);root.tail=(0,0,.1)
 for old,new in BMAP.items():
  data=RIG['bones'][old];b=arm.edit_bones.new(new);b.head=joint(data['head']);b.tail=joint(data['tail'])
  if (b.tail-b.head).length<.001:b.tail=b.head+Vector((0,0,.02))
 # Match primary limb direction to the complete limb, not the short twist section.
 for side in ['Left','Right']:
  for name,tail in [('UpperArm','LowerArm'),('LowerArm','Hand'),('UpperLeg','LowerLeg'),('LowerLeg','Foot')]:
   arm.edit_bones[side+name].tail=arm.edit_bones[side+tail].head
 for old,new in BMAP.items():
  parent=RIG['bones'][old]['parent'];parent_name=retained(parent) if parent else 'Root'
  arm.edit_bones[new].parent=arm.edit_bones[parent_name]
 bpy.ops.object.mode_set(mode='OBJECT')
 mesh=bpy.data.meshes.new('AuthoredBody');mesh.from_pydata([converted(coords[i]) for i in used],[],[[remap[i] for i in f] for f in faces]);mesh.update()
 obj=bpy.data.objects.new('Body',mesh);bpy.context.collection.objects.link(obj)
 uv=mesh.uv_layers.new(name='UVMap')
 for poly,indices in zip(mesh.polygons,face_uvs):
  for loop,uv_index in zip(poly.loop_indices,indices):uv.data[loop].uv=uvs[uv_index]
  poly.use_smooth=True
 mat=bpy.data.materials.new('Body_Review_Clay');mat.use_nodes=True
 shader=mat.node_tree.nodes.get('Principled BSDF');shader.inputs['Base Color'].default_value=(.32,.36,.40,1);shader.inputs['Roughness'].default_value=.65;shader.inputs['Metallic'].default_value=0
 mesh.materials.append(mat)
 for name in ['Root',*BMAP.values()]:obj.vertex_groups.new(name=name)
 for index,weights in merged.items():
  for name,weight in weights.items():obj.vertex_groups[name].add([index],weight,'REPLACE')
 obj.parent=rig
 # Preserve original quad cage and source weights in an editable Blender file.
 skin=obj.modifiers.new('HumanoidSkin','ARMATURE');skin.object=rig
 bpy.ops.wm.save_as_mainfile(filepath=str(AUTHORING/(shape['id']+'.blend')))
 shape_entry={'shape':shape,'height_m':CFG['height_m'],'lods':[]}
 for lod,target_tris in enumerate(CFG['body_lod_targets']):
  candidate=obj.copy();candidate.data=obj.data.copy();bpy.context.collection.objects.link(candidate)
  candidate.name='Body_LOD'+str(lod)
  bpy.ops.object.select_all(action='DESELECT');candidate.select_set(True);bpy.context.view_layer.objects.active=candidate
  # Remove skin temporarily so geometric reduction occurs in rest space.
  candidate.modifiers.clear()
  if lod>0:
   dec=candidate.modifiers.new('CandidateReduction','DECIMATE');dec.ratio=min(1,target_tris/(len(faces)*2));dec.use_collapse_triangulate=True
   bpy.ops.object.modifier_apply(modifier=dec.name)
  skin=candidate.modifiers.new('HumanoidSkin','ARMATURE');skin.object=rig
  # Limit and normalize the reducer's interpolated weights.
  bpy.ops.object.vertex_group_limit_total(limit=4)
  bpy.ops.object.vertex_group_normalize_all(lock_active=False)
  rig.select_set(True)
  path=OUT/(shape['id']+'_lod'+str(lod)+'.glb')
  bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
   export_animations=False,export_skins=True,export_all_influences=False,export_morph=False,
   export_yup=True,export_cameras=False,export_lights=False)
  raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+length])
  tris=sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives'])
  shape_entry['lods'].append({'path':str(path.relative_to(ROOT)),'triangles':tris,'sha256':hashlib.sha256(raw).hexdigest()})
  bpy.data.objects.remove(candidate,do_unlink=True)
 manifest['variants'][shape['id']]=shape_entry
(OUT/'measurements.json').write_text(json.dumps(manifest,indent=2)+'\n')
(ROOT/'data/characters/bone_names.json').write_text(json.dumps(['Root',*BMAP.values()],indent=2)+'\n')
provenance_path=ROOT/'assets/characters/provenance.json'
provenance=json.loads(provenance_path.read_text())
provenance['assets']=[a for a in provenance['assets'] if not a.get('generated',False)]
for path in [*sorted(OUT.glob('*.glb')),*sorted(AUTHORING.glob('*.blend'))]:
 provenance['assets'].append({'path':str(path.relative_to(ROOT)),'license':'CC0-1.0',
  'source':'MakeHuman base mesh, morph targets, rig and weights at '+manifest['source_revision'],
  'generated':True,'generator':'tools/characters/build_body.py',
  'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
  'modifications':'Authored target fitting; 1.80 m normalization; 72-bone subset; merged/normalized top-four weights; candidate LOD reduction; original UVs retained. No production textures or animation.'})
provenance_path.write_text(json.dumps(provenance,indent=2)+'\n')
print('BODY PIPELINE COMPLETE: five shape presets, 72 bones, four LOD candidates; gear/art gates remain open.')
