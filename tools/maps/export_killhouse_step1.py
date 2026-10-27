"""Apply prepared vertex coordinates to imported source meshes and export a review GLB.
Run with Blender 5 bpy Python: script SOURCE.gltf ARRAYS.npz OUTPUT.glb
"""
import bpy,sys,numpy as np
from mathutils import Matrix
source,arrays,destination=sys.argv[1:4]
bpy.context.preferences.filepaths.use_scripts_auto_execute=False
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=source)
data=np.load(arrays);objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for obj in objects:
 coords=data[obj.name+'_v'];assert len(coords)==len(obj.data.vertices)
 obj.parent=None;obj.matrix_world=Matrix.Identity(4)
 for vertex,p in zip(obj.data.vertices,coords):vertex.co=(float(p[0]),float(-p[2]),float(p[1]))
 obj.data.update();obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=destination,export_format='GLB',use_selection=True,export_yup=True)
# Carry attribution inside the derivative GLB as well as its adjacent README.
import struct,json
path=__import__('pathlib').Path(destination);raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0];document=json.loads(raw[20:20+length])
document['asset']['copyright']='Killhouse by _.quve, CC-BY-4.0; https://sketchfab.com/3d-models/killhouse-a2ce333ba32548d5b454131f6016c961 . ZERO-LINE derivative: scale/orientation, partition/door edits, prop sizing. Original retained separately.'
meta=json.dumps(document,separators=(',',':')).encode();meta+=b' '*((-len(meta))%4);tail=raw[20+length:]
path.write_bytes(struct.pack('<III',0x46546c67,2,20+len(meta)+len(tail))+struct.pack('<II',len(meta),0x4e4f534a)+meta+tail)
print('STEP1_EXPORT',destination,flush=True)
