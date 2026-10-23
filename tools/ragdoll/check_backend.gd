extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var a:=RigidBody3D.new();var b:=RigidBody3D.new();root.add_child(a);root.add_child(b)
 var joint: RID=PhysicsServer3D.joint_create();var rows: Array=[]
 PhysicsServer3D.joint_make_cone_twist(joint,a.get_rid(),Transform3D.IDENTITY,b.get_rid(),Transform3D.IDENTITY)
 for entry: Array in [["CONE_TWIST_JOINT_SWING_SPAN",.6],["CONE_TWIST_JOINT_TWIST_SPAN",.4],["CONE_TWIST_JOINT_BIAS",.9],["CONE_TWIST_JOINT_SOFTNESS",.2],["CONE_TWIST_JOINT_RELAXATION",.5]]:
  assert(ClassDB.class_has_integer_constant("PhysicsServer3D",entry[0]))
  var parameter: int=ClassDB.class_get_integer_constant("PhysicsServer3D",entry[0])
  PhysicsServer3D.cone_twist_joint_set_param(joint,parameter,entry[1]);var actual: float=PhysicsServer3D.cone_twist_joint_get_param(joint,parameter)
  rows.append({"property":entry[0],"set":entry[1],"read":actual,"honored":is_equal_approx(actual,float(entry[1]))})
 PhysicsServer3D.joint_make_hinge(joint,a.get_rid(),Transform3D.IDENTITY,b.get_rid(),Transform3D.IDENTITY)
 for entry: Array in [["HINGE_JOINT_LIMIT_LOWER",-.1],["HINGE_JOINT_LIMIT_UPPER",2.4],["HINGE_JOINT_BIAS",.9],["HINGE_JOINT_LIMIT_BIAS",.9],["HINGE_JOINT_LIMIT_SOFTNESS",.2],["HINGE_JOINT_LIMIT_RELAXATION",.5]]:
  assert(ClassDB.class_has_integer_constant("PhysicsServer3D",entry[0]))
  var parameter: int=ClassDB.class_get_integer_constant("PhysicsServer3D",entry[0])
  PhysicsServer3D.hinge_joint_set_param(joint,parameter,entry[1]);var actual: float=PhysicsServer3D.hinge_joint_get_param(joint,parameter)
  rows.append({"property":entry[0],"set":entry[1],"read":actual,"honored":is_equal_approx(actual,float(entry[1]))})
 PhysicsServer3D.free_rid(joint);a.free();b.free()
 var file:=FileAccess.open("res://data/ragdoll/backend_audit.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"backend":ProjectSettings.get_setting("physics/3d/physics_engine"),"tests":rows},"  "));file.close();print("BACKEND_AUDIT_COMPLETE");quit()
