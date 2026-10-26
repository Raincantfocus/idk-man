extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game: Node=load("res://scenes/main.tscn").instantiate();game.is_test=true;root.add_child(game);game.start_run(true);game.set_process(false);game.player.set_physics_process(false)
 var enemy: Node=game.enemies[0];enemy.take_damage(100000,enemy.global_position+Vector3.UP*1.7,true,true)
 for i: int in 2:await physics_frame
 var actor: Node=game.presentation.corpse_nodes[-1]
 game.player.ability_delay=0;game.player.toggle_ability("focus")
 var before: float=actor.elapsed+actor.handoff_elapsed
 for i: int in 6:await physics_frame
 var world_delta: float=actor.elapsed+actor.handoff_elapsed-before
 var result: Dictionary={"focus_six_ticks_world_seconds":world_delta,"time_scale":Engine.time_scale,"focus_pass":world_delta>0 and world_delta<.02}
 root.focus_exited.emit();result.focus_loss_signal_pass=game.state=="paused";before=actor.elapsed+actor.handoff_elapsed
 for i: int in 6:await physics_frame
 result.pause_pass=actor.elapsed+actor.handoff_elapsed==before
 game.resume_game();game.player.end_ability()
 var file:=FileAccess.open("res://data/playtest/results/lifecycle.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close();print("LIFECYCLE ",JSON.stringify(result))
 game.free();await process_frame;quit(0 if result.focus_pass and result.pause_pass else 1)
