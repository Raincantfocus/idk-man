extends CharacterBody3D
## Isolated presentation actor. No loot, score, damage or wave callbacks.
const Clip=preload("death_clip.gd")
const Query=preload("clearance_query.gd")
enum State {READY, ANIMATING, BLENDING, RAGDOLL, FROZEN}
var state: State=State.READY
var tuning: Dictionary
var budget: RefCounted
var query: Query
var skeleton: Skeleton3D
var player: AnimationPlayer
var simulator: PhysicalBoneSimulator3D
var physical: Dictionary={}
var proxy_offsets: Dictionary={}
var joint_links: Dictionary={}
var frozen_joint_error: float=0.0
var excluded: Array[RID]=[]
var clips: Array=[]
var selected: Clip
var elapsed: float=0.0
var handoff_elapsed: float=0.0
var stable_elapsed: float=0.0
var root_blocked_ticks: int=0
var lethal_events_received: int=0
var handoff_count: int=0
var reason: String=""
var trace: Array=[]
var pose_history: Array=[]
var history_delta: float=1.0/60.0
var hit_impulse:=Vector3.ZERO
var body_collider: CollisionShape3D
var max_handoff_pop: float=0.0
var allow_eviction: bool=true
var full_ragdoll: bool=true
var budget_camera_position:=Vector3.ZERO
func setup(settings: Dictionary, pool: RefCounted) -> void:
 tuning=settings;budget=pool;query=Query.new();query.configure(tuning)
 collision_layer=8;collision_mask=int(tuning.collision_mask)
 body_collider=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.22;capsule.height=1.8;body_collider.shape=capsule;body_collider.position.y=.9;add_child(body_collider)
 var model: Node3D=(load("res://models/body.glb") as PackedScene).instantiate();add_child(model)
 skeleton=model.find_children("*","Skeleton3D",true,false)[0]
 for file: String in ["fatigues","carrier"]:
  var donor: Node3D=(load("res://models/"+file+".glb") as PackedScene).instantiate();add_child(donor)
  var material:=ORMMaterial3D.new();material.albedo_texture=load("res://models/"+file+"_albedo.png");material.orm_texture=load("res://models/"+file+"_orm.png");material.normal_enabled=true;material.normal_texture=load("res://models/"+file+"_normal.png");material.ao_enabled=true
  for mesh: MeshInstance3D in donor.find_children("*","MeshInstance3D",true,false):mesh.reparent(model,true);mesh.skeleton=mesh.get_path_to(skeleton);mesh.material_override=material
  donor.free()
 if FileAccess.file_exists("res://data/clipping/review_patch.json"):
  preload("res://scripts/clipping/apply_patch.gd").apply(model,JSON.parse_string(FileAccess.get_file_as_string("res://data/clipping/review_patch.json")))
 player=AnimationPlayer.new();add_child(player);player.root_node=player.get_path_to(skeleton);player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 assert(player.add_animation_library(&"",load("res://data/death/death_library.res"))==OK)
 assert(player.add_animation_library(&"base",load("res://data/animation/actorcore_library.res"))==OK)
 player.play(&"base/hold");player.seek(0,true);player.pause();skeleton.force_update_all_bone_transforms()
 for file: String in DirAccess.get_files_at("res://data/death/clips"):
  if file.ends_with(".tres"):clips.append(load("res://data/death/clips/"+file))
 _build_bodies();excluded.append(get_rid());pose_history.append(capture_pose());set_physics_process(true)
