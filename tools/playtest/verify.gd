extends SceneTree
var game: Node
var report: Dictionary={"checks":[],"scope":"Real-map automated integration; accelerated director clock and scripted lethal hits, not a difficulty playthrough"}
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
 report.checks.append({"check":label,"pass":ok})
 if not ok:failures+=1;push_error(label)
 print("CHECK ",ok," ",label)
func ticks(count: int) -> void:
 for i: int in count:await physics_frame
func kill_all() -> void:
 for enemy: Node in game.enemies.duplicate():
  if is_instance_valid(enemy):enemy.take_damage(100000,enemy.global_position+Vector3.UP*1.7,true,true)
func economy(mode: int) -> Dictionary:
 game.start_run(true);game.set_gore_level(mode)
 for enemy: Node in game.enemies:enemy.free()
 game.enemies.clear();game.rng.seed=44117;game.presentation.reset_run()
 for role: String in ["rusher","enforcer","shield","flusher","elite"]:
  var enemy: Node=game.spawn_enemy(role,Vector3(0,.03,10));enemy.training_dummy=true
  enemy.take_damage(100000,enemy.global_position+Vector3.UP*1.7,true,true)
  enemy.take_damage(100000,enemy.global_position+Vector3.UP*1.7,true,true)
 var drops: Array=[]
 for pickup: Node in game.pickups:drops.append(pickup.kind)
 return {"kills":game.kills,"score":game.score,"credits":game.credits,"drops":drops,"rng":game.rng.state}
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
 await ticks(2)
 var off: Dictionary=economy(0);await ticks(2)
 var full: Dictionary=economy(2);await ticks(2)
 report.economy={"off":off,"full":full};check(off==full,"Off/Full identical kills, score, credits, drops and gameplay RNG; duplicate lethal calls ignored")
 game.presentation.new_enemies=false
 var old_off: Dictionary=economy(0);await ticks(2)
 var old_full: Dictionary=economy(2);await ticks(2)
 report.legacy_economy={"off":old_off,"full":old_full};check(old_off==old_full,"Legacy Off/Full rewards and gameplay RNG identical")
 game.presentation.new_enemies=true
 game.start_run();game.set_process(false);game.player.set_physics_process(false)
 var seen: Dictionary={};var wave_rows: Array=[]
 for wave: int in range(1,11):
  var initial: int=game.kills
  var steps: int=0
  while game.state not in ["shop","complete"] and steps<5000:
   game.player.health=100;game.player.armor=100
   game._process(.25)
   for enemy: Node in game.enemies:seen[enemy.kind]=true
   kill_all()
   await ticks(1);steps+=1
  wave_rows.append({"wave":wave,"kills":game.kills-initial,"steps":steps,"state":game.state})
  check(game.state in ["shop","complete"],"Wave "+str(wave)+" resolves via real director")
  if wave<10:game.start_wave()
 report.waves=wave_rows;check(seen.size()==5,"All five roles spawned through director")
 # Pause and focus use real scene-tree/world-time behavior.
 game.start_run(true);await ticks(2)
 var sample: Node=game.enemies[0];sample.take_damage(100000,sample.global_position+Vector3.UP*1.7,true,true);await ticks(2)
 var actor: Node=game.presentation.corpse_nodes[-1];var before: float=actor.handoff_elapsed
 game.pause_game();await ticks(6);check(actor.handoff_elapsed==before,"Pause freezes corpse clock");game.resume_game()
 Engine.time_scale=.2;before=actor.handoff_elapsed;await ticks(6);report.focus_world_delta=actor.handoff_elapsed-before;Engine.time_scale=1
 game.start_run(true);await ticks(4);var count_before: int=get_node_count()
 game.start_run(true);await ticks(4);var count_after: int=get_node_count()
 report.restart_nodes={"before":count_before,"after":count_after};check(count_before==count_after,"Restart node count stable")
 game.presentation.toggle_models();check(not game.presentation.new_enemies,"Old model toggle works")
 game.presentation.toggle_models();check(game.presentation.new_enemies,"New model toggle works")
 var file:=FileAccess.open("res://test-output/playtest-integration.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 game.free();await process_frame;print("PLAYTEST_VERIFICATION failures=",failures);quit(1 if failures else 0)
