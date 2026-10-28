"""Blender 5: script EXPORTED_GLB OUTPUT_NPZ OUTPUT_JSON."""
import bpy,numpy as np,json,sys
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=sys.argv[1]);arrays={};rows=[]
for obj in bpy.context.scene.objects:
 if obj.type!='MESH':continue
 obj.data.calc_loop_triangles();v=np.array([(obj.matrix_world@p.co)[:] for p in obj.data.vertices]);v=v[:,[0,2,1]];v[:,2]*=-1;f=np.array([t.vertices[:] for t in obj.data.loop_triangles]);key='m'+str(len(rows));arrays[key+'_v']=v;arrays[key+'_f']=f;rows.append({'name':obj.name,'key':key,'tris':len(f),'min':v.min(0).tolist(),'max':v.max(0).tolist()})
np.savez_compressed(sys.argv[2],**arrays);open(sys.argv[3],'w').write(json.dumps(rows,indent=2))
