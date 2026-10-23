extends "res://scripts/death/death_actor.gd"
## Experimental presentation rig. Never emits gameplay deaths or rewards.
var definitions: Dictionary={}
var guard_ticks: Dictionary={}
var boost_ticks: Dictionary={}
var last_valid_pose: Array[Transform3D]=[]
var last_valid_bodies: Dictionary={}
var joint_metrics: Dictionary={}
var worst_pose: Array[Transform3D]=[]
var worst_joint_metrics: Dictionary={}
var worst_separation: float=-1.0
var incoming_pose: Array[Transform3D]=[]
var incoming_bodies: Dictionary={}
var snapshot_joint_error: float=0.0
var max_angle_error: float=0.0
var max_body_speed: float=0.0
var max_body_spin: float=0.0
var guard_freezes: int=0
var guard_missing_snapshot: int=0
var guard_cpu_us: int=0
var guard_frames: int=0
var excluded_pairs: Array=[]
var hit_position:=Vector3.ZERO
func _build_bodies() -> void:
 for definition: Dictionary in tuning.bones:definitions[String(definition.name)]=definition
 super._build_bodies()
 for name: String in physical:
  var body: PhysicalBone3D=physical[name]
  body.mass=float(definitions[name].base_mass)+float(tuning.roles[tuning.mass_role].get(name,0.0))
  body.gravity_scale=float(tuning.gravity_scale);body.friction=float(tuning.friction);body.bounce=float(tuning.bounce)
  if definitions[name].get("shape_kind","")=="box":
   var shape:=BoxShape3D.new();var size: Array=definitions[name].box_size_m;shape.size=Vector3(float(size[0]),float(size[1]),float(size[2]));(body.get_child(0) as CollisionShape3D).shape=shape
  if name=="Head":
   var shape:=SphereShape3D.new();shape.radius=float(definitions[name].radius);(body.get_child(0) as CollisionShape3D).shape=shape
 _collision_pairs()
func _parent_name(name: String) -> String:
 var parent: int=skeleton.get_bone_parent(skeleton.find_bone(name))
 while parent>=0:
  var candidate: String=skeleton.get_bone_name(parent)
  if physical.has(candidate):return candidate
  parent=skeleton.get_bone_parent(parent)
 return ""
func _collision_pairs() -> void:
 excluded_pairs.clear()
 for name: String in physical:
  for other: String in physical:
   if name==other:continue
   physical[name].remove_collision_exception_with(physical[other])
   if _parent_name(name)==other or _parent_name(other)==name:
    physical[name].add_collision_exception_with(physical[other])
    if name<other:excluded_pairs.append([name,other])
func _handoff(trigger: String) -> void:
 if handoff_count>0:return
 # The base class owns event idempotence, root motion and the budget fallback.
 # Do not apply its mass-only impulse; distribute once below with distance weights.
 var impulse: Vector3=hit_impulse;hit_impulse=Vector3.ZERO
 super._handoff(trigger)
 _collision_pairs()
 var captured: Dictionary={}
 for name: String in physical:captured[name]=physical[name].global_transform
 _configure_joint_frames(captured)
 var weights: Dictionary={};var total: float=0.0
 for name: String in physical:
  var body: PhysicalBone3D=physical[name];body.global_transform=captured[name]
  body.linear_velocity=body.linear_velocity.limit_length(float(tuning.transfer.linear_cap));body.angular_velocity=body.angular_velocity.limit_length(float(tuning.transfer.angular_cap))
  var weight: float=body.mass/maxf(body.global_position.distance_to(hit_position),float(tuning.transfer.distance_floor_m));weights[name]=weight;total+=weight
 for name: String in physical:
  var body: PhysicalBone3D=physical[name]
  body.apply_central_impulse((impulse*(float(weights[name])/maxf(total,.001))).limit_length(body.mass*float(tuning.transfer.delta_v_cap)))
 incoming_pose=capture_pose();incoming_bodies=captured.duplicate()
 _sample_guard(false)