func _build_bodies() -> void:
 simulator=PhysicalBoneSimulator3D.new();skeleton.add_child(simulator);simulator.influence=0.0;simulator.active=false
 for definition: Dictionary in tuning.bones:
  var index: int=skeleton.find_bone(definition.name);assert(index>=0)
  var rest: Transform3D=skeleton.get_bone_global_rest(index);var end: Vector3=rest.origin+Vector3.UP*.12
  if not String(definition.tip).is_empty():end=skeleton.get_bone_global_rest(skeleton.find_bone(definition.tip)).origin
  var segment: Vector3=end-rest.origin;var center: Vector3=(rest.origin+end)*.5
  var basis:=Basis(Quaternion(Vector3.UP,segment.normalized()))
  var bone:=PhysicalBone3D.new();bone.name="Physical_"+String(definition.name);simulator.add_child(bone);bone.set("bone_name",StringName(definition.name));bone.body_offset=rest.affine_inverse()*Transform3D(basis,center)
  # Godot cone twist uses local X; our capsule/bone length is local Y.
  var axis: Array=tuning.cone_axis_rotation_radians
  bone.joint_rotation=Vector3(float(axis[0]),float(axis[1]),float(axis[2]))
  bone.mass=float(definition.mass);bone.linear_damp=float(tuning.linear_damping);bone.angular_damp=float(tuning.angular_damping);bone.friction=.8;bone.bounce=0.0;bone.can_sleep=true;bone.collision_layer=int(tuning.corpse_layer);bone.collision_mask=int(tuning.collision_mask)
  bone.joint_type=PhysicalBone3D.JOINT_TYPE_CONE;bone.set("joint_constraints/swing_span",float(definition.swing));bone.set("joint_constraints/twist_span",float(definition.twist))
  var collider:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.radius=float(definition.radius);shape.height=maxf(shape.radius*2.0,segment.length()*.8);collider.shape=shape;bone.add_child(collider)
  PhysicsServer3D.body_set_enable_continuous_collision_detection(bone.get_rid(),true)
  # Root motion must never recover against this actor's own physical bodies.
  add_collision_exception_with(bone);bone.add_collision_exception_with(self)
  physical[String(definition.name)]=bone;proxy_offsets[String(definition.name)]=bone.body_offset.origin;excluded.append(bone.get_rid())
 for bone: PhysicalBone3D in physical.values():
  for other: PhysicalBone3D in physical.values():
   if bone!=other:bone.add_collision_exception_with(other)
func capture_pose() -> Array[Transform3D]:
 skeleton.force_update_all_bone_transforms();var result: Array[Transform3D]=[]
 for i: int in skeleton.get_bone_count():result.append(skeleton.get_bone_global_pose(i))
 if state==State.BLENDING or state==State.RAGDOLL:
  var animated: Array[Transform3D]=result.duplicate()
  for i: int in skeleton.get_bone_count():
   var name: String=skeleton.get_bone_name(i);var parent: int=skeleton.get_bone_parent(i)
   if physical.has(name) and physical[name].is_simulating_physics():
    var simulated: Transform3D=skeleton.global_transform.affine_inverse()*physical[name].global_transform*physical[name].body_offset.affine_inverse()
    result[i]=animated[i].interpolate_with(simulated,simulator.influence)
   elif parent>=0:result[i]=result[parent]*(animated[parent].affine_inverse()*animated[i])
 return result
func restore_pose(pose: Array) -> void:
 for i: int in skeleton.get_bone_count():
  var parent: int=skeleton.get_bone_parent(i);var local: Transform3D=pose[parent].affine_inverse()*pose[i] if parent>=0 else pose[i]
  skeleton.set_bone_pose_position(i,local.origin);skeleton.set_bone_pose_rotation(i,local.basis.get_rotation_quaternion());skeleton.set_bone_pose_scale(i,local.basis.get_scale())
 skeleton.force_update_all_bone_transforms()
func points() -> Dictionary:
 var result: Dictionary={};var pose: Array[Transform3D]=capture_pose()
 for name: String in tuning.key_radii:result[name]=skeleton.global_transform*(pose[skeleton.find_bone(name)]*proxy_offsets[name])
 return result
func begin_death(incoming: Vector3, tags: PackedStringArray, impulse: Vector3=Vector3.ZERO, crouched: bool=false) -> bool:
 if state!=State.READY:return false
 lethal_events_received+=1;hit_impulse=impulse.limit_length(float(tuning.max_hit_impulse))
 var choice: Dictionary=query.choose(get_world_3d().direct_space_state,clips,query.hit_direction(global_basis,incoming),tags,global_transform,excluded,crouched)
 selected=choice.clip;trace.append({"event":"selection","clip":String(selected.id) if selected!=null else "none","reason":choice.reason,"rejected":choice.rejected})
 if selected==null:_handoff("ragdoll_now");return true
 state=State.ANIMATING;elapsed=0.0;player.play(selected.animation);player.pause()
 return true
func notify_hit(heavy_or_lethal: bool, impulse: Vector3) -> void:
 if state==State.ANIMATING and (heavy_or_lethal or impulse.length()>=float(tuning.disturbance_impulse_threshold)):
  hit_impulse=impulse.limit_length(float(tuning.max_hit_impulse));_handoff("disturbed")
