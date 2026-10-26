extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game: Node=load("res://scenes/main.tscn").instantiate();game.is_test=true;root.add_child(game);game.start_run(true);game.set_process(false);game.player.set_physics_process(false)
 for e: Node in game.enemies:e.free()
 game.enemies.clear();game.set_gore_level(2)
 var enemy: Node=game.spawn_enemy("enforcer",Vector3(0,.03,5));enemy.set_physics_process(false)
 var actor: Node=enemy.animated_visual.actor
 enemy.take_damage(10000,enemy.global_position+Vector3.UP*1.7,true,true)
 var gore: Node=actor.get_meta("gore_presenter")
 print("HEAD_CUT ",gore.cuts," gibs=",game.presentation.blood_budget.total(&"gibs"))
 assert(gore.cuts.has("head"));assert(game.kills==1)
 assert(gore.sever("left_arm",Vector3.LEFT));assert(gore.sever("right_arm",Vector3.RIGHT));assert(gore.sever("left_leg",Vector3.FORWARD));assert(not gore.sever("right_leg",Vector3.BACK))
 assert(not gore.sever("head",Vector3.UP))
 for i: int in 1100:await physics_frame
 assert(actor.handoff_count==1 and game.kills==1)
 print("GORE_STATE ",actor.State.keys()[actor.state]," cuts=",gore.cuts.size()," gibs=",game.presentation.blood_budget.total(&"gibs"))
 game.set_gore_level(0);await physics_frame;assert(gore.cuts.is_empty());assert(game.presentation.blood_budget.total(&"gibs")==0)
 for mesh: MeshInstance3D in gore.originals:assert(mesh.mesh==gore.originals[mesh].mesh)
 game.free();await process_frame;print("NEW_GORE_TEST_PASS");quit()
