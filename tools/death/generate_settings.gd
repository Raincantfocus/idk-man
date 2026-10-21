extends SceneTree
func _initialize() -> void:
 var settings=preload("res://scripts/death/death_settings.gd").new();settings.values=JSON.parse_string(FileAccess.get_file_as_string("res://data/death/settings.json"))
 assert(ResourceSaver.save(settings,"res://data/death/settings.tres")==OK);quit()
