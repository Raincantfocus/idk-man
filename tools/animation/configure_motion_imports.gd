extends SceneTree
func _initialize() -> void:
 var profile:=SkeletonProfileHumanoid.new();var source:=BoneMap.new();source.profile=profile
 var pairs: Dictionary={"Root":"BoneRoot","Hips":"Hip","Spine":"Waist","Chest":"Spine01","UpperChest":"Spine02","Neck":"NeckTwist01","Head":"Head","Jaw":"JawRoot","LeftEye":"L_Eye","RightEye":"R_Eye"}
 for side: String in ["Left","Right"]:
  var prefix: String="L_" if side=="Left" else "R_"
  for part: String in ["Shoulder","UpperArm","LowerArm","Hand","UpperLeg","LowerLeg","Foot","Toes"]:
   var names: Dictionary={"Shoulder":"Clavicle","UpperArm":"Upperarm","LowerArm":"Forearm","Hand":"Hand","UpperLeg":"Thigh","LowerLeg":"Calf","Foot":"Foot","Toes":"ToeBase"}
   pairs[side+part]=prefix+String(names[part])
  for finger: String in ["Thumb","Index","Middle","Ring","Little"]:
   var source_finger: String="Mid" if finger=="Middle" else "Pinky" if finger=="Little" else finger
   var segments: Array=["Metacarpal","Proximal","Distal"] if finger=="Thumb" else ["Proximal","Intermediate","Distal"]
   for i: int in 3:pairs[side+finger+segments[i]]=prefix+source_finger+str(i+1)
 for name: String in pairs:source.set_skeleton_bone_name(StringName(name),StringName("CC_Base_"+String(pairs[name])))
 assert(ResourceSaver.save(source,"res://data/animation/actorcore_bone_map.tres")==OK)
 var target: BoneMap=load("res://data/animation/target_bone_map.tres") as BoneMap
 for folder: String in ["res://motions","res://models"]:
  for file: String in DirAccess.get_files_at(folder):
   if not file.ends_with(".glb"):continue
   var path: String=folder.path_join(file)
   var packed: PackedScene=load(path) as PackedScene
   var scene: Node=packed.instantiate()
   var rigs: Array[Node]=scene.find_children("*","Skeleton3D",true,false)
   var config:=ConfigFile.new();assert(config.load(path+".import")==OK)
   config.set_value("params","animation/import",folder=="res://motions")
   config.set_value("params","animation/remove_immutable_tracks",false)
   config.set_value("params","animation/fps",60)
   config.set_value("params","animation/import_rest_as_RESET",true)
   config.set_value("params","meshes/generate_lods",false)
   config.set_value("params","skins/use_named_skins",true)
   if rigs.is_empty():
    config.set_value("params","nodes/import_as_skeleton_bones",true)
    print("REQUEST_SKELETON_IMPORT ",path)
   else:
    var settings: Dictionary={}
    for sk: Node in rigs:
     settings["PATH:"+String(scene.get_path_to(sk))]={"retarget/bone_map":source if folder=="res://motions" else target,"retarget/bone_renamer/rename_bones":true,"retarget/bone_renamer/unique_node/make_unique":false,"retarget/rest_fixer/retarget_method":1,"retarget/rest_fixer/apply_node_transforms":true,"retarget/rest_fixer/normalize_position_tracks":true,"retarget/rest_fixer/fix_silhouette/enable":true,"retarget/rest_fixer/fix_silhouette/threshold":1.0}
    config.set_value("params","_subresources",{"nodes":settings})
   assert(config.save(path+".import")==OK);scene.free()
 quit()
