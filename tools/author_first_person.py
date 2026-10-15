"""Original game-art approximations of M4A1, SPAS-12, and USP .45 silhouettes. Run with blender --background --python this_file.
Coordinates below are Godot meters (X right, Y up, -Z forward).
This is visual game geometry, not manufacturing or functional weapon data.
"""
import bpy
import math
from mathutils import Vector
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1] / 'assets/first_person'
ROOT.mkdir(parents=True, exist_ok=True)
def v(p): return Vector((p[0], -p[2], p[1]))
def clear():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def material(name, color, metal, rough):
    m = bpy.data.materials.new(name); m.diffuse_color = (*color, 1); m.use_nodes = True
    bs = m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*color, 1)
    bs.inputs['Metallic'].default_value = metal; bs.inputs['Roughness'].default_value = rough
    return m
METAL=material('Phosphate steel', (.055,.068,.077), .85,.37)
EDGE=material('Machined edges', (.20,.23,.25), .9,.29)
POLY=material('Grip polymer', (.037,.043,.044), .08,.78)
PAINT=material('Ceramic sand finish', (.28,.25,.19), .45,.52)
RUBBER=material('Glove reinforced rubber', (.032,.039,.038), .02,.86)
FABRIC=material('Olive woven sleeve', (.14,.17,.12), 0,.94)
STITCH=material('Seams and markings', (.42,.44,.34), .05,.8)
BRASS=material('Shell brass', (.55,.32,.08), .8,.28)
RED=material('Shell hull', (.27,.025,.015), .05,.58)
LUME=material('Sight phosphor', (.55,.86,.28), .1,.4)
parts=[]
def finish(o, name, mat, group='Static', bone=None):
    o.name=name; o.data.materials.append(mat); o['group']=group
    if bone: o['bone']=bone
    parts.append(o); return o
def box(name, center, size, mat=METAL, bevel=.008, group='Static', bone=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=v(center)); o=bpy.context.object
    o.scale=(size[0],size[2],size[1]); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        m=o.modifiers.new('Machined bevel','BEVEL'); m.width=bevel; m.segments=3
        bpy.ops.object.modifier_apply(modifier=m.name)
        m=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL'); bpy.ops.object.modifier_apply(modifier=m.name)
    return finish(o,name,mat,group,bone)
def rod(name, a, b, radius, mat=METAL, group='Static', bone=None, r2=None):
    a,b=v(a),v(b); d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=radius, radius2=radius if r2 is None else r2, depth=d.length, location=(a+b)/2)
    o=bpy.context.object; o.rotation_mode='QUATERNION'; o.rotation_quaternion=d.to_track_quat('Z','Y')
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for face in o.data.polygons: face.use_smooth=True
    return finish(o,name,mat,group,bone)
def mark(text, p, size=.018):
    # Raised, readable markings on the right receiver side.
    bpy.ops.object.text_add(location=v(p)); o=bpy.context.object
    o.data.body=text; o.data.size=size; o.data.extrude=.0003
    o.rotation_euler=(math.pi/2,0,math.pi/2)
    bpy.ops.object.convert(target='MESH'); finish(bpy.context.object,'Marking',STITCH)
def empty(name, pos):
    o=bpy.data.objects.new(name,None); bpy.context.collection.objects.link(o); o.location=v(pos); return o

def pack_weapon(name, muzzle, eject, left_grip, sight):
    groups={group:[o for o in parts if o['group']==group] for group in sorted({o['group'] for o in parts})}
    for group,objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects: o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]; bpy.ops.object.join()
        obj=bpy.context.object; obj.name=group
        bpy.context.scene.cursor.location=(0,0,0); bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    empty('MuzzleSocket',muzzle); empty('EjectionSocket',eject); empty('SupportGrip',left_grip); empty('SightLine',sight)
    scale={'carbine':.66,'shotgun':.76,'sidearm':.72}[name]
    for obj in bpy.context.scene.objects:
        obj.location *= scale
        if obj.type=='MESH':
            for vert in obj.data.vertices: vert.co *= scale
    bpy.ops.export_scene.gltf(filepath=str(ROOT/(name+'.glb')),export_format='GLB',export_cameras=False,export_lights=False,export_extras=False)

