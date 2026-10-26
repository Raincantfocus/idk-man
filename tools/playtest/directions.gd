extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game: Node=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.start_run(true);game.set_process(false);game.player.set_physics_process(false)
 for e: Node in game.enemies:e.free()
 game.enemies.clear()
 var rows: Array=[]
 for role: String in ["rusher","enforcer","shield","flusher","elite"]:
  for side: String in ["front","back","left","right"]:
   game.presentation.clear_corpses();await physics_frame
   var offset: Vector3={"front":Vector3(0,0,8),"back":Vector3(0,0,-8),"left":Vector3(-8,0,0),"right":Vector3(8,0,0)}[side]
   game.player.position=Vector3(0,.03,5)+offset
   var enemy: Node=game.spawn_enemy(role,Vector3(0,.03,5));enemy.set_physics_process(false)
   enemy.take_damage(100000,enemy.global_position+Vector3.UP*1.7,true,true)
   var actor: Node=game.presentation.corpse_nodes[-1]
   for i: int in 1350:await physics_frame
   var row: Dictionary={"role":role,"direction":side,"clip":String(actor.selected.id) if actor.selected else "obstructed_direct_ragdoll","animation_seconds":actor.elapsed,"handoff":actor.handoff_count,"state":actor.State.keys()[actor.state],"reason":actor.reason,"deaths":actor.lethal_events_received}
   rows.append(row);print("DIRECTION ",JSON.stringify(row))
 var out:=FileAccess.open("res://test-output/playtest-directions.json",FileAccess.WRITE);out.store_string(JSON.stringify(rows,"  "));out.close()
 game.free();await process_frame;quit()
