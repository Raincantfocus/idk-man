extends Node
## Cosmetic playback only. Caller supplies world-scaled delta once per tick.
## No health, movement, attack scheduling, RNG, animation methods or loot callbacks.
const Profile=preload("animation_profile.gd")
var skeleton: Skeleton3D
var player: AnimationPlayer
var tree: AnimationTree
var tuning: Profile
var blend: float=0.0
var frozen: bool=false
var preview: bool=false
func configure(target: Skeleton3D, library: AnimationLibrary, settings: Profile) -> void:
 skeleton=target;tuning=settings
 player=AnimationPlayer.new();player.name="AuthoredAnimationPlayer";add_child(player)
 player.root_node=player.get_path_to(skeleton)
 player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 assert(player.add_animation_library(&"",library)==OK)
 var graph:=AnimationNodeBlendTree.new()
 var locomotion:=AnimationNodeBlendSpace1D.new();locomotion.min_space=0;locomotion.max_space=1
 var hold:=AnimationNodeAnimation.new();hold.animation=StringName(tuning.clips.hold)
 var run:=AnimationNodeAnimation.new();run.animation=StringName(tuning.clips.run)
 locomotion.add_blend_point(hold,0);locomotion.add_blend_point(run,1)
 graph.add_node(&"Locomotion",locomotion)
 var fire_clip:=AnimationNodeAnimation.new();fire_clip.animation=StringName(tuning.clips.fire);graph.add_node(&"FireClip",fire_clip)
 var reload_clip:=AnimationNodeAnimation.new();reload_clip.animation=StringName(tuning.clips.reload);graph.add_node(&"ReloadClip",reload_clip)
 var fire:=AnimationNodeOneShot.new();fire.fadein_time=float(tuning.fire_fade_in_seconds);fire.fadeout_time=float(tuning.fire_fade_out_seconds)
 var reload:=AnimationNodeOneShot.new();reload.fadein_time=float(tuning.reload_fade_in_seconds);reload.fadeout_time=float(tuning.reload_fade_out_seconds)
 fire.filter_enabled=true;reload.filter_enabled=true
 var filter_roots: Array[int]=[]
 for name: String in tuning.upper_body_roots:
  var bone: int=skeleton.find_bone(name);assert(bone>=0);filter_roots.append(bone)
 for i: int in skeleton.get_bone_count():
  var ancestor: int=i
  while ancestor>=0 and not ancestor in filter_roots:ancestor=skeleton.get_bone_parent(ancestor)
  if ancestor in filter_roots:
   var path:=NodePath(".:"+skeleton.get_bone_name(i));fire.set_filter_path(path,true);reload.set_filter_path(path,true)
 graph.add_node(&"Fire",fire);graph.add_node(&"Reload",reload)
 graph.connect_node(&"Fire",0,&"Locomotion");graph.connect_node(&"Fire",1,&"FireClip")
 graph.connect_node(&"Reload",0,&"Fire");graph.connect_node(&"Reload",1,&"ReloadClip")
 graph.connect_node(&"output",0,&"Reload")
 tree=AnimationTree.new();tree.name="AuthoredAnimationTree";add_child(tree)
 tree.anim_player=tree.get_path_to(player);tree.root_node=tree.get_path_to(skeleton);tree.tree_root=graph
 tree.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;tree.active=true
 tree.advance(0)
func advance(world_delta: float, speed_mps: float) -> void:
 if frozen or not is_finite(world_delta) or world_delta<=0:return
 if preview:player.advance(world_delta);return
 var target: float=clampf(speed_mps/float(tuning.run_reference_speed_mps),0,1)
 blend=move_toward(blend,target,world_delta/maxf(float(tuning.speed_blend_seconds),.001))
 tree.set("parameters/Locomotion/blend_position",blend);tree.advance(world_delta)
func on_attack() -> void:
 if not frozen and not preview:tree.set("parameters/Fire/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
func on_reload() -> void:
 if not frozen and not preview:tree.set("parameters/Reload/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
func preview_clip(clip: StringName) -> void:
 assert(player.has_animation(clip));preview=true;tree.active=false;player.play(clip);player.seek(0,true)
func use_locomotion() -> void:
 player.stop();preview=false;tree.active=true;tree.advance(0)
func capture_pose() -> Array[Transform3D]:
 skeleton.force_update_all_bone_transforms()
 var result: Array[Transform3D]=[]
 for i: int in skeleton.get_bone_count():result.append(skeleton.get_bone_global_pose(i))
 return result
func freeze_pose() -> Array[Transform3D]:
 var result: Array[Transform3D]=capture_pose();frozen=true;tree.active=false;player.pause();return result