def weapon(kind):
    clear(); parts.clear()
    pistol=kind=='sidearm'; shotgun=kind=='shotgun'
    if pistol:
        box('Frame',(0,-.025,-.09),(.075,.065,.24),POLY,.012)
        box('Slide',(0,.03,-.12),(.079,.075,.29),METAL,.009,'Action')
        rod('Barrel',(0,.03,-.18),(0,.03,-.28),.016,EDGE)
        rod('Bore',(0,.03,-.282),(0,.03,-.284),.009,POLY)
        box('Grip',(0,-.13,.015),(.072,.18,.10),POLY,.018)
        box('Magazine',(0,-.15,.016),(.056,.18,.065),METAL,.005,'Magazine')
        box('Baseplate',(0,-.245,.016),(.079,.016,.095),POLY,.004,'Magazine')
        for side in [-1,1]:
            for i in range(6): box('Slide serration',(side*.039,.034,-.035+i*.010),(.004,.048,.005),EDGE,.001,'Action')
            for i in range(6): box('Grip texture',(side*.037,-.09-i*.021,.015),(.003,.006,.065),RUBBER,.001)
        # Open trigger guard, front post and rear notch leave the sight line clear.
        box('Guard bottom',(0,-.095,-.075),(.063,.012,.11),POLY,.004)
        box('Guard front',(0,-.065,-.13),(.063,.065,.012),POLY,.004)
        rod('Trigger',(0,-.03,-.07),(0,-.075,-.06),.009,EDGE,group='Trigger')
        for x in [-.027,.027]: box('Rear sight',(x,.083,.005),(.016,.022,.03),POLY,.002)
        box('Front sight',(0,.083,-.24),(.012,.022,.018),POLY,.002)
        box('Front dot',(0,.085,-.229),(.005,.006,.001),LUME,.0003)
        box('Safety decocker',(-.044,.004,.01),(.015,.015,.045),METAL,.003)
        box('Slide release',(-.044,-.014,-.04),(.012,.013,.055),METAL,.003)
        rod('Thread protector',(0,.03,-.28),(0,.03,-.31),.019,METAL)
        mark('USP .45',(.041,.035,-.15),.012)
        pack_weapon(kind,(0,.03,-.315),(.05,.035,-.075),(-.055,-.13,.01),(0,.085,0))
        return
    finish_mat=METAL
    box('Receiver',(0,0,-.10),(.115,.13,.34),finish_mat,.016)
    box('Lower',(0,-.075,-.06),(.10,.07,.25),METAL,.010)
    box('Pistol grip',(0,-.17,.06),(.08,.20,.10),POLY,.014)
    for i in range(7): box('Grip rib',(0,-.10-i*.024,.116),(.069,.008,.006),RUBBER,.002)
    box('Trigger guard bottom',(0,-.15,-.04),(.075,.012,.12),METAL,.004)
    box('Trigger guard front',(0,-.11,-.103),(.075,.075,.012),METAL,.004)
    rod('Trigger',(0,-.08,-.045),(0,-.13,-.025),.008,EDGE,group='Trigger')
    if shotgun:
        for side in [-1,1]:
            rod('Stock hinge',(side*.05,.03,.06),(side*.08,.03,.06),.027,EDGE)
            box('Folding stock strut',(side*.06,.08,.23),(.018,.045,.39),METAL,.005,'Stock')
        box('Folding butt plate',(0,.025,.42),(.14,.19,.025),METAL,.005,'Stock')
        rod('Shell loading proxy',(0,-.12,-.12),(0,-.12,-.19),.018,RED,group='Magazine')
        box('Loading port',(0,-.105,-.12),(.055,.006,.12),POLY,.005)
        box('Mode selector',(-.065,-.03,-.34),(.02,.023,.04),EDGE,.004)
    else:
        rod('Buffer',(0,.01,.06),(0,.01,.31),.033,METAL)
        box('Stock cheek',(0,.015,.26),(.105,.085,.24),POLY,.018)
        box('Stock heel',(0,-.035,.39),(.11,.19,.045),POLY,.013)
        box('Buttpad',(0,-.035,.417),(.115,.20,.025),RUBBER,.008)
        box('Magazine upper',(0,-.16,-.13),(.065,.17,.115),METAL,.01,'Magazine')
        box('Magazine curved lower',(0,-.285,-.11),(.065,.12,.115),METAL,.01,'Magazine')
        for side in [-1,1]:
            for z in [-.16,-.115,-.07]: box('Magazine stamp',(side*.034,-.20,z),(.004,.17,.012),EDGE,.002,'Magazine')
        box('Forward assist',(.075,.02,.015),(.04,.035,.045),METAL,.008)
        box('Selector',(-.061,-.045,.01),(.012,.015,.035),EDGE,.003)
    box('Ejection port',(.059,.015,-.11),(.003,.047,.115),POLY,.005)
    box('Bolt',(.062,.015,-.11),(.007,.035,.084),EDGE,.004,'Action')
    rod('Charging handle',(.06,.012,-.09),(.10,.012,-.09),.012,METAL,group='Action')
    for side in [-1,1]:
        for z in [.025,-.23]: rod('Receiver pin',(side*.057,-.02,z),(side*.062,-.02,z),.009,EDGE)
    end=-.96 if shotgun else -.80
    if shotgun:
        rod('Barrel',(0,.015,-.25),(0,.015,end),.024,METAL)
        rod('Underbarrel',(0,-.052,-.25),(0,-.052,-.76),.019,EDGE)
        box('Foreend',(0,-.035,-.43),(.115,.12,.25),POLY,.02)
        for i in range(9): box('Foreend rib',(0,-.035,-.32-i*.025),(.124,.125,.008),RUBBER,.003)
        for side in [-1,1]:
            for i in range(12): box('Heat shield vent',(side*.028,.044,-.29-i*.042),(.009,.024,.022),POLY,.004)
        for i in range(4):
            z=-.21+i*.052
            rod('Shell carrier',(-.07,-.04,z),(-.07,.055,z),.018,RED)
            rod('Shell rim',(-.07,.055,z),(-.07,.067,z),.019,BRASS)
    else:
        box('Handguard',(0,0,-.43),(.10,.12,.31),finish_mat,.018)
        rod('Barrel',(0,.005,-.52),(0,.005,end),.019,EDGE)
        for side in [-1,1]:
            for i in range(7): box('Handguard slot',(side*.051,.005,-.30-i*.038),(.003,.032,.025),POLY,.005)
            for i in range(5): box('Lower grip rib',(side*.045,-.06,-.33-i*.04),(.012,.012,.015),RUBBER,.002)
    rod('Muzzle device',(0,.012,end+.065),(0,.012,end),.031,METAL)
    rod('Dark bore',(0,.012,end-.001),(0,.012,end-.004),.016,POLY)
    for i in range(20): box('Rail tooth',(0,.078,.04-i*.03),(.063,.018,.014),EDGE,.002)
    if not shotgun:
        # Open optic tube, rings, mount and reticle. Magnification is not simulated.
        for z in [-.19,.015]:
            for j in range(24):
                angle=j*math.tau/24; a2=(j+1)*math.tau/24
                rod('Optic ring',(math.cos(angle)*.043,.17+math.sin(angle)*.043,z),(math.cos(a2)*.043,.17+math.sin(a2)*.043,z),.006,METAL)
        for j in range(24):
            angle=j*math.tau/24
            rod('Optic housing',(math.cos(angle)*.043,.17+math.sin(angle)*.043,-.19),(math.cos(angle)*.043,.17+math.sin(angle)*.043,.015),.006,METAL)
        box('Optic mount',(0,.105,-.08),(.055,.045,.16),METAL,.004)
        rod('Elevation turret',(0,.21,-.07),(0,.237,-.07),.018,METAL)
        rod('Reticle horizontal',(-.029,.17,-.18),(.029,.17,-.18),.001,LUME)
        rod('Reticle vertical',(0,.141,-.18),(0,.199,-.18),.001,LUME)
    else:
        for x in [-.033,.033]: box('Sight ear',(x,.122,.015),(.018,.084,.035),METAL,.004)
        box('Front post',(0,.12,-.57),(.017,.060,.025),METAL,.003)
    mark('SPAS-12' if shotgun else 'M4A1',(.059,.035,-.23))
    pack_weapon(kind,(0,.012,end-.01),(.085,.02,-.10),(-.04,-.10,-.43 if shotgun else -.38),(0,.15 if shotgun else .17,0))

