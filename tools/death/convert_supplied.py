"""Audit supplied FBX and export death/flinch/strafe source keys without mesh art."""
import bpy,json,sys,re,hashlib
from pathlib import Path
args=sys.argv[sys.argv.index('--')+1:];source=Path(args[0]);out=Path(args[1]);out.mkdir(parents=True,exist_ok=True);rows=[]
for path in sorted(source.rglob('*.fbx')):
 if not any(x in path.stem.lower() for x in ['death','hit reaction']) and path.name!='Strafe.fbx':continue
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(path),automatic_bone_orientation=False)
 rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
 ident=re.sub('[^a-z0-9]+','_',str(path.relative_to(source).with_suffix('')).lower()).strip('_')
 if not rigs or not rigs[0].animation_data or not rigs[0].animation_data.action:
  rows.append({'id':ident,'source':str(path.relative_to(source)),'usable':False,'reason':'No armature/action'});continue
 rig=rigs[0];action=rig.animation_data.action;action.name=ident;fps=bpy.context.scene.render.fps/bpy.context.scene.render.fps_base
 start,end=action.frame_range;bpy.context.scene.frame_start=int(start);bpy.context.scene.frame_end=int(end)
 bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
 bpy.ops.export_scene.gltf(filepath=str(out/(ident+'.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=True,export_frame_step=1,export_def_bones=False,export_skins=True,export_yup=True)
 rows.append({'id':ident,'file':ident+'.glb','source':str(path.relative_to(source)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'seconds':(end-start)/fps,'fps':fps,'source_bones':len(rig.data.bones),'bone_names':[b.name for b in rig.data.bones],'usable':True,'flying':'flying' in ident,'death':'death' in ident,'loop':False})
 print('CONVERTED',ident,flush=True)
(out/'source_manifest.json').write_text(json.dumps({'clips':rows,'source_inventory':[str(p.relative_to(source)) for p in sorted(source.rglob('*.fbx'))],'blender':bpy.app.version_string},indent=2))
