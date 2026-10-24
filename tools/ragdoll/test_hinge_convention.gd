extends SceneTree
## Actual native Jolt behavior, not merely parameter readback.
func _initialize() -> void:call_deferred("run")
func run() -> void:
 assert(ProjectSettings.get_setting("physics/3d/physics_engine")=="Jolt Physics")
 for method: String in ["joint_create","joint_make_hinge","hinge_joint_set_flag","hinge_joint_set_param","free_rid"]:
  assert(ClassDB.class_has_method("PhysicsServer3D",method),method)
 var results: Array=[]
 for limits: Vector2 in [Vector2(-5,145),Vector2(0,140)]:
  for flexion: float in [-60.0,60.0,120.0,170.0]:
   var anchor:=StaticBody3D.new();root.add_child(anchor);anchor.collision_layer=0
   var limb:=RigidBody3D.new();root.add_child(limb);limb.gravity_scale=0;limb.collision_layer=0;limb.collision_mask=0
   # Godot's hinge flexion is the negative B-relative-to-A Z rotation.
   limb.rotation.z=deg_to_rad(-flexion)
   var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();limb.add_child(shape)
   var joint: RID=PhysicsServer3D.joint_create()
   PhysicsServer3D.joint_make_hinge(joint,anchor.get_rid(),Transform3D.IDENTITY,limb.get_rid(),Transform3D.IDENTITY)
   PhysicsServer3D.hinge_joint_set_flag(joint,PhysicsServer3D.HINGE_JOINT_FLAG_USE_LIMIT,true)
   PhysicsServer3D.hinge_joint_set_param(joint,PhysicsServer3D.HINGE_JOINT_LIMIT_LOWER,deg_to_rad(limits.x))
   PhysicsServer3D.hinge_joint_set_param(joint,PhysicsServer3D.HINGE_JOINT_LIMIT_UPPER,deg_to_rad(limits.y))
   for frame: int in 60:await physics_frame
   var measured: float=-limb.rotation_degrees.z
   var passed: bool=measured>=limits.x-.1 and measured<=limits.y+.1
   if flexion>=limits.x and flexion<=limits.y:passed=passed and absf(measured-flexion)<.1
   results.append({"lower":limits.x,"upper":limits.y,"initial_flexion_degrees":flexion,"final_flexion_degrees":measured,"pass":passed})
   PhysicsServer3D.free_rid(joint);anchor.free();limb.free()
   assert(passed,JSON.stringify(results.back()))
 var report: Dictionary={"engine":Engine.get_version_info().string,"backend":"Jolt Physics","cases":results}
 var file:=FileAccess.open("res://data/ragdoll/hinge_convention_report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("HINGE_CONVENTION_PASS ",JSON.stringify(report));quit()