for kind in ['carbine','shotgun','sidearm']: weapon(kind)

# Four deform bones give the sleeve/wrist pair on each arm independent motion.
clear(); parts.clear()
arm=bpy.data.armatures.new('OperatorArmature'); rig=bpy.data.objects.new('OperatorRig',arm)
bpy.context.collection.objects.link(rig); bpy.context.view_layer.objects.active=rig; rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
points={'R':((.20,-.38,.48),(.055,-.19,.10),(.055,-.09,.035)),
        'L':((-.30,-.32,.18),(-.08,-.13,-.32),(-.04,-.10,-.41))}
for side,(elbow,wrist,hand) in points.items():
    fore=arm.edit_bones.new('forearm_'+side); fore.head=v(elbow); fore.tail=v(wrist)
    palm=arm.edit_bones.new('hand_'+side); palm.head=v(wrist); palm.tail=v(hand); palm.parent=fore
bpy.ops.object.mode_set(mode='OBJECT')
for side,(elbow,wrist,hand) in points.items():
    bone='forearm_'+side; hbone='hand_'+side
    rod('Sleeve',elbow,wrist,.078,FABRIC,bone=bone,r2=.051)
    e,w=v(elbow),v(wrist)
    # Cuff, seams, and compressed fabric folds.
    for i in range(6):
        t=.70+i*.045
        a=tuple(elbow[j]+(wrist[j]-elbow[j])*t for j in range(3))
        b=tuple(elbow[j]+(wrist[j]-elbow[j])*(t+.018) for j in range(3))
        rod('Sleeve fold',a,b,.056,FABRIC,bone=bone)
    rod('Wrist cuff',tuple(wrist[j]+(elbow[j]-wrist[j])*.10 for j in range(3)),wrist,.054,RUBBER,bone=bone)
    if side=='R':
        box('Palm',(.055,-.13,.05),(.083,.10,.09),RUBBER,.024,bone=hbone)
        for i in range(4):
            y=-.09-i*.024
            rod('Finger proximal',(.058,y,.008),(.005,y,-.002),.012,RUBBER,bone=hbone)
            rod('Finger tip',(.005,y,-.002),(-.026,y,.027),.011,RUBBER,bone=hbone)
            box('Knuckle pad',(.092,y,.04),(.012,.018,.04),POLY,.005,bone=hbone)
        rod('Thumb',(.06,-.075,.08),(-.006,-.073,.065),.015,RUBBER,bone=hbone)
        box('Glove seam',(.098,-.135,.065),(.002,.075,.003),STITCH,.001,bone=hbone)
    else:
        box('Palm',(-.035,-.102,-.38),(.10,.055,.13),RUBBER,.020,bone=hbone)
        for i in range(4):
            z=-.335-i*.029
            rod('Finger proximal',(-.04,-.10,z),(.045,-.085,z),.012,RUBBER,bone=hbone)
            rod('Finger tip',(.045,-.085,z),(.052,-.046,z),.011,RUBBER,bone=hbone)
            box('Knuckle pad',(-.075,-.085,z),(.015,.025,.022),POLY,.005,bone=hbone)
        rod('Thumb',(-.067,-.10,-.33),(-.055,-.045,-.35),.015,RUBBER,bone=hbone)
