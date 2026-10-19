extends SceneTree
const Profile=preload("res://scripts/animation/animation_profile.gd")
func _initialize() -> void:
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/animation_tuning.json"))
 var profile:=Profile.new()
 for key: String in data:
  profile.set(key,PackedStringArray(data[key]) if key in ["missing_clips","upper_body_roots"] else data[key])
 assert(ResourceSaver.save(profile,"res://data/animation/animation_profile.tres")==OK)
 var f:=FileAccess.open("res://data/animation/animation_tuning.json",FileAccess.WRITE);f.store_string(JSON.stringify(profile.to_dictionary(),"  ")+"\n");f.close();quit()
