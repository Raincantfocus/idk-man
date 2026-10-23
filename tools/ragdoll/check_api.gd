extends SceneTree
func _initialize() -> void:
 var b:=PhysicalBone3D.new()
 for p: String in ["gravity_scale","friction","bounce","linear_damp","angular_damp","joint_rotation","body_offset"]:
  assert(b.get_property_list().any(func(row:Dictionary)->bool:return row.name==p),p)
 b.joint_type=PhysicalBone3D.JOINT_TYPE_HINGE
 for p: String in ["joint_constraints/angular_limit_enabled","joint_constraints/angular_limit_upper","joint_constraints/angular_limit_lower"]:
  assert(b.get_property_list().any(func(row:Dictionary)->bool:return row.name==p),p)
 assert(ClassDB.class_has_method("PhysicsBody3D","remove_collision_exception_with"))
 print("RAGDOLL_API_VERIFIED ",Engine.get_version_info().string);b.free();quit()
