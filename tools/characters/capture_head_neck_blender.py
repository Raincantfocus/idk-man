"""Blender native Cycles CPU static review, no synthetic replacement images.
-b --disable-autoexec AUTHORING.blend -P THIS -- PRIVATE_OUTPUT
"""
import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector
out=Path(sys.argv[sys.argv.index('--')+1]).resolve();out.mkdir(parents=True,exist_ok=True)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=8;scene.cycles.use_denoising=False
scene.render.resolution_x=512;scene.render.resolution_y=512;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.threads_mode='FIXED';scene.render.threads=2
scene.world=bpy.data.worlds.new('HN_ReviewWorld');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.14,.17,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
camera_data=bpy.data.cameras.new('HN_ReviewCamera');camera=bpy.data.objects.new('HN_ReviewCamera',camera_data);scene.collection.objects.link(camera);scene.camera=camera;camera_data.lens=42
for name,position,power,size in [('Key',(1,-2,3),100,.8),('Fill',(-1,1,2.5),70,1.0)]:
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size
 obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj);obj.location=position;obj.rotation_euler=(Vector((0,0,1.7))-obj.location).to_track_quat('-Z','Y').to_euler()
source=bpy.data.objects['HN_intact'];original=source.data.materials[0]
bruise=original.copy();bruise.name='HN_review_bruise';nodes=bruise.node_tree.nodes;links=bruise.node_tree.links;bsdf=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
prior=bsdf.inputs['Base Color'].links[0].from_socket
uv=nodes.new('ShaderNodeUVMap');uv.uv_map='WoundUV';sep=nodes.new('ShaderNodeSeparateXYZ');links.new(uv.outputs[0],sep.inputs[0])
subtract=nodes.new('ShaderNodeMath');subtract.operation='SUBTRACT';subtract.inputs[1].default_value=.5;links.new(sep.outputs['Y'],subtract.inputs[0])
absolute=nodes.new('ShaderNodeMath');absolute.operation='ABSOLUTE';links.new(subtract.outputs[0],absolute.inputs[0])
remap=nodes.new('ShaderNodeMapRange');remap.inputs['From Min'].default_value=.035;remap.inputs['From Max'].default_value=.13;remap.inputs['To Min'].default_value=.65;remap.inputs['To Max'].default_value=0;links.new(absolute.outputs[0],remap.inputs[0])
mix=nodes.new('ShaderNodeMixRGB');links.new(remap.outputs[0],mix.inputs[0]);links.new(prior,mix.inputs[1]);mix.inputs[2].default_value=(.16,.018,.028,1);links.new(mix.outputs[0],bsdf.inputs['Base Color'])
views={'front':(0,-.84,1.73),'side':(.84,-.08,1.73),'back':(0,.76,1.73)}
captures=[]
for state,variant in [(name,0) for name in ['intact','damaged','fractured_closed','fractured_open','detached']]+[(name,variant) for variant in [1,2] for name in ['fractured_open','detached']]:
 for obj in bpy.data.objects:
  if obj.type=='MESH':obj.hide_render=True;obj.location=(0,0,0)
 source.data.materials[0]=bruise if state=='damaged' else original
 source.data.shape_keys.key_blocks['fractured_closed'].value=1 if state=='fractured_closed' else 0
 if state in ['intact','damaged','fractured_closed']:source.hide_render=False
 else:
  head=bpy.data.objects[f'HN_head_v{variant}'];stump=bpy.data.objects[f'HN_stump_v{variant}'];head.hide_render=False;stump.hide_render=False
  head.location=(0,0,.025) if state=='fractured_open' else (.055,0,.075)
 for view,position in views.items():
  camera.location=position;camera.rotation_euler=(Vector((0,-.06,1.71))-camera.location).to_track_quat('-Z','Y').to_euler()
  suffix=f'_v{variant}' if variant else '';path=out/f'{state}{suffix}_{view}.png';scene.render.filepath=str(path);bpy.ops.render.render(write_still=True)
  captures.append(path.name)
for obj in bpy.data.objects:
 if obj.type=='MESH':obj.hide_render=obj.name=='HN_intact' or obj.name.startswith(('HN_head_v','HN_stump_v'))
for view,position in views.items():
 camera.location=position;camera.rotation_euler=(Vector((0,-.06,1.71))-camera.location).to_track_quat('-Z','Y').to_euler()
 path=out/f'interiors_{view}.png';scene.render.filepath=str(path);bpy.ops.render.render(write_still=True);captures.append(path.name)
(out/'captures.json').write_text(json.dumps({'renderer':'Blender Cycles CPU, 8 samples','captures':captures,'visual_approval':False},indent=2))
print('HEAD_NECK_BLENDER_CAPTURES',len(captures),flush=True)
