"""Create kit-specific LOD copies; retain original unmasked LODs for reveal states."""
import bpy,json,sys
from pathlib import Path
from mathutils import Vector
from mathutils.kdtree import KDTree
args=sys.argv[sys.argv.index('--')+1:];patch=json.loads(Path(args[0]).read_text());source=Path(args[1]);out=Path(args[2]);out.mkdir(parents=True,exist_ok=True)
body=patch['meshes']['Body_LOD0'];kd=KDTree(len(body['v']))
for i,p in enumerate(body['v']):kd.insert(Vector((p[0],-p[2],p[1])),i)
kd.balance();rows=[]
for lod in [1,2,3]:
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(source/f'standard_lod{lod}.glb'))
 before=after=0
 for obj in list(bpy.context.scene.objects):
  if obj.type!='MESH':continue
  mesh=obj.data;mesh.calc_loop_triangles();before+=len(mesh.loop_triangles)
  import bmesh
  bm=bmesh.new();bm.from_mesh(mesh);bm.verts.ensure_lookup_table();remove=[]
  for face in bm.faces:
   hidden=True
   for v in face.verts:
    _,i,d=kd.find(obj.matrix_world@v.co)
    if d>.02 or not body['covered'][i] or body['protected'][i]:hidden=False;break
   if hidden:remove.append(face)
  bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(mesh);bm.free();mesh.calc_loop_triangles();after+=len(mesh.loop_triangles)
 bpy.ops.export_scene.gltf(filepath=str(out/f'covered_lod{lod}.glb'),export_format='GLB',export_animations=False)
 rows.append({'lod':lod,'before_triangles':before,'after_triangles':after,'saved_triangles':before-after})
(out/'lod_report.json').write_text(json.dumps({'rows':rows,'policy':'Kit-specific review copies only. Swap to retained unmasked LOD when reveal is requested; removed faces cannot be restored by a shader. No torn garment states certified.'},indent=2));print(rows)