func _physics_process(delta: float) -> void:
 if delta<=0.0 or state==State.READY or state==State.FROZEN:return
 if state==State.ANIMATING:
  var previous: Array[Transform3D]=capture_pose();var old_points: Dictionary=points();var expected: Vector3=global_basis*(selected.root_at(elapsed+delta)-selected.root_at(elapsed));var before: Vector3=global_position
  if expected.length_squared()>0.00000001:move_and_collide(expected)
  var fraction: float=global_position.distance_to(before)/maxf(expected.length(),.000001)
  root_blocked_ticks=root_blocked_ticks+1 if expected.length()>.0001 and fraction<float(tuning.blocked_root_fraction) else 0
  if root_blocked_ticks>=int(tuning.blocked_root_ticks):_handoff("root_blocked");return
  var next: float=minf(elapsed+delta,selected.duration);player.seek(next,true);skeleton.force_update_all_bone_transforms();var new_points: Dictionary=points();var space: PhysicsDirectSpaceState3D=get_world_3d().direct_space_state
  for name: String in new_points:
   if query.obstruction(space,name,old_points[name],new_points[name],excluded):
    restore_pose(previous)
    var contacts: Array[Dictionary]=space.intersect_shape(query.parameters(name,new_points[name],excluded),4)
    var disturbed: bool=contacts.any(func(contact: Dictionary)->bool:return contact.collider is RigidBody3D or contact.collider is PhysicalBone3D)
    _handoff("disturbed" if disturbed else "bone_blocked");return
  elapsed=next;history_delta=delta;pose_history.append(capture_pose())
  while pose_history.size()>3:pose_history.pop_front()
  if not query.supported(space,new_points,excluded):_handoff("no_support");return
  if elapsed>=selected.handoff_time:_handoff("planned");return
 elif state==State.BLENDING or state==State.RAGDOLL:
  handoff_elapsed+=delta;simulator.influence=clampf(handoff_elapsed/float(tuning.blend_seconds),0.0,1.0)
  if simulator.influence>=1.0:state=State.RAGDOLL
  var quiet: bool=true
  for bone: PhysicalBone3D in physical.values():
   if not bone.is_simulating_physics():continue
   bone.linear_velocity=bone.linear_velocity.limit_length(float(tuning.max_linear_speed));bone.angular_velocity=bone.angular_velocity.limit_length(float(tuning.max_angular_speed))
   quiet=quiet and bone.linear_velocity.length()<float(tuning.sleep_linear_speed) and bone.angular_velocity.length()<float(tuning.sleep_angular_speed)
  stable_elapsed=stable_elapsed+delta if quiet else 0.0
  if stable_elapsed>=float(tuning.sleep_stable_seconds) or (quiet and handoff_elapsed>=float(tuning.settle_seconds)):freeze_corpse()
