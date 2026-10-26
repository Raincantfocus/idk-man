extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game: Node=load("res://scenes/main.tscn").instantiate();game.is_test=true;root.add_child(game);game.set_process(false);game.set_gore_level(2)
 var enemy: Node=game.spawn_enemy("enforcer",Vector3.ZERO)
 var gore: Node=enemy.animated_visual.gore;gore.alive=false
 gore.split_cache.clear();gore.cap_cache.clear()
 for region: String in ["head","left_arm","right_arm","left_leg","right_leg"]:
  assert(gore.sever(region,Vector3.UP));gore.restore();gore.service.blood_budget.release_owner(gore.actor.get_instance_id());await process_frame
 var data:=preload("res://scripts/playtest/gore_geometry.gd").new();data.splits=gore.split_cache;data.caps=gore.cap_cache
 assert(ResourceSaver.save(data,"res://data/playtest/gore_geometry.res",ResourceSaver.FLAG_COMPRESS)==OK)
 print("GORE_GEOMETRY_BAKED splits=",data.splits.size()," caps=",data.caps.size())
 game.free();await process_frame;quit()
