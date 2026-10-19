extends SceneTree
func _initialize() -> void:
 for pair: Array in [["ArrayMesh","add_blend_shape"],["ArrayMesh","add_surface_from_arrays"],["MeshInstance3D","set_blend_shape_value"],["GeometryInstance3D","set_instance_shader_parameter"],["Skeleton3D","get_bone_pose_rotation"],["MeshInstance3D","find_blend_shape_by_name"]]:
  assert(ClassDB.class_has_method(pair[0],pair[1]),str(pair))
 var script: Script=load("res://scripts/clipping/apply_patch.gd")
 assert(script.can_instantiate())
 print("CLIPPING_API_CHECK_PASS ",Engine.get_version_info().string)
 quit()
