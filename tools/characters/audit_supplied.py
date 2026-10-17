"""Read-only Blender source inventory. Run with --disable-autoexec and a supplied blend.
Writes JSON beside the asset's extracted/ directory, never resaves the blend.
"""
import bpy,json
from pathlib import Path
meshes=[]
for obj in bpy.data.objects:
 if obj.type!='MESH' or obj.name.startswith('WGT') or obj.name=='smd_bone_vis':continue
 m=obj.data
 meshes.append(dict(name=obj.name,triangles=sum(len(p.vertices)-2 for p in m.polygons),
  materials=[s.material.name if s.material else None for s in obj.material_slots],
  skinned=any(mod.type=='ARMATURE' for mod in obj.modifiers),
  parent=obj.parent.name if obj.parent else None,parent_type=obj.parent_type,parent_bone=obj.parent_bone,
  uv_layers=[uv.name for uv in m.uv_layers],shape_keys=list(m.shape_keys.key_blocks.keys()) if m.shape_keys else [],
  unweighted_vertices=sum(not any(g.weight>0 for g in v.groups) for v in m.vertices),
  over_four_weights=sum(sum(g.weight>1e-5 for g in v.groups)>4 for v in m.vertices)))
report=dict(file=Path(bpy.data.filepath).name,blender=bpy.app.version_string,
 triangles=sum(m['triangles'] for m in meshes),materials=len({s for m in meshes for s in m['materials'] if s}),meshes=meshes,
 rigs=[dict(name=a.name,bones=len(a.bones),deform=sum(b.use_deform for b in a.bones),bone_names=[b.name for b in a.bones]) for a in bpy.data.armatures],
 actions=[a.name for a in bpy.data.actions],images=[dict(name=i.name,size=list(i.size),packed=bool(i.packed_file or i.packed_files),path=i.filepath) for i in bpy.data.images])
p=Path(bpy.data.filepath).parent.parent/'audit.json';p.write_text(json.dumps(report,indent=2));print('AUDIT',p,report['triangles'],report['materials'],flush=True)
