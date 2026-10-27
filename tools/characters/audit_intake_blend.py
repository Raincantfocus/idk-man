"""Read-only audit of a supplied blend. Run Blender with --disable-autoexec.
Usage: blender -b --disable-autoexec source.blend -P this.py -- report.json
"""
import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector
output=Path(sys.argv[sys.argv.index('--')+1]);output.parent.mkdir(parents=True,exist_ok=True)
meshes=[];bounds=[]
for obj in bpy.context.scene.objects:
 if obj.type!='MESH' or obj.name.startswith(('WGT','smd_bone_vis')):continue
 m=obj.data
 world=[obj.matrix_world@Vector(v) for v in obj.bound_box];bounds+=world
 deform={b.name for modifier in obj.modifiers if modifier.type=='ARMATURE' and modifier.object for b in modifier.object.data.bones if b.use_deform}
 group_names={g.index:g.name for g in obj.vertex_groups}
 uv=m.uv_layers.active
 uv_area=world_area=0.0
 m.calc_loop_triangles()
 for tri in m.loop_triangles:
  a,b,c=[obj.matrix_world@m.vertices[i].co for i in tri.vertices];world_area+=(b-a).cross(c-a).length/2
  if uv:
   a,b,c=[uv.data[i].uv for i in tri.loops];uv_area+=abs((b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x))/2
 mesh=dict(name=obj.name,vertices=len(m.vertices),triangles=len(m.loop_triangles),quads=sum(len(p.vertices)==4 for p in m.polygons),materials=[s.material.name if s.material else None for s in obj.material_slots],uv_layers=[v.name for v in m.uv_layers],uv_area_sum=uv_area,world_surface_area_scene_units2=world_area,shape_keys=list(m.shape_keys.key_blocks.keys()) if m.shape_keys else [],armatures=[mod.object.name for mod in obj.modifiers if mod.type=='ARMATURE' and mod.object],unweighted_vertices=sum(not any(g.weight>1e-5 and group_names.get(g.group) in deform for g in v.groups) for v in m.vertices),over_four_weights=sum(sum(g.weight>1e-5 and group_names.get(g.group) in deform for g in v.groups)>4 for v in m.vertices),non_manifold_edges=None)
 meshes.append(mesh)
rigs=[]
for obj in bpy.context.scene.objects:
 if obj.type!='ARMATURE':continue
 rigs.append(dict(name=obj.name,bones=len(obj.data.bones),deform=sum(b.use_deform for b in obj.data.bones),scale=list(obj.scale),bone_names=[b.name for b in obj.data.bones]))
images=[dict(name=i.name,size=list(i.size),packed=bool(i.packed_file or i.packed_files),path=i.filepath) for i in bpy.data.images]
materials=[]
for m in bpy.data.materials:
 materials.append(dict(name=m.name,textures=[{'node':n.name,'image':n.image.name,'outputs':[(l.from_socket.name,l.to_node.name,l.to_socket.name) for l in m.node_tree.links if l.from_node==n]} for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image] if m.use_nodes else []))
size=[max(v[i] for v in bounds)-min(v[i] for v in bounds) for i in range(3)] if bounds else []
report=dict(source=Path(bpy.data.filepath).name,blender=bpy.app.version_string,unit_scale=bpy.context.scene.unit_settings.scale_length,bounds_scene_units=size,height_z_m=size[2]*bpy.context.scene.unit_settings.scale_length if size else None,triangles=sum(m['triangles'] for m in meshes),material_slots=sum(len(m['materials']) for m in meshes),unique_materials=len({v for m in meshes for v in m['materials'] if v}),meshes=meshes,rigs=rigs,images=images,material_nodes=materials,actions=[a.name for a in bpy.data.actions])
output.write_text(json.dumps(report,indent=2)+'\n');print('INTAKE_AUDIT',report['source'],report['triangles'],report['unique_materials'],report['height_z_m'],flush=True)
