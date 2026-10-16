extends SceneTree
func _initialize() -> void:
 var mapping: BoneMap=load("res://data/characters/humanoid_bone_map.tres") as BoneMap
 var dir: DirAccess=DirAccess.open("res://assets/characters/generated")
 for name: String in dir.get_files():
  if not name.ends_with(".glb.import"): continue
  var path: String="res://assets/characters/generated/"+name
  var config := ConfigFile.new()
  if config.load(path)!=OK:
   quit(1)
   return
  config.set_value("params","meshes/generate_lods",false)
  config.set_value("params","animation/import",false)
  config.set_value("params","skins/use_named_skins",true)
  # Options verified in Godot 4.6.3 resource_importer_scene and skeleton plugins.
  # Phase 1 retains authored A-rest. Phase 2 selects retarget rest correction
  # after the source animation rest pose is known and deformation is reviewed.
  config.set_value("params","_subresources",{"nodes":{"PATH:HumanoidRig/Skeleton3D":{
   "retarget/bone_map":mapping,
   "retarget/bone_renamer/rename_bones":false,
   "retarget/bone_renamer/unique_node/make_unique":false,
   "retarget/rest_fixer/retarget_method":0,
   "retarget/rest_fixer/apply_node_transforms":false,
   "retarget/rest_fixer/normalize_position_tracks":false,
   "retarget/rest_fixer/fix_silhouette/enable":false}}})
  if config.save(path)!=OK:
   quit(1)
   return
 print("Configured explicit LOD imports and humanoid BoneMap; preserved authored rest pose")
 quit()
