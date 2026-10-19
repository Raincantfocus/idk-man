"""Blender 4.3.2 FBX → neutral glTF animation sources, preserving authored keys."""
import bpy,sys,json,hashlib
from pathlib import Path
root=Path(__file__).resolve().parents[2];source=Path(sys.argv[sys.argv.index('--')+1]);out=Path(sys.argv[sys.argv.index('--')+2]);out.mkdir(parents=True,exist_ok=True)
assert not out.resolve().is_relative_to(root)
clips=[]
for path in sorted(source.glob('Actorcore-*/Motion/**/*.fbx')):
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.fbx(filepath=str(path),automatic_bone_orientation=False)
 rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');action=rig.animation_data.action
 stem=path.stem
 ident='run_loop' if 'fastrun_forward_loop' in stem else 'run_start' if 'fastrun_forward_start' in stem else 'run_stop' if 'fastrun_forward_end' in stem else 'fire' if 'hold_gun_shooting' in stem else 'reload_cover' if 'reload' in stem else 'turn_left' if 'turn180' in stem else 'turn_right' if 'turn90' in stem else 'side_shoot'
 action.name=ident
 bpy.context.scene.frame_start=int(action.frame_range[0]);bpy.context.scene.frame_end=int(action.frame_range[1]);bpy.context.scene.render.fps=60
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
 bpy.ops.export_scene.gltf(filepath=str(out/(ident+'.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=True,export_frame_step=1,export_def_bones=False,export_skins=True,export_yup=True)
 clips.append({'id':ident,'source':str(path.relative_to(source)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'seconds':(action.frame_range[1]-action.frame_range[0])/60,'source_bones':len(rig.data.bones),'file':ident+'.glb','loop':ident=='run_loop'})
(out/'source_manifest.json').write_text(json.dumps({'clips':clips,'blender':bpy.app.version_string},indent=2))
print('CONVERTED',len(clips),flush=True)