func _handoff(trigger: String) -> void:
 if handoff_count>0:return
 handoff_count=1;reason=trigger;player.pause()
 var original: Array[Transform3D]=capture_pose();var corrected: Array[Transform3D]=original.duplicate();var world: Transform3D=skeleton.global_transform
 var space: PhysicsDirectSpaceState3D=get_world_3d().direct_space_state
 for name: String in tuning.key_radii:
  var index: int=skeleton.find_bone(name);var position: Vector3=world*(corrected[index]*proxy_offsets[name])
  var correction: Vector3=query.penetration(space,name,position,excluded)
  if correction.length()>0.00001:corrected[index].origin+=world.basis.inverse()*correction.limit_length(float(tuning.max_depenetration_m))
 restore_pose(corrected)
 full_ragdoll=budget.reserve(self,budget_camera_position)
 var selected_bones: Array[StringName]=[]
 if not full_ragdoll:
  for name: String in ["Hips","Chest","Head","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"]:selected_bones.append(StringName(name))
 if not full_ragdoll:
  for name: String in physical.keys():
   if not StringName(name) in selected_bones:
    var removed: PhysicalBone3D=physical[name];var index: int=skeleton.find_bone(name);var parent: int=skeleton.get_bone_parent(index)
    while parent>=0 and not StringName(skeleton.get_bone_name(parent)) in selected_bones:parent=skeleton.get_bone_parent(parent)
    if parent>=0:
     var retained: PhysicalBone3D=physical[String(skeleton.get_bone_name(parent))]
     var parent_transform: Transform3D=world*corrected[parent]*retained.body_offset
     var child_transform: Transform3D=world*corrected[index]*removed.body_offset
     var child_shape: CollisionShape3D=removed.get_child(0) as CollisionShape3D
     var compound:=CollisionShape3D.new();compound.shape=child_shape.shape;retained.add_child(compound);compound.transform=parent_transform.affine_inverse()*child_transform*child_shape.transform
    excluded.erase(removed.get_rid());physical.erase(name);removed.free()
 body_collider.set_deferred("disabled",true);collision_layer=0
 simulator.influence=0.0;simulator.active=true;simulator.physical_bones_start_simulation()
 var old: Array=pose_history[maxi(0,pose_history.size()-2)] if not pose_history.is_empty() else original
 var total_mass: float=0.0
 for bone: PhysicalBone3D in physical.values():total_mass+=bone.mass
 for name: String in physical:
  var bone: PhysicalBone3D=physical[name];var index: int=skeleton.find_bone(name)
  var current_transform: Transform3D=world*corrected[index]*bone.body_offset;var old_transform: Transform3D=world*old[index]*bone.body_offset
  bone.global_transform=current_transform
  bone.linear_velocity=((current_transform.origin-old_transform.origin)/maxf(history_delta,.001)).limit_length(float(tuning.max_linear_speed))
  var rotation: Quaternion=(current_transform.basis.get_rotation_quaternion()*old_transform.basis.get_rotation_quaternion().inverse()).normalized()
  if rotation.w<0.0:rotation=-rotation
  var axis:=Vector3(rotation.x,rotation.y,rotation.z);var omega:=Vector3.ZERO
  if axis.length()>.00001:omega=axis.normalized()*(2.0*acos(clampf(rotation.w,-1.0,1.0))/maxf(history_delta,.001))
  bone.angular_velocity=omega.limit_length(float(tuning.max_angular_speed));bone.apply_central_impulse(hit_impulse*(bone.mass/maxf(total_mass,1.0)))
 # Rebuild joint frames only after every body is placed at the captured pose.
 # Otherwise skipped humanoid helper bones retain an outdated animation anchor.
 for definition: Dictionary in tuning.bones:
  if not physical.has(String(definition.name)):continue
  var bone: PhysicalBone3D=physical[String(definition.name)]
  bone.joint_type=PhysicalBone3D.JOINT_TYPE_NONE;bone.joint_type=PhysicalBone3D.JOINT_TYPE_CONE
  bone.set("joint_constraints/swing_span",float(definition.swing));bone.set("joint_constraints/twist_span",float(definition.twist))
 for name: String in physical:
  var index: int=skeleton.find_bone(name);var parent: int=skeleton.get_bone_parent(index)
  while parent>=0 and not physical.has(String(skeleton.get_bone_name(parent))):parent=skeleton.get_bone_parent(parent)
  if parent>=0:
   var parent_name: String=skeleton.get_bone_name(parent);var anchor: Vector3=physical[name].global_transform*physical[name].joint_offset.origin
   joint_links[name]={"parent":parent_name,"parent_anchor":physical[parent_name].global_transform.affine_inverse()*anchor,"child_anchor":physical[name].joint_offset.origin}
 for i: int in original.size():max_handoff_pop=maxf(max_handoff_pop,(world*original[i].origin).distance_to(world*corrected[i].origin))
 state=State.BLENDING;trace.append({"event":"handoff","reason":reason,"time":elapsed,"pop_m":max_handoff_pop,"full_ragdoll":full_ragdoll})
func is_simulating() -> bool:return state==State.BLENDING or state==State.RAGDOLL
func freeze_corpse() -> bool:
 if not allow_eviction:return false
 if state==State.FROZEN:return true
 # Budget eviction and timeout must not suspend a corpse over a void.
 var space: PhysicsDirectSpaceState3D=get_world_3d().direct_space_state
 var key_points: Dictionary=points()
 if not query.supported(space,key_points,excluded):return false
 for name: String in key_points:
  if query.penetration(space,name,key_points[name],excluded).length()>float(tuning.penetration_limit_m):return false
 var pose: Array[Transform3D]=capture_pose()
 frozen_joint_error=joint_error()
 for bone: PhysicalBone3D in physical.values():
  var frozen:=StaticBody3D.new();frozen.collision_layer=int(tuning.corpse_layer);frozen.collision_mask=int(tuning.world_mask)|int(tuning.prop_mask);add_child(frozen);frozen.global_transform=bone.global_transform
  for child: Node in bone.get_children():
   if child is CollisionShape3D:
    var collision:=CollisionShape3D.new();collision.shape=child.shape;collision.transform=child.transform;frozen.add_child(collision)
  excluded.append(frozen.get_rid())
 simulator.physical_bones_stop_simulation();simulator.active=false;simulator.influence=0.0;restore_pose(pose);state=State.FROZEN
 return true

func joint_error() -> float:
 if state==State.FROZEN:return frozen_joint_error
 var maximum: float=0.0
 for name: String in joint_links:
  var link: Dictionary=joint_links[name]
  var a: Vector3=physical[link.parent].global_transform*link.parent_anchor
  var b: Vector3=physical[name].global_transform*link.child_anchor
  maximum=maxf(maximum,a.distance_to(b))
 return maximum
