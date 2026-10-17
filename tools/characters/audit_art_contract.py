"""Blender preflight for a deforming garment/body authoring blend, not rigid gear.
Run with --disable-autoexec --python-exit-code 2 FILE --python THIS -- REPORT.json.
Reports failures explicitly. Does not modify the source or approve visual quality.
"""
import bpy,json,sys,math
from pathlib import Path
repo=Path(__file__).resolve().parents[2]
cfg=json.loads((repo/'data/characters/authoring_contract.json').read_text())
output=Path(sys.argv[sys.argv.index('--')+1]).resolve()
assert not output.is_relative_to(repo), 'Private reports must remain outside the repository'
report={'source':Path(bpy.data.filepath).name,'visual_approval':False,'meshes':[],'failures':[]}
rigs=[o for o in bpy.data.objects if o.type=='ARMATURE']
if len(rigs)!=1:report['failures'].append('Exactly one authoring skeleton required')
else:
 count=len(rigs[0].data.bones);report['bones']=count
 if not cfg['bone_count'][0]<=count<=cfg['bone_count'][1]:report['failures'].append('Bone count out of budget')
for obj in bpy.data.objects:
 if obj.type!='MESH':continue
 mesh=obj.data;mesh.calc_loop_triangles()
 row={'name':obj.name,'vertices':len(mesh.vertices),'triangles':len(mesh.loop_triangles),'materials':len(mesh.materials)}
 skin_groups={g.index for g in obj.vertex_groups if any(t in g.name for t in cfg['deformation_group_tokens'])}
 deform_vertices={v.index for v in mesh.vertices if any(g.group in skin_groups and g.weight>=cfg['deformation_min_weight'] for g in v.groups)}
 row['nonquad_deformation_faces']=sum(len(p.vertices)!=4 and any(v in deform_vertices for v in p.vertices) for p in mesh.polygons)
 row['bad_weight_vertices']=sum(len([g for g in v.groups if g.weight>1e-6])>cfg['max_influences'] or abs(sum(g.weight for g in v.groups)-1)>cfg['weight_sum_tolerance'] for v in mesh.vertices)
 shapes=set(mesh.shape_keys.key_blocks.keys()) if mesh.shape_keys else set()
 row['missing_correctives']=[name for name in cfg['required_correctives'] if name not in shapes]
 row['missing_seam_attributes']=[name for name in cfg['seam_attributes'] if name not in mesh.attributes]
 area=0.0;uv_area=0.0;zero_uv=0
 if mesh.uv_layers.active:
  uv=mesh.uv_layers.active.data
  for tri in mesh.loop_triangles:
   points=[uv[i].uv for i in tri.loops]
   a=points[1]-points[0];b=points[2]-points[0]
   uv_triangle_area=abs(a.x*b.y-a.y*b.x)*.5
   uv_area+=uv_triangle_area;area+=tri.area
   if uv_triangle_area<1e-12:zero_uv+=1
  row['aggregate_texels_per_meter']=cfg['atlas_resolution']*math.sqrt(uv_area/area) if area else 0
  row['uv_triangle_area_sum']=uv_area
  row['surface_area_m2']=area
  row['zero_area_uv_triangles']=zero_uv
  row['density_note']='Aggregate area ratio; overlapping islands and local stretch require separate visual review'
 else:row['missing_uv']=True
 for key in ['nonquad_deformation_faces','bad_weight_vertices','missing_correctives','missing_seam_attributes','missing_uv','zero_area_uv_triangles']:
  if row.get(key):report['failures'].append(obj.name+': '+key)
 report['meshes'].append(row)
report['machine_preflight_passed']=not report['failures']
output.write_text(json.dumps(report,indent=2))
print('ART_PREFLIGHT',json.dumps(report),flush=True)
if report['failures']:raise RuntimeError('Authoring contract incomplete; see report')
