"""Read-only neutral-light intake render using Blender 5 bpy; no source scripts run.
Usage: python render_intake_blend.py SOURCE.blend OUTPUT.png
Source units are interpreted as centimeters for this review only; originals unchanged.
"""
import bpy,sys
from mathutils import Vector
source,output=sys.argv[1:3]
bpy.context.preferences.filepaths.use_scripts_auto_execute=False
bpy.ops.wm.open_mainfile(filepath=source,use_scripts=False,load_ui=False)
scene=bpy.context.scene
root=bpy.data.objects.new('IntakeCentimeterConversion',None);scene.collection.objects.link(root)
for obj in list(scene.objects):
 if obj!=root and obj.parent is None and obj.type in {'MESH','ARMATURE'}:obj.parent=root
root.scale=(.01,)*3
for obj in scene.objects:
 if obj.type=='LIGHT':obj.hide_render=True
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=12;scene.cycles.use_denoising=True
scene.render.resolution_x=640;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=output
scene.render.film_transparent=False
scene.world=bpy.data.worlds.new('IntakeNeutralWorld');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.12,.12,.12,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.35
bpy.ops.object.camera_add(location=(2.6,-4.5,2.1));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,1.0))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=2.3;scene.camera=camera
for name,pos,power,size in [('Key',(2,-3,4),900,3),('Fill',(-3,-1,2),500,3),('Rim',(0,3,3),1000,2)]:
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size
 light=bpy.data.objects.new(name,data);scene.collection.objects.link(light);light.location=pos;light.rotation_euler=(Vector((0,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
scene.view_settings.view_transform='AgX';scene.view_settings.exposure=0
bpy.ops.render.render(write_still=True)
print('INTAKE_RENDER',output,flush=True)
