"""Render four actual Blender reference frames from the generated authoring file."""
import bpy,sys,math
from pathlib import Path
from mathutils import Vector
out=Path(sys.argv[sys.argv.index('--')+1]);out.mkdir(exist_ok=True,parents=True)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=False
scene.render.resolution_x=768;scene.render.resolution_y=768;scene.render.resolution_percentage=100
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.17,.17,.17,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
for o in scene.objects:o.hide_render=True
camera_data=bpy.data.cameras.new('NeckReviewCamera');camera=bpy.data.objects.new('NeckReviewCamera',camera_data);scene.collection.objects.link(camera);scene.camera=camera
camera.location=(0,-.35,.35);camera.rotation_euler=(Vector()-camera.location).to_track_quat('-Z','Y').to_euler();camera_data.lens=48
for name,pos,power,size in [('Key',(-.4,-.3,.6),25,.3),('Fill',(.4,.2,.4),10,.4)]:
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size
 light=bpy.data.objects.new(name,data);scene.collection.objects.link(light);light.location=pos;light.rotation_euler=(Vector()-light.location).to_track_quat('-Z','Y').to_euler()
for weapon in ['melee','rifle','shotgun','explosive']:
 obj=bpy.data.objects['neck_'+weapon+'_0_LOD0'];obj.hide_render=False
 scene.render.filepath=str(out/(weapon+'_blender.png'));bpy.ops.render.render(write_still=True);obj.hide_render=True
print('BLENDER_NECK_CAPTURES 4')
