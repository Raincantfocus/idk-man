import shutil,sys
from pathlib import Path
repo=Path(__file__).resolve().parents[2];out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
for folder in ['scripts/animation','tools/animation','data/animation']:
 (out/folder).mkdir(parents=True,exist_ok=True)
 for f in (repo/folder).glob('*'):
  if f.is_file() and f.suffix in ['.gd','.py','.json','.tres']:shutil.copy(f,out/folder/f.name)
(out/'models').mkdir(exist_ok=True)
shutil.copy(repo/'assets/characters/generated/standard_lod0.glb',out/'models/body.glb')
shutil.copy('/workspace/private-soldier-intake/converted/modular_fatigues/fatigues_standard_lod0.glb',out/'models/fatigues.glb')
shutil.copy('/workspace/private-soldier-intake/converted/modular_carrier/parts/complete_kit.glb',out/'models/carrier.glb')
shutil.copy(repo/'data/characters/humanoid_bone_map.tres',out/'data/animation/target_bone_map.tres')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="ZERO LINE Animation Integration Review"\nrun/main_scene="res://review.tscn"\n[display]\nwindow/size/viewport_width=1000\nwindow/size/viewport_height=900\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n[physics]\n3d/physics_engine="Jolt Physics"\n')
(out/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://tools/animation/animation_review.gd" id="1"]\n[node name="AnimationReview" type="Node3D"]\nscript=ExtResource("1")\n')

for kind in ['fatigues','carrier']:
 for suffix in ['albedo','normal','orm']:
  name=kind+'_'+suffix+'.png';shutil.copy('/workspace/private-soldier-intake/converted/modular_'+kind+'/'+name,out/'models'/name)
