extends SceneTree
## Offline retarget after native BoneMap/profile import. All motion is sampled
## from supplied keyframes; no procedural gait and no runtime limb oscillation.
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var body: Node=(load("res://models/body.glb") as PackedScene).instantiate();root.add_child(body)
 var target: Skeleton3D=body.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
 var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://death_motions/source_manifest.json"))
 var library:=AnimationLibrary.new();var report: Array[Dictionary]=[];var roots: Dictionary={}
 for clip: Dictionary in manifest.clips:
  var source: Node=(load("res://death_motions/"+String(clip.file)) as PackedScene).instantiate();root.add_child(source)
  var rig: Skeleton3D=source.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
  var player: AnimationPlayer=source.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
  player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
  var source_name: StringName=&""
  for name: StringName in player.get_animation_list():
   if name!=&"RESET":source_name=name;break
  assert(source_name!=&"")
  var animation:=Animation.new();animation.length=minf(player.get_animation(source_name).length,float(clip.seconds))
  animation.loop_mode=Animation.LOOP_LINEAR if clip.loop else Animation.LOOP_NONE
  var tracks: Dictionary={};var mapping: Dictionary={}
  for i: int in target.get_bone_count():
   var name: String=target.get_bone_name(i);var mapped: int=rig.find_bone(name)
   if mapped>=0 and name!="Root":mapping[i]=mapped
   var track: int=animation.add_track(Animation.TYPE_ROTATION_3D);animation.track_set_path(track,NodePath(".:"+name));tracks[i]=track
  var hip: int=target.find_bone("Hips");var source_hip: int=rig.find_bone("Hips");assert(hip>=0 and source_hip>=0)
  var hip_track: int=animation.add_track(Animation.TYPE_POSITION_3D);animation.track_set_path(hip_track,NodePath(".:Hips"))
  player.play(source_name);player.seek(0,true);rig.force_update_all_bone_transforms()
  var rest_y: float=rig.get_bone_global_rest(source_hip).origin.y
  var initial: Vector3=rig.get_bone_global_pose(source_hip).origin
  var root_rows: Array=[]
  var frames: int=int(ceil(animation.length*60.0))
  var max_bob: float=0.0
  for frame: int in frames+1:
   var time: float=minf(frame/60.0,animation.length);player.seek(time,true);rig.force_update_all_bone_transforms()
   var global_rotations: Array[Quaternion]=[]
   for i: int in target.get_bone_count():
    var parent: int=target.get_bone_parent(i)
    var parent_rotation: Quaternion=global_rotations[parent] if parent>=0 else Quaternion.IDENTITY
    var local_rotation: Quaternion=target.get_bone_rest(i).basis.get_rotation_quaternion()
    var desired: Quaternion=parent_rotation*local_rotation
    if mapping.has(i):
     var j: int=mapping[i]
     desired=(rig.get_bone_global_pose(j).basis.get_rotation_quaternion()*rig.get_bone_global_rest(j).basis.get_rotation_quaternion().inverse()*target.get_bone_global_rest(i).basis.get_rotation_quaternion()).normalized()
     local_rotation=(parent_rotation.inverse()*desired).normalized()
    global_rotations.append(desired)
    animation.rotation_track_insert_key(tracks[i],time,local_rotation)
   var position: Vector3=target.get_bone_rest(hip).origin
   # Source import normalizes displacement by motion_scale; preserve vertical
   # motion only. Never apply authored translation to the gameplay capsule.
   var bob: float=(rig.get_bone_global_pose(source_hip).origin.y-rest_y)*target.motion_scale/maxf(rig.motion_scale,.001)
   var displacement: Vector3=(rig.get_bone_global_pose(source_hip).origin-initial)*target.motion_scale/maxf(rig.motion_scale,.001)
   root_rows.append({"time":time,"position":[displacement.x,0.0,displacement.z]})
   position.y+=bob;max_bob=maxf(max_bob,absf(bob));animation.position_track_insert_key(hip_track,time,position)
  assert(library.add_animation(StringName(clip.id),animation)==OK)
  report.append({"id":clip.id,"seconds":animation.length,"sample_count":frames+1,"mapped_bones":mapping.size(),"target_bones":target.get_bone_count(),"max_vertical_displacement_m":max_bob,"root_translation_removed":true})
  roots[clip.id]=root_rows
  source.free()
 assert(ResourceSaver.save(library,"res://data/death/death_library.res")==OK)
 var root_file:=FileAccess.open("res://data/death/root_motion.json",FileAccess.WRITE);root_file.store_string(JSON.stringify(roots));root_file.close()
 var file:=FileAccess.open("res://data/death/retarget_report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"clips":report,"engine":Engine.get_version_info().string},"  "));file.close()
 body.free();print("BAKED_DEATH_LIBRARY ",report.size());quit()
