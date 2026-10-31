"""Blender 5: author reusable GLTF cover meshes; source car retains CC-BY credit.
Usage: python script SOURCE_KILLHOUSE_GLTF OUTPUT_DIRECTORY
"""
import bpy,sys,math,json
from pathlib import Path
from mathutils import Vector
out=sys.argv[1];out=Path(out);out.mkdir(parents=True,exist_ok=True)
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

reset()
m=bpy.data.materials.new('fabric');m.diffuse_color=(.22,.25,.21,1);mats['fabric']=m
box((0,0,.24),(2,.9,.3),'wood',.025)
box((0,.35,.58),(2,.2,.54),'fabric',.06)
for x in [-.88,.88]:box((x,0,.53),(.24,.9,.52),'fabric',.055)
for x in [-.48,0,.48]:box((x,-.08,.49),(.46,.65,.18),'fabric',.045)
for x in [-.8,.8]:
 for y in [-.3,.3]:box((x,y,.075),(.08,.08,.15),'wood')
export('couch')
reset();box((0,0,.55),(1.2,.65,.08),'wood')
for x in [-.5,.5]:
 for y in [-.23,.23]:box((x,y,.27),(.06,.06,.54),'steel')
export('coffee_table')
reset()
box((0,0,.62),(5,2,.42));box((-1,0,1.25),(1.9,2,1.1),bevel=.09)
box((-1.98,0,1.4),(.04,1.75,.55),'glass');box((-2.1,0,.95),(.8,2,.35))
for y in [-1.01,1.01]:box((-1,y,1.4),(1.5,.035,.55),'glass');box((1.25,y,1),(2.45,.12,.6))
box((2.45,0,1),(.12,2,.6));box((1.25,0,.8),(2.4,1.85,.08),'rubber')
for x in [-1.6,1.6]:
 for y in [-1,1]:cyl((x,y,.4),.4,.23,'rubber','Y');cyl((x,y*1.13,.4),.19,.04,'steel','Y')
export('pickup')
reset();box((0,0,2),(13.6,2.6,2.8),'paint',.04);box((0,0,.6),(13.2,2.3,.18),'steel')
for x in [3.6,4.6,5.6]:
 for y in [-1.15,1.15]:cyl((x,y,.42),.42,.28,'rubber','Y')
for y in [-.9,.9]:box((-3.8,y,.4),(.12,.12,.8),'steel')
for y in [-1.32,1.32]:
 for x in range(-6,7):box((x,y,2),(.04,.03,2.6),'steel',.003)
export('semi_trailer')
(out/'additional_provenance.json').write_text(json.dumps({'assets':report,'quality':'Original prototype props, not photoreal production assets'},indent=2))
