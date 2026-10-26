extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game: Node=load("res://scenes/main.tscn").instantiate();game.is_test=true;root.add_child(game);game.start_run(true);game.set_process(false);game.player.set_physics_process(false);game.set_gore_level(2)
 var enemy: Node=game.spawn_enemy("enforcer",Vector3(0,0,15));enemy.set_physics_process(false)
 for i: int in 3:await physics_frame
 var actor: Node=enemy.animated_visual.actor
 var pool: Node=game.presentation.wound_pool
 var point: Vector3=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("Chest")).origin
 var index: int=pool.add_wound(actor,point+Vector3(0,0,.4),Vector3.BACK)
 print("WOUND_INDEX ",index)
 assert(index>=0)
 var first_ms: float=actor.get_meta("last_wound_ms")
 var initial_nodes: int=get_node_count()
 for i: int in 55:assert(pool.add_wound(actor,point+Vector3(0,0,.4),Vector3.BACK)>=0)
 var active: int=0
 for slot: Dictionary in pool.slots:
  if slot.owner==actor.get_instance_id():active+=1
 assert(active==50);assert(get_node_count()==initial_nodes)
 var slot: Dictionary=pool.slots[index]
 assert(slot.socket.get_parent()==actor.skeleton)
 var local: Transform3D=slot.visual.transform
 var cached_ms: float=actor.get_meta("last_wound_ms")
 enemy.take_damage(100000,enemy.global_position+Vector3.UP*1.7,true,true)
 for i: int in 180:await physics_frame
 assert(slot.owner==actor.get_instance_id())
 assert(slot.visual.transform.is_equal_approx(local))
 actor.free();await process_frame
 for entry: Dictionary in pool.slots:assert(is_instance_valid(entry.socket))
 game.set_gore_level(0)
 for entry: Dictionary in pool.slots:assert(entry.owner==0 and not entry.visual.visible)
 game.start_run(true);await physics_frame
 print("WOUND_POOL_PASS active_limit=50 global=",pool.slots.size()," new_nodes_on_55_hits=0 first_wound_ms=",first_ms," cached_wound_ms=",cached_ms)
 game.free();await process_frame;quit()
