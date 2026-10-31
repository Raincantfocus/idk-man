"""Blender 5: author reusable GLTF cover meshes; source car retains CC-BY credit.
Usage: python script SOURCE_KILLHOUSE_GLTF OUTPUT_DIRECTORY
"""
import bpy,sys,math,json
from pathlib import Path
from mathutils import Vector
source,out=sys.argv[1:];out=Path(out);out.mkdir(parents=True,exist_ok=True)
report=[]
def reset():
 bpy.ops.wm.read_factory_settings(use_empty=True)
 global mats;mats={}
 for name,color,metal in [('paint',(0.18,.25,.28,1),.7),('rubber',(.035,.04,.045,1),0),('glass',(.10,.17,.21,1),.35),('wood',(.32,.22,.12,1),0),('steel',(.22,.24,.27,1),.8),('concrete',(.42,.44,.45,1),0),('light',(.85,.79,.60,1),.2)]:
  m=bpy.data.materials.new(name);m.diffuse_color=color;m.use_nodes=True;bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=color;bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=.5 if metal else .8;mats[name]=m
# Blender coordinates already use X width, Y depth, Z height.
def box(c,s,mat='paint',bevel=.015):
 bpy.ops.mesh.primitive_cube_add(size=1,location=c);o=bpy.context.object;o.scale=s;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[mat])
 if bevel:
  b=o.modifiers.new('edge','BEVEL');b.width=bevel;b.segments=1;bpy.ops.object.modifier_apply(modifier=b.name)
 return o
def cyl(c,r,h,mat='paint',axis='Z'):
 bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=h,location=c);o=bpy.context.object;o.data.materials.append(mats[mat])
 if axis=='X':o.rotation_euler.y=math.pi/2
 if axis=='Y':o.rotation_euler.x=math.pi/2
 return o
def beam(a,b,w=.07,mat='steel'):
 a,b=Vector(a),Vector(b);o=box((a+b)/2,(w,w,(b-a).length),mat);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def export(name):
 objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];bpy.ops.object.select_all(action='DESELECT')
 for o in objs:o.select_set(True)
 bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();obj=bpy.context.object;obj.name=name
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);obj.data.calc_loop_triangles();tris=len(obj.data.loop_triangles)
 bpy.ops.export_scene.gltf(filepath=str(out/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True)
 report.append({'name':name,'triangles':tris,'materials':len(obj.data.materials),'origin':'ground centre','authorship':'original scripted modeling; car derived from supplied Killhouse CC-BY-4.0' if name=='car' else 'original scripted modeling for ZERO-LINE'})
reset();bpy.ops.import_scene.gltf(filepath=source)
car=next(o for o in bpy.context.scene.objects if o.name=='Object_4');matrix=car.matrix_world.copy();car.parent=None;car.matrix_world=matrix
for o in list(bpy.context.scene.objects):
 if o!=car:bpy.data.objects.remove(o,do_unlink=True)
bpy.context.view_layer.objects.active=car;car.select_set(True);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
# Source car's longest horizontal dimension becomes X, then normalize to spec.
import numpy as np
v=np.array([p.co[:] for p in car.data.vertices]);c=v.mean(0);_,_,basis=np.linalg.svd(v[:,:2]-c[:2],full_matrices=False);q=(v[:,:2]-c[:2])@basis.T
for i,p in enumerate(car.data.vertices):p.co.x=float(q[i,0]);p.co.y=float(q[i,1])
v=np.array([p.co[:] for p in car.data.vertices]);lo=v.min(0);span=np.ptp(v,axis=0)
for p in car.data.vertices:p.co=Vector(((p.co.x-(lo[0]+span[0]/2))*3.5/span[0],(p.co.y-(lo[1]+span[1]/2))*1.8/span[1],(p.co.z-lo[2])*1.5/span[2]))
car.data.materials.clear();car.data.materials.append(mats['paint']);d=car.modifiers.new('cover_lod','DECIMATE');d.ratio=.15;bpy.ops.object.modifier_apply(modifier=d.name);export('car')
reset()
# Corrugated container 6 x 2.4 x 2.6.
box((0,0,1.3),(6,2.4,2.6),'paint',.04)
for y in [-1.215,1.215]:
 for i in range(31):box((-2.9+i*.1933,y,1.3),(.065,.035,2.45),'steel',.004)
for x in [-3.025,3.025]:
 for y in [-.6,.6]:box((x,y,1.3),(.04,1.15,2.45),'paint',.01)
 for y in [-.95,-.25,.25,.95]:cyl((x,y,1.3),.025,2.35,'steel')
for y in [-1.2,1.2]:
 for z in [.07,2.53]:box((0,y,z),(6.08,.09,.14),'steel')
export('container')
reset()
box((0,0,.7),(2,1.4,1.2),'paint',.07)
for x in [-.65,.65]:
 for y in [-.48,.48]:cyl((x,y,.12),.12,.12,'rubber','Y')
for y in [-.73,.73]:box((0,y,.75),(1.85,.06,.12),'steel')
for x in [-.5,.5]:box((x,0,1.34),(.96,1.44,.12),'rubber',.025)
export('dumpster')
reset()
for z in [.12,.38,.64]:
 for x in [-.95,0,.95]:box((x,0,z),( .20,.95,.22),'wood',.005)
 for y in [-.4,-.2,0,.2,.4]:box((0,y,z+.14),(2.4,.16,.06),'wood',.004)
export('pallet')
reset()
box((0,0,1),(1.9,1.9,1.9),'wood')
for x in [-.98,.98]:
 for y in [-.85,.85]:box((x,y,1),(.04,.13,2),'wood',.004)
 for z in [.12,1.88]:box((x,0,z),(.04,2,.13),'wood',.004)
 beam((x,-.85,.15),(x,.85,1.85),.12,'wood')
for y in [-.98,.98]:
 for x in [-.85,.85]:box((x,y,1),(.13,.04,2),'wood',.004)
 for z in [.12,1.88]:box((0,y,z),(2,.04,.13),'wood',.004)
 beam((-.85,y,.15),(.85,y,1.85),.12,'wood')
export('crate')
reset();cyl((0,0,.5),.29,.98)
for h in [.05,.32,.68,.95]:cyl((0,0,h),.3,.035,'steel')
cyl((.12,.08,1.005),.04,.012,'steel');export('barrel')
reset()
# Jersey cross section, extruded along width.
section=[(-.5,0),(.5,0),(.5,.2),(.2,.65),(.2,1.2),(-.2,1.2),(-.2,.65),(-.5,.2)]
v=[(x,y,z) for x in [-2.5,2.5] for y,z in section];f=[tuple(range(7,-1,-1)),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)];m=bpy.data.meshes.new('jersey');m.from_pydata(v,[],f);m.materials.append(mats['concrete']);o=bpy.data.objects.new('jersey',m);bpy.context.collection.objects.link(o);export('barrier')
reset()
# Forklift silhouette: rear counterweight, seat, mast/carriage, forks and guard.
box((-.35,0,.55),(1.5,1.2,.6),'paint',.09);box((-.9,0,.8),(.45,1.3,.6),'paint',.08)
for x in [-.75,.55]:
 for y in [-.64,.64]:cyl((x,y,.30),.30,.18,'rubber','Y')
