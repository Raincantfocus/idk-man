extends SceneTree
func _initialize() -> void:
 var map:=BoneMap.new();map.profile=SkeletonProfileHumanoid.new()
 var names: Dictionary={"Hips":"Hips","Spine":"Spine","Chest":"Spine1","UpperChest":"Spine2","Neck":"Neck","Head":"Head"}
 for side: String in ["Left","Right"]:
  for part: String in ["Shoulder","UpperArm","LowerArm","Hand","UpperLeg","LowerLeg","Foot","Toes"]:
   var source: Dictionary={"Shoulder":"Shoulder","UpperArm":"Arm","LowerArm":"ForeArm","Hand":"Hand","UpperLeg":"UpLeg","LowerLeg":"Leg","Foot":"Foot","Toes":"ToeBase"};names[side+part]=side+String(source[part])
  for finger: String in ["Thumb","Index","Middle","Ring","Little"]:
   var original: String="Pinky" if finger=="Little" else finger
   var parts: Array=["Metacarpal","Proximal","Distal"] if finger=="Thumb" else ["Proximal","Intermediate","Distal"]
   for i: int in 3:names[side+finger+parts[i]]=side+"Hand"+original+str(i+1)
 for name: String in names:map.set_skeleton_bone_name(name,"mixamorig_"+String(names[name]))
 assert(ResourceSaver.save(map,"res://data/death/mixamo_bone_map.tres")==OK)
 for file: String in DirAccess.get_files_at("res://death_motions"):
  if not file.ends_with(".glb"):continue
  var path: String="res://death_motions/"+file
  var scene: Node=(load(path) as PackedScene).instantiate();var rigs: Array[Node]=scene.find_children("*","Skeleton3D",true,false)
  var config:=ConfigFile.new();assert(config.load(path+".import")==OK)
  config.set_value("params","animation/import",true);config.set_value("params","animation/remove_immutable_tracks",false);config.set_value("params","animation/fps",60);config.set_value("params","animation/import_rest_as_RESET",true);config.set_value("params","nodes/import_as_skeleton_bones",true)
  var settings: Dictionary={}
  for rig: Skeleton3D in rigs:
   # glTF exporter replaces colons; confirm actual imported name before mapping.
   var prefix: String="mixamorig_"
   for name: String in names:map.set_skeleton_bone_name(name,prefix+String(names[name]))
   settings["PATH:"+String(scene.get_path_to(rig))]={"retarget/bone_map":map,"retarget/bone_renamer/rename_bones":true,"retarget/bone_renamer/unique_node/make_unique":false,"retarget/rest_fixer/retarget_method":1,"retarget/rest_fixer/apply_node_transforms":true,"retarget/rest_fixer/normalize_position_tracks":true,"retarget/rest_fixer/fix_silhouette/enable":true,"retarget/rest_fixer/fix_silhouette/threshold":1.0}
  if not settings.is_empty():config.set_value("params","_subresources",{"nodes":settings})
  assert(config.save(path+".import")==OK);scene.free()
 quit()
