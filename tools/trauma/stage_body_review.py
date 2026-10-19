"""Stage standalone review, keeping derived assets outside the checkout."""
import shutil,sys
from pathlib import Path
root=Path(__file__).resolve().parents[2];out=Path(sys.argv[1]).resolve();assert not out.is_relative_to(root)
for folder in ['scripts/trauma','data/trauma','tools/trauma']:
 (out/folder).mkdir(parents=True,exist_ok=True)
 for source in (root/folder).glob('*'):
  if source.is_file() and source.suffix!='.uid':shutil.copy(source,out/folder/source.name)
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="ZERO LINE Body Cut Review"\nrun/main_scene="res://review.tscn"\n[display]\nwindow/size/viewport_width=1000\nwindow/size/viewport_height=900\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n[physics]\n3d/physics_engine="Jolt Physics"\n')
(out/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://tools/trauma/body_review.gd" id="1"]\n[node name="BodyReview" type="Node3D"]\nscript=ExtResource("1")\n')
