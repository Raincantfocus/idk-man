extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var args: PackedStringArray=OS.get_cmdline_user_args()
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 var patch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[1]))
 var viewer: Node=(load("res://baseline_review.tscn") as PackedScene).instantiate();root.add_child(viewer);viewer.set_process(false)
 var meshes: Dictionary=preload("res://scripts/clipping/apply_patch.gd").apply(viewer.model_root,patch)
 for mesh: MeshInstance3D in meshes.values():
  assert(mesh.mesh.blend_shape_mode==Mesh.BLEND_SHAPE_MODE_NORMALIZED)
 var driver=preload("res://scripts/clipping/corrective_driver.gd").new();driver.configure(viewer.skeleton,meshes,patch)
 var rows: Array=[]
 for clip: Dictionary in data.clips:
  viewer.controller.preview_clip(StringName(clip.name))
  for index: int in range(0,clip.samples.size(),30):
   var sample: Dictionary=clip.samples[index];viewer.controller.player.seek(float(sample.time),true);viewer.skeleton.force_update_all_bone_transforms();driver.advance(4.0)
   var weights: Dictionary={}
   for rule: Dictionary in patch.corrective_rules:
    var mesh: MeshInstance3D=meshes.Body_LOD0;weights[rule.name]=mesh.get_blend_shape_value(mesh.find_blend_shape_by_name(rule.name))
   rows.append({"clip":clip.name,"frame":sample.frame,"weights":weights})
 driver.advance(8.01)
 for mesh: MeshInstance3D in meshes.values():
  for i: int in mesh.get_blend_shape_count():assert(mesh.get_blend_shape_value(i)==0.0)
 var file:=FileAccess.open(args[2],FileAccess.WRITE);file.store_string(JSON.stringify(rows));file.close()
 print("NATIVE_CORRECTIVE_SAMPLES ",rows.size()," FAR_RESET_PASS");quit()
