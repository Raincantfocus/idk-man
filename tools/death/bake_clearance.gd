extends SceneTree
const Clip=preload("res://scripts/death/death_clip.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/death/settings.json"))
 var roots: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/death/root_motion.json"))
 var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://death_motions/source_manifest.json"))
 var scene: Node=(load("res://models/body.glb") as PackedScene).instantiate();root.add_child(scene)
 var sk: Skeleton3D=scene.find_children("*","Skeleton3D",true,false)[0]
 var offsets: Dictionary={}
 for definition: Dictionary in config.bones:
  var index: int=sk.find_bone(definition.name);var rest: Transform3D=sk.get_bone_global_rest(index);var end: Vector3=rest.origin+Vector3.UP*.12
  if not String(definition.tip).is_empty():end=sk.get_bone_global_rest(sk.find_bone(definition.tip)).origin
  offsets[definition.name]=rest.affine_inverse()*((rest.origin+end)*.5)
 var player:=AnimationPlayer.new();scene.add_child(player);player.root_node=player.get_path_to(sk);player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 var library: AnimationLibrary=load("res://data/death/death_library.res");assert(player.add_animation_library(&"",library)==OK)
 DirAccess.make_dir_recursive_absolute("res://data/death/clips");var reports: Array=[]
 for source: Dictionary in manifest.clips:
  if not source.death:continue
  var clip:=Clip.new();clip.id=source.id;clip.animation=source.id;clip.duration=library.get_animation(clip.id).length;clip.flying=source.flying;clip.requires_crouch="crouching" in String(clip.id)
  clip.direction=&"right" if "from_right" in String(clip.id) else &"back" if "from_back" in String(clip.id) or "from_the_back" in String(clip.id) else &"front"
  clip.priority=120 if clip.flying else 100;clip.handoff_time=clip.duration*float(config.flying_handoff_fraction if clip.flying else config.handoff_fraction)
  clip.key_bones=PackedStringArray(config.key_radii.keys());clip.swept_capsule_radius=config.key_radii.duplicate();clip.root_samples.assign(roots[clip.id])
  var previous:=Vector3.ZERO
  for row: Dictionary in clip.root_samples:
   var p:=Vector3(row.position[0],row.position[1],row.position[2]);clip.root_motion_distance+=p.distance_to(previous);previous=p
  player.play(clip.id)
  var count: int=int(ceil(clip.duration/float(config.clearance_interval_seconds)))
  for frame: int in count+1:
   var time: float=minf(frame*float(config.clearance_interval_seconds),clip.duration);player.seek(time,true);sk.force_update_all_bone_transforms()
   var points: Dictionary={};var root_offset: Vector3=clip.root_at(time)
   for name: String in clip.key_bones:
    var index: int=sk.find_bone(name);assert(index>=0,"Missing key bone "+name)
    var p: Vector3=(sk.get_bone_global_pose(index)*offsets[name])+root_offset;points[name]=[p.x,p.y,p.z];clip.min_clearance_behind_cm=maxf(clip.min_clearance_behind_cm,-p.z*100.0)
   clip.clearance_samples.append({"time":time,"points":points})
  # End authored motion before its first floor-contact violation. World obstacles
  # are still checked at selection and every physics tick by the controller.
  for sample: Dictionary in clip.clearance_samples:
   var unsafe: bool=false
   for name: String in clip.key_bones:
    unsafe=unsafe or float(sample.points[name][1])-float(clip.swept_capsule_radius[name])<float(config.query_margin_m)
   if unsafe:
    clip.handoff_time=minf(clip.handoff_time,maxf(0.05,float(sample.time)-float(config.clearance_interval_seconds)));break
  player.seek(clip.handoff_time,true);sk.force_update_all_bone_transforms();var handoff_points: Dictionary={}
  for name: String in clip.key_bones:
   var point: Vector3=(sk.get_bone_global_pose(sk.find_bone(name))*offsets[name])+clip.root_at(clip.handoff_time);handoff_points[name]=[point.x,point.y,point.z]
  clip.clearance_samples.append({"time":clip.handoff_time,"points":handoff_points})
  clip.clearance_samples.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return float(a.time)<float(b.time))
  player.seek(clip.duration,true);sk.force_update_all_bone_transforms()
  clip.ends_lying=sk.get_bone_global_pose(sk.find_bone("Chest")).origin.y<0.55
  assert(ResourceSaver.save(clip,"res://data/death/clips/"+String(clip.id)+".tres")==OK)
  var file:=FileAccess.open("res://data/death/clips/"+String(clip.id)+".json",FileAccess.WRITE);file.store_string(JSON.stringify(clip.to_dictionary(),"  "));file.close()
  reports.append({"id":clip.id,"direction":clip.direction,"samples":clip.clearance_samples.size(),"root_motion_distance":clip.root_motion_distance,"flying":clip.flying,"usable_data":true,"visual_approval":false})
 var file:=FileAccess.open("res://data/death/clearance_report.json",FileAccess.WRITE);file.store_string(JSON.stringify(reports,"  "));file.close();scene.free();print("DEATH_CLEARANCE_BAKED ",reports.size());quit()
