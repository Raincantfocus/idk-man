"""Blender 5 bpy CPU preview of the exported review GLB, not a game screenshot."""
import bpy,sys,math,json
from mathutils import Vector
source,destination,report_path=sys.argv[1:4]
bpy.context.preferences.filepaths.use_scripts_auto_execute=False
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=source)
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];triangles=0
for o in meshes:o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles)
from pathlib import Path
Path(report_path).write_text(json.dumps({'reimported_meshes':len(meshes),'reimported_triangles':triangles,'blender':bpy.app.version_string},indent=2)+'\n')
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=16;scene.cycles.use_denoising=True
scene.render.resolution_x=1400;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.22,.24,.27,1);scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.5
bpy.ops.object.camera_add(location=(20,-26,28));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,1))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=33;scene.camera=camera
bpy.ops.object.light_add(type='SUN',location=(10,-10,20));sun=bpy.context.object;sun.rotation_euler=(math.radians(25),math.radians(-20),math.radians(-25));sun.data.energy=2;sun.data.angle=.1
scene.render.filepath=destination;scene.render.image_settings.file_format='PNG';bpy.ops.render.render(write_still=True)
print('STEP1_RENDER',triangles,destination,flush=True)