func _configure_joint_frames(captured: Dictionary) -> void:
 joint_links.clear()
 for name: String in physical:
  var parent_name: String=_parent_name(name)
  if parent_name.is_empty():continue
  var body: PhysicalBone3D=physical[name];var parent: PhysicalBone3D=physical[parent_name]
  var child_pose: Transform3D=captured[name];var parent_pose: Transform3D=captured[parent_name]
  var definition: Dictionary=definitions[name]
  var pivot: Vector3=child_pose*body.body_offset.affine_inverse().origin
  var world_a: Basis;var world_b: Basis
  if definition.joint_kind=="hinge":
   var upper: Vector3=parent_pose.basis.y.normalized();var lower: Vector3=child_pose.basis.y.normalized()
   var normal: Vector3=upper.cross(lower)
   if normal.length()<.001:normal=upper.cross(Vector3.FORWARD)
   if normal.length()<.001:normal=upper.cross(Vector3.RIGHT)
   normal=normal.normalized()
   world_a=Basis(upper,normal.cross(upper).normalized(),normal)
   world_b=Basis(lower,normal.cross(lower).normalized(),normal)
  else:
   var rest_parent: Transform3D=skeleton.get_bone_global_rest(skeleton.find_bone(parent_name))*parent.body_offset
   var rest_child: Transform3D=skeleton.get_bone_global_rest(skeleton.find_bone(name))*body.body_offset
   var neutral_axis: Vector3=Vector3.DOWN if name.ends_with("UpperArm") else rest_child.basis.y.normalized()
   var child_neutral:=Basis(Quaternion(Vector3.RIGHT,rest_child.basis.y.normalized()))
   var neutral:=Basis(Quaternion(rest_child.basis.y.normalized(),neutral_axis))*child_neutral
   world_a=parent_pose.basis*rest_parent.basis.inverse()*neutral
   world_b=child_pose.basis*rest_child.basis.inverse()*child_neutral
   world_a=world_a*Basis(Quaternion(Vector3.RIGHT,deg_to_rad(float(definition.get("neutral_twist_degrees",0.0)))))
  var local_a: Transform3D=parent_pose.affine_inverse()*Transform3D(world_a,pivot)
  var local_b: Transform3D=child_pose.affine_inverse()*Transform3D(world_b,pivot)
  body.joint_rotation=local_b.basis.get_euler()
  # Reload at coincident frames, then restore BEFORE physics advances. This
  # supplies Godot's derived parent frame without re-zeroing flexion at handoff.
  parent.global_transform=parent_pose
  body.global_transform=parent_pose*local_a*body.joint_offset.affine_inverse()
  body.joint_type=PhysicalBone3D.JOINT_TYPE_NONE
  if definition.joint_kind=="hinge":
   body.joint_type=PhysicalBone3D.JOINT_TYPE_HINGE
   body.set("joint_constraints/angular_limit_enabled",true)
   body.set("joint_constraints/angular_limit_lower",float(definition.lower_degrees))
   body.set("joint_constraints/angular_limit_upper",float(definition.upper_degrees))
  else:
   body.joint_type=PhysicalBone3D.JOINT_TYPE_CONE
   body.set("joint_constraints/swing_span",float(definition.swing));body.set("joint_constraints/twist_span",float(definition.twist))
  joint_links[name]={"parent":parent_name,"parent_anchor":local_a.origin,"child_anchor":body.joint_offset.origin,"parent_basis":local_a.basis,"child_basis":body.joint_offset.basis}
  body.global_transform=child_pose
func _angle_error(name: String, link: Dictionary) -> float:
 var a: Basis=physical[link.parent].global_basis*link.parent_basis
 var b: Basis=physical[name].global_basis*link.child_basis
 var relative: Basis=(a.inverse()*b).orthonormalized()
 var q: Quaternion=relative.get_rotation_quaternion()
 var definition: Dictionary=definitions[name]
 if definition.joint_kind=="hinge":
  var angle: float=wrapf(rad_to_deg(2.0*atan2(q.z,q.w)),-180.0,180.0)
  var off_axis: float=rad_to_deg(acos(clampf(relative.z.dot(Vector3.BACK),-1.0,1.0)))
  return maxf(off_axis,maxf(float(definition.lower_degrees)-angle,angle-float(definition.upper_degrees)))
 var swing: float=rad_to_deg(acos(clampf(relative.x.dot(Vector3.RIGHT),-1.0,1.0)))
 var twist: float=absf(wrapf(rad_to_deg(2.0*atan2(q.x,q.w)),-180.0,180.0))
 return maxf(0.0,maxf(swing-float(definition.swing),twist-float(definition.twist)))
