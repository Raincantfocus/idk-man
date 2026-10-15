"""Original armored humanoid game art. Blender 4.3.2, meters, Godot -Z forward."""
import bpy, math, json, struct, hashlib
from mathutils import Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/operators'
ROOT.mkdir(parents=True,exist_ok=True)
def v(p): return Vector((p[0],-p[2],p[1]))
def mat(name,color,metal=0,rough=.7):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 return m
ARMOR=mat('Armor',(.19,.22,.20),.6,.5)
CLOTH=mat('Cloth',(.06,.075,.065))
DARK=mat('Rubber',(.025,.03,.028),0,.85)
STEEL=mat('Metal',(.11,.13,.14),.8,.36)
ACCENT=mat('Accent',(.46,.33,.10),.3,.6)
VISOR=mat('Visor',(.5,.13,.04),.4,.25)
SKIN=mat('Skin',(.52,.30,.19),0,.86)
HAIR=mat('Hair',(.045,.028,.018),0,.95)
EYE=mat('Eye',(.65,.62,.54),0,.4)
LIP=mat('Lip',(.24,.095,.065),0,.9)
parts=[]
def finish(o,bone,material):
 o.data.materials.append(material);o['bone']=bone;parts.append(o);return o
def box(p,size,bone,material=ARMOR,bevel=.015):
 bpy.ops.mesh.primitive_cube_add(size=1,location=v(p));o=bpy.context.object;o.scale=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  m=o.modifiers.new('Edge bevel','BEVEL');m.width=bevel;m.segments=2;bpy.ops.object.modifier_apply(modifier=m.name)
  m=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=m.name)
 return finish(o,bone,material)
def oval(p,size,bone,material=CLOTH):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=1,location=v(p));o=bpy.context.object;o.scale=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for f in o.data.polygons:f.use_smooth=True
 return finish(o,bone,material)
def rod(a,b,r,bone,material=CLOTH,r2=None):
 a,b=v(a),v(b);d=b-a
 bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(a+b)/2);o=bpy.context.object;o.rotation_mode='QUATERNION';o.rotation_quaternion=d.to_track_quat('Z','Y');bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for f in o.data.polygons:f.use_smooth=True
 return finish(o,bone,material)
BONES={'pelvis':((0,.78,0),(0,1,0),None),'torso':((0,1,0),(0,1.42,0),'pelvis'),'head':((0,1.42,0),(0,1.78,0),'torso')}
for side,x in [('L',-1),('R',1)]:
 BONES['upper_arm_'+side]=((x*.30,1.30,0),(x*.36,1.02,-.03),'torso')
 BONES['forearm_'+side]=((x*.36,1.02,-.03),(x*.25,1.06,-.32),'upper_arm_'+side)
 BONES['hand_'+side]=((x*.25,1.06,-.32),(x*.22,1.08,-.43),'forearm_'+side)
 BONES['thigh_'+side]=((x*.16,.78,0),(x*.17,.43,.015),'pelvis')
 BONES['shin_'+side]=((x*.17,.43,.015),(x*.17,.10,.015),'thigh_'+side)
 BONES['foot_'+side]=((x*.17,.10,.015),(x*.17,.07,-.20),'shin_'+side)

