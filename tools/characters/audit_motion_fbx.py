"""Blender 4.x: metadata audit only; does not retarget or modify source files.
blender -b --disable-autoexec --python tools/characters/audit_motion_fbx.py -- PRIVATE_ROOT
"""
import bpy, json, sys, hashlib
from pathlib import Path
root=Path(sys.argv[sys.argv.index('--')+1]).resolve()
repo=Path(__file__).resolve().parents[2]
if root.is_relative_to(repo): raise SystemExit('Use a private directory outside the repository')
report={'schema':1,'blender':bpy.app.version_string,'files':[], 'note':'Frame rate is Blender import scene rate; sampled hip displacement is not a root-motion certification.'}
for path in sorted(root.rglob('*.fbx')):
 bpy.ops.wm.read_factory_settings(use_empty=True)
 entry={'path':str(path.relative_to(root)), 'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
 try:
  bpy.ops.import_scene.fbx(filepath=str(path),use_anim=True)
  entry['fps']=bpy.context.scene.render.fps/bpy.context.scene.render.fps_base
  entry['rigs']=[{'name':o.name,'bones':[b.name for b in o.data.bones], 'bone_count':len(o.data.bones)} for o in bpy.data.objects if o.type=='ARMATURE']
  entry['meshes']=[{'name':o.name,'triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'materials':len(o.data.materials)} for o in bpy.data.objects if o.type=='MESH']
  entry['actions']=[{'name':a.name,'frame_start':float(a.frame_range[0]),'frame_end':float(a.frame_range[1]),'duration_seconds':float(a.frame_range[1]-a.frame_range[0])/entry['fps'],'fcurves':len(a.fcurves)} for a in bpy.data.actions]
  entry['status']='imported'
 except Exception as e: entry.update(status='failed',error=str(e))
 report['files'].append(entry)
 (root/'fbx_audit.json').write_text(json.dumps(report,indent=2))
 print('AUDITED',entry['path'],entry['status'],flush=True)
print('AUDIT_COMPLETE',len(report['files']),flush=True)
