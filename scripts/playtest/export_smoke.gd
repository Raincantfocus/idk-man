extends Node
## Debug-export-only startup probe; invoked with -- --playtest-smoke.
var game: Node
func _ready() -> void:call_deferred("run")
func run() -> void:
 for i: int in 4:await get_tree().physics_frame
 game.start_run(true);game.set_process(false);game.player.set_physics_process(false)
 for enemy: Node in game.enemies.duplicate():
  enemy.take_damage(100000,enemy.global_position+Vector3.UP*1.7,true,true)
 for i: int in 1000:await get_tree().physics_frame
 var states: Array=[]
 var clip_count: int=0
 var animated_count: int=0
 var valid: bool=game.kills==3
 for actor: Node in game.presentation.corpse_nodes:
  states.append(actor.State.keys()[actor.state]);valid=valid and actor.handoff_count==1
  clip_count=actor.clips.size()
  if actor.elapsed>0:animated_count+=1
 valid=valid and clip_count>=12 and animated_count>0
 print("EXPORTED_PLAYTEST_SMOKE ",JSON.stringify({"pass":valid,"loaded_clips":clip_count,"animated_corpses":animated_count,"kills":game.kills,"corpses":states,"debug_tools":ResourceLoader.exists("res://scripts/playtest/debug_tools.gd"),"engine":Engine.get_version_info().string}))
 get_tree().quit(0 if valid else 1)