def build(kind):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False);parts.clear()
 arm=bpy.data.armatures.new('OperatorSkeleton');rig=bpy.data.objects.new('OperatorRig',arm);bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True)
 bpy.ops.object.mode_set(mode='EDIT')
 for name,(a,b,parent) in BONES.items():
  bone=arm.edit_bones.new(name);bone.head=v(a);bone.tail=v(b)
  if parent:bone.parent=arm.edit_bones[parent]
 bpy.ops.object.mode_set(mode='OBJECT')
 oval((0,1.12,.02),(.25,.29,.16),'torso')
 box((0,.82,.015),(.36,.20,.26),'pelvis',CLOTH,.04)
 box((0,.94,0),(.44,.065,.32),'pelvis',DARK,.02)
 box((0,1.19,-.145),(.41,.36,.085),'torso',ARMOR,.045)
 box((0,1.36,-.11),(.34,.055,.10),'torso',STEEL,.012)
 for x in [-.13,0,.13]:
  box((x,1.05,-.22),(.10,.15,.08),'torso',DARK,.015)
  box((x,1.09,-.265),(.085,.012,.008),'torso',ACCENT,.003)
 for x in [-.21,.21]:
  box((x,.88,-.04),(.075,.16,.17),'pelvis',DARK,.02)
  rod((x,1.35,-.15),(x,1.03,-.16),.022,'torso',DARK)
 # Human neck, ears, jaw, facial planes and visible eyes; no robotic faceplate.
 rod((0,1.25,0),(0,1.49,0),.065,'head',SKIN)
 oval((0,1.62,0),(.125,.18,.125),'head',SKIN)
 oval((0,1.535,-.045),(.091,.08,.085),'head',SKIN)
 oval((0,1.60,-.126),(.026,.045,.033),'head',SKIN)
 oval((0,1.565,-.137),(.031,.018,.022),'head',SKIN)
 oval((0,1.522,-.112),(.046,.009,.012),'head',LIP)
 for x in [-1,1]:
  oval((x*.125,1.61,0),(.024,.045,.028),'head',SKIN)
  oval((x*.052,1.638,-.112),(.032,.013,.013),'head',EYE)
  oval((x*.052,1.638,-.124),(.011,.011,.005),'head',HAIR)
  rod((x*.028,1.663,-.114),(x*.079,1.66,-.108),.008,'head',HAIR)
 oval((0,1.745,.015),(.127,.064,.12),'head',HAIR)
 if kind in ('enforcer','shield','elite'):
  oval((0,1.765,.015),(.143,.058,.14),'head',CLOTH)
  box((0,1.735,-.13),(.25,.018,.12),'head',CLOTH,.008)
 if kind=='flusher':
  # Half-mask leaves the eyes and forehead visibly human.
  oval((0,1.53,-.13),(.075,.055,.035),'head',DARK)
  for x in [-.115,.115]:
   rod((x,.98,.23),(x,1.36,.23),.085,'torso',ACCENT)
   box((x,1.1,.23),(.18,.045,.18),'torso',DARK,.01)
  box((0,1.18,.19),(.40,.43,.10),'torso',DARK,.02)
 if kind=='rusher':
  box((0,1.2,-.20),(.14,.23,.035),'torso',ACCENT,.01)
 for side,x in [('L',-1),('R',1)]:
  upper='upper_arm_'+side;fore='forearm_'+side;hand='hand_'+side;thigh='thigh_'+side;shin='shin_'+side;foot='foot_'+side
  a,b,_=BONES[upper];rod(a,b,.080,upper,CLOTH,r2=.068)
  a,b,_=BONES[fore];rod(a,b,.063,fore,SKIN,r2=.043)
  oval((x*.31,1.28,.01),(.095,.105,.10),upper,CLOTH)
  oval((x*.36,1.02,-.03),(.07,.085,.07),upper,CLOTH)
  oval((x*.36,1.02,-.03),(.078,.073,.075),fore,DARK)

  oval((x*.235,1.065,-.37),(.065,.06,.09),hand,SKIN)
  for j in range(4):oval((x*.235+(j-1.5)*.022,1.065,-.425),(.013,.035,.035),hand,SKIN)
  a,b,_=BONES[thigh];rod(a,b,.105,thigh,CLOTH,r2=.083)
  box((x*.17,.62,-.075),(.17,.23,.065),thigh,CLOTH,.025)
  a,b,_=BONES[shin];rod(a,b,.081,shin,CLOTH,r2=.065)
  oval((x*.17,.43,-.04),(.092,.085,.075),shin,DARK)
  box((x*.17,.43,-.09),(.16,.12,.06),shin,ARMOR,.025)

  box((x*.17,.08,-.075),(.18,.14,.30),foot,DARK,.035)
  box((x*.17,.025,-.075),(.185,.035,.31),foot,STEEL,.009)
 if kind=='shield':
  # Wide armored rim and a recessed viewport keep the silhouette readable.
  box((-.25,1.0,-.53),(.76,1.10,.065),'hand_L',ARMOR,.045)
  box((-.25,1.33,-.569),(.48,.12,.012),'hand_L',DARK,.008)
  box((-.25,1.33,-.578),(.40,.065,.005),'hand_L',VISOR,.002)
  for x in [-.57,.07]:box((x,1.0,-.57),(.035,.94,.02),'hand_L',STEEL,.006)
  for y in [.58,.64]:box((-.25,y,-.57),(.55,.025,.014),'hand_L',ACCENT,.004)
 if kind in ('rusher','shield'):
  rod((.23,1.06,-.34),(.23,1.5,-.56),.028,'hand_R',STEEL)
  rod((.23,1.37,-.495),(.23,1.5,-.56),.032,'hand_R',ACCENT)
 else:
  box((.22,1.11,-.46),(.085,.09,.29),'hand_R',STEEL,.012)
  box((.22,1.10,-.65),(.075,.08,.18),'hand_R',DARK,.01)
  rod((.22,1.12,-.71),(.22,1.12,-.89),.018,'hand_R',STEEL)
  box((.22,1.02,-.45),(.05,.16,.08),'hand_R',DARK,.008)
  for i in range(8):box((.22,1.165,-.36-i*.035),(.06,.012,.016),'hand_R',STEEL,.002)
 for o in parts:
  group=o.vertex_groups.new(name=o['bone']);group.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Skin','ARMATURE');mod.object=rig;o.parent=rig
 # Proportion pass: 1.80 m adult, ~7.5 head heights, narrower facial width.
 for o in parts:
  if o['bone']=='torso' or any(t in o['bone'] for t in ['arm_', 'hand_']):
   o.location.z += .12
  if o['bone']=='head':
   for vert in o.data.vertices:
    world=o.matrix_world @ vert.co
    world.x *= .88
    world.z = 1.56 + (world.z-1.44)*.67
    vert.co=o.matrix_world.inverted() @ world
 bpy.context.view_layer.objects.active=rig
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
 bpy.ops.object.mode_set(mode='EDIT')
 for bone in arm.edit_bones:
  if bone.name=='torso' or any(t in bone.name for t in ['arm_', 'hand_']):
   bone.head.z += .12;bone.tail.z += .12
 arm.edit_bones['head'].head=v((0,1.56,0));arm.edit_bones['head'].tail=v((0,1.80,0))
 bpy.ops.object.mode_set(mode='OBJECT')
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();bpy.context.object.name='OperatorMesh'
 bpy.ops.export_scene.gltf(filepath=str(ROOT/(kind+'.glb')),export_format='GLB',export_cameras=False,export_lights=False,export_extras=False)
for kind in ('enforcer','rusher','shield','flusher','elite'):build(kind)
manifest={'origin':'Original PROJECT: ZERO-LINE human soldier art','source':'tools/author_operators.py','bones':list(BONES),'models':{}}
for p in sorted(ROOT.glob('*.glb')):
 d=p.read_bytes();n=struct.unpack_from('<I',d,12)[0];g=json.loads(d[20:20+n]);tri=sum(g['accessors'][q['indices']]['count']//3 for m in g['meshes'] for q in m['primitives']);manifest['models'][p.name]={'sha256':hashlib.sha256(d).hexdigest(),'triangles':tri}
(ROOT/'provenance.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Exported five human soldiers with a shared 15-bone skin.')
