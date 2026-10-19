"""Stage code/config beside the generated private art without duplicating assets."""
import shutil,sys
from pathlib import Path
repo=Path(__file__).resolve().parents[2];out=Path(sys.argv[1]).resolve()
assert not out.is_relative_to(repo)
for folder in ['scripts/trauma','data/trauma']:
 (out/folder).mkdir(parents=True,exist_ok=True)
 for f in (repo/folder).glob('*'):
  if f.is_file() and not f.name.endswith('.uid'):shutil.copy(f,out/folder/f.name)
for name in ['neck_review.gd','capture_neck_review.gd']:shutil.copy(repo/'tools/trauma'/name,out/name)
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="ZERO LINE Neck Rework Review"\nrun/main_scene="res://review.tscn"\n[display]\nwindow/size/viewport_width=1000\nwindow/size/viewport_height=900\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n[physics]\n3d/physics_engine="Jolt Physics"\n')
(out/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://neck_review.gd" id="1"]\n[node name="NeckReview" type="Node3D"]\nscript=ExtResource("1")\n')
print('STAGED',out)