func _physics_process(delta: float) -> void:
 super._physics_process(delta)
 if not is_simulating():return
 var curve: Dictionary=tuning.settle_curve
 var blend: float=clampf((handoff_elapsed-float(curve.start_seconds))/(float(curve.end_seconds)-float(curve.start_seconds)),0.0,1.0)
 for name: String in physical:
  var body: PhysicalBone3D=physical[name]
  body.linear_damp=lerpf(float(curve.linear_start),float(curve.linear_end),blend)
  body.angular_damp=lerpf(float(curve.angular_start),float(curve.angular_end),blend)
  if int(boost_ticks.get(name,0))>0:
   boost_ticks[name]=int(boost_ticks[name])-1;body.angular_damp=float(tuning.guard.boost_damping)
  max_body_speed=maxf(max_body_speed,body.linear_velocity.length());max_body_spin=maxf(max_body_spin,body.angular_velocity.length())
 _sample_guard(true)
func _sample_guard(enforce: bool) -> void:
 var begin: int=Time.get_ticks_usec();var valid: bool=true;var trigger: bool=false
 for name: String in joint_links:
  var link: Dictionary=joint_links[name];var child: PhysicalBone3D=physical[name];var parent: PhysicalBone3D=physical[link.parent]
  var separation: float=(parent.global_transform*link.parent_anchor).distance_to(child.global_transform*link.child_anchor)
  var angle: float=_angle_error(name,link);max_angle_error=maxf(max_angle_error,angle)
  joint_metrics[name]={"separation_m":separation,"angle_error_degrees":angle}
  valid=valid and separation<=float(tuning.guard.soft_m) and angle<=5.0
  if enforce and separation>float(tuning.guard.soft_m):
   boost_ticks[name]=int(tuning.guard.boost_ticks);boost_ticks[link.parent]=int(tuning.guard.boost_ticks)
   var center: Vector3=(child.linear_velocity*child.mass+parent.linear_velocity*parent.mass)/(child.mass+parent.mass)
   var relative: Vector3=(child.linear_velocity-parent.linear_velocity).limit_length(float(tuning.guard.relative_speed_cap))
   child.linear_velocity=center+relative*parent.mass/(child.mass+parent.mass)
   parent.linear_velocity=center-relative*child.mass/(child.mass+parent.mass)
  var bad: bool=separation>float(tuning.guard.hard_m) or angle>float(tuning.guard.angle_extra_degrees)
  guard_ticks[name]=int(guard_ticks.get(name,0))+1 if bad else 0
  trigger=trigger or int(guard_ticks[name])>=int(tuning.guard.consecutive_ticks)
 var current_separation: float=joint_error()
 if current_separation>worst_separation:
  worst_separation=current_separation;worst_pose=capture_pose();worst_joint_metrics=joint_metrics.duplicate(true)
 if valid:
  for name: String in points():
   if query.penetration(get_world_3d().direct_space_state,name,points()[name],excluded).length()>.02:valid=false;break
 if valid:
  last_valid_pose=capture_pose();snapshot_joint_error=joint_error();last_valid_bodies.clear()
  for name: String in physical:last_valid_bodies[name]=physical[name].global_transform
 if enforce and trigger:
  if last_valid_pose.is_empty():
   guard_missing_snapshot+=1
   last_valid_pose=incoming_pose;last_valid_bodies=incoming_bodies;snapshot_joint_error=0.0
   trace.append({"event":"invalid_initial_pose_rejected","acceptance_failure":true})
  _freeze_guard_snapshot()
 guard_cpu_us+=Time.get_ticks_usec()-begin;guard_frames+=1
func _freeze_guard_snapshot() -> void:
 # Emergency fallback follows the requested last-valid-pose rule, even in air.
 # It can visibly rewind; the stress report records this rather than hiding it.
 frozen_joint_error=snapshot_joint_error
 for name: String in physical:
  var bone: PhysicalBone3D=physical[name]
  var frozen:=StaticBody3D.new();frozen.collision_layer=int(tuning.corpse_layer);frozen.collision_mask=int(tuning.world_mask)|int(tuning.prop_mask);add_child(frozen);frozen.global_transform=last_valid_bodies[name]
  for child: Node in bone.get_children():
   if child is CollisionShape3D:
    var collider:=CollisionShape3D.new();collider.shape=child.shape;collider.transform=child.transform;frozen.add_child(collider)
  excluded.append(frozen.get_rid())
 simulator.physical_bones_stop_simulation();simulator.active=false;simulator.influence=0.0
 restore_pose(last_valid_pose);state=State.FROZEN;guard_freezes+=1
 trace.append({"event":"stretch_guard_freeze","may_rewind":true,"time":handoff_elapsed})