for o in parts:
    group=o.vertex_groups.new(name=o['bone']); group.add(list(range(len(o.data.vertices))),1.0,'REPLACE')
    mod=o.modifiers.new('Skin','ARMATURE'); mod.object=rig; o.parent=rig
bpy.ops.object.select_all(action='DESELECT')
for o in parts: o.select_set(True)
bpy.context.view_layer.objects.active=parts[0]; bpy.ops.object.join(); bpy.context.object.name='GlovesAndSleeves'
bpy.ops.export_scene.gltf(filepath=str(ROOT/'operator_arms.glb'),export_format='GLB',export_cameras=False,export_lights=False,export_extras=False)
print('Authored three reference-based weapon approximations and a four-bone first-person arm rig.')

# Record original source and geometry budgets with the generated assets.
import hashlib
import json
import struct
manifest = {'source': 'tools/author_first_person.py', 'origin': 'Original visual approximations of M4A1, SPAS-12 and USP .45; no manufacturer assets or endorsements', 'models': {}}
for path in sorted(ROOT.glob('*.glb')):
    data = path.read_bytes()
    length = struct.unpack_from('<I', data, 12)[0]
    scene = json.loads(data[20:20 + length])
    triangles = sum(scene['accessors'][part['indices']]['count'] // 3
                    for mesh in scene['meshes'] for part in mesh['primitives'])
    manifest['models'][path.name] = {'sha256': hashlib.sha256(data).hexdigest(), 'triangles': triangles}
(ROOT / 'provenance.json').write_text(json.dumps(manifest, indent=2) + '\n')