box((-.2,0,1.05),(.5,.55,.16),'rubber');box((-.42,0,1.3),(.12,.55,.45),'rubber')
for x in [-.65,.3]:
 for y in [-.55,.55]:beam((x,y,.8),(x,y,2.1),.07)
box((-.175,0,2.15),(1.1,1.3,.1),'steel')
for y in [-.42,.42]:box((.8,y,1.1),(.12,.12,2.2),'steel');box((1.1,y,.13),(.6,.16,.10),'steel')
box((.82,0,.58),(.12,1,.12),'steel');export('forklift')
reset()
# Delivery truck with cab, cargo box, bumper, grille, mirrors and wheels.
box((.65,0,1.65),(3.65,2.35,2.3),'paint',.06);box((-1.8,0,1.35),(1.35,2.3,1.7),'paint',.09)
box((-2.49,0,1.8),(.03,1.9,.6),'glass',.005);box((-2.51,0,.92),(.05,1.5,.35),'steel')
for y in [-1.17,1.17]:box((-1.8,y,1.8),(.9,.03,.6),'glass',.005)
for x in [-1.75,1.65]:
 for y in [-1.16,1.16]:cyl((x,y,.4),.4,.18,'rubber','Y');cyl((x,y*1.08,.4),.18,.03,'steel','Y')
for y in [-.85,.85]:box((-2.53,y,1.1),(.06,.3,.2),'light')
box((-2.5,0,.58),(.12,2.5,.18),'steel');export('truck')
(out/'provenance.json').write_text(json.dumps({'source_car':{'author':'_.quve','license':'CC-BY-4.0','url':'https://sketchfab.com/3d-models/killhouse-a2ce333ba32548d5b454131f6016c961'},'assets':report,'quality':'Readable authored prototype meshes; not purchased photoreal production assets'},indent=2)+'\n')
