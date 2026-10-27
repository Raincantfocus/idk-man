import bpy,json,numpy as np
from pathlib import Path
root=Path('/workspace/map-intake')
for name,path in [('killhouse',root/'killhouse/scene.gltf'),('warehouse',Path('/workspace/attachments/b08da96f-4bc3-46d2-a7e0-2a004e3d0dc7/warehouse_fbx_model_free.glb'))]:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(path))
 rows=[];arrays={}
 for obj in bpy.context.scene.objects:
  if obj.type!='MESH':continue
  m=obj.data;m.calc_loop_triangles()
  # Blender Z-up -> Godot Y-up, retaining imported glTF transforms.
  v=np.array([(obj.matrix_world@p.co)[:] for p in m.vertices]);v=v[:,[0,2,1]];v[:,2]*=-1
  f=np.array([t.vertices[:] for t in m.loop_triangles]);key='mesh'+str(len(rows));arrays[key+'_v']=v;arrays[key+'_f']=f
  rows.append({'name':obj.name,'key':key,'triangles':len(f),'min':v.min(0).tolist(),'max':v.max(0).tolist(),'size':np.ptp(v,axis=0).tolist(),'materials':[s.material.name if s.material else None for s in obj.material_slots]})
 (root/(name+'.json')).write_text(json.dumps(rows,indent=2));np.savez_compressed(root/(name+'.npz'),**arrays)
 print(name,[(r['name'],r['triangles'],[round(x,3) for x in r['size']]) for r in rows],flush=True)
