extends SceneTree
const Controller=preload("res://scripts/animation/character_animation.gd")
var count: int=0
var failures: int=0
func check(ok: bool, label: String) -> void:
 if not ok:failures+=1;push_error(label)
 else:count+=1
func _initialize() -> void:call_deferred("run")
func make_actor() -> Dictionary:
 var body: Node3D=(load("res://models/body.glb") as PackedScene).instantiate() as Node3D;root.add_child(body)
 var sk: Skeleton3D=body.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
 var controller:=Controller.new();body.add_child(controller)
 controller.configure(sk,load("res://data/animation/actorcore_library.res") as AnimationLibrary,load("res://data/animation/animation_profile.tres"))
 return {"body":body,"skeleton":sk,"controller":controller}
func same_pose(a: Array[Transform3D], b: Array[Transform3D], tolerance: float=.0001) -> bool:
 for i: int in a.size():
  if a[i].origin.distance_to(b[i].origin)>tolerance:return false
  if a[i].basis.get_rotation_quaternion().angle_to(b[i].basis.get_rotation_quaternion())>.001:return false
 return true
func run() -> void:
 var actor: Dictionary=make_actor();var sk: Skeleton3D=actor.skeleton;var controller: Controller=actor.controller
 var library: AnimationLibrary=controller.player.get_animation_library(&"")
 check(sk.get_bone_count()==72,"72-bone target")
 check(library.get_animation_list().size()==9,"Eight clips plus static hold")
 for clip: StringName in library.get_animation_list():
  var animation: Animation=library.get_animation(clip)
  for track: int in animation.get_track_count():
   var kind: int=animation.track_get_type(track);var path: NodePath=animation.track_get_path(track)
   check(kind==Animation.TYPE_ROTATION_3D or kind==Animation.TYPE_POSITION_3D,"No gameplay method/audio/property tracks")
   check(sk.find_bone(String(path.get_subname(0)))>=0,"Every track resolves")
   if kind==Animation.TYPE_POSITION_3D:check(path.get_subname(0)==&"Hips","Only hip position allowed")
  controller.preview_clip(clip)
  for fraction: float in [0.0,.25,.5,.75,1.0]:
   controller.player.seek(animation.length*fraction,true);sk.force_update_all_bone_transforms()
   var finite: bool=true;var lengths: bool=true
   for i: int in sk.get_bone_count():
    finite=finite and sk.get_bone_global_pose(i).is_finite()
    if sk.get_bone_name(i)!="Hips":lengths=lengths and sk.get_bone_pose_position(i).is_equal_approx(sk.get_bone_rest(i).origin)
   check(finite,"Finite retarget poses");check(lengths,"Fixed rest segment translations")
 check((actor.body as Node3D).transform==Transform3D.IDENTITY,"No root capsule movement")
 controller.preview_clip(&"run_loop");controller.advance(.2,5)
 var paused_pose: Array[Transform3D]=controller.capture_pose();controller.advance(0,5)
 check(same_pose(paused_pose,controller.capture_pose()),"Zero world delta pauses")
 var second: Dictionary=make_actor();var other: Controller=second.controller;other.preview_clip(&"run_loop")
 for i: int in 10:other.advance(.02,5)
 check(same_pose(paused_pose,other.capture_pose()),"Scaled time uses supplied delta exactly once")
 controller.use_locomotion()
 for i: int in 30:controller.advance(1.0/60.0,5)
 controller.on_attack();controller.advance(.1,5)
 check(bool(controller.tree.get("parameters/Fire/active")),"Fire one-shot activates")
 controller.on_reload();controller.advance(.1,5)
 check(bool(controller.tree.get("parameters/Reload/active")),"Reload one-shot activates")
 var captured: Array[Transform3D]=controller.freeze_pose();controller.advance(1,5);controller.on_attack()
 check(captured.size()==72 and same_pose(captured,controller.capture_pose()),"Captured death pose freezes without rewards")
 check(not (actor.body as Node).find_children("*","CollisionObject3D",true,false).size(),"No gameplay collider added")
 var base_actor: Dictionary=make_actor();var fire_actor: Dictionary=make_actor()
 var base_control: Controller=base_actor.controller;var fire_control: Controller=fire_actor.controller
 for i: int in 30:base_control.advance(1.0/60.0,5);fire_control.advance(1.0/60.0,5)
 fire_control.on_attack()
 for i: int in 15:base_control.advance(1.0/60.0,5);fire_control.advance(1.0/60.0,5)
 var base_sk: Skeleton3D=base_actor.skeleton;var fire_sk: Skeleton3D=fire_actor.skeleton
 for name: String in ["Hips","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"]:
  var bone: int=base_sk.find_bone(name)
  check(base_sk.get_bone_pose(bone).is_equal_approx(fire_sk.get_bone_pose(bone)),"Upper-body filter preserves "+name)
 base_actor.body.free();fire_actor.body.free()
 actor.body.free();second.body.free()
 var f:=FileAccess.open("res://animation_test_report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":count,"failed":failures,"engine":Engine.get_version_info().string},"  "));f.close()
 print("ANIMATION_TESTS ",count," passed, ",failures," failed");quit(1 if failures>0 else 0)
