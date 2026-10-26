extends SceneTree
var game: Node
var report: Dictionary={}
var cut_times: Array=[]
func _initialize() -> void:call_deferred("run")
func economy(mode: int) -> Dictionary:
 game.start_run(true);game.set_gore_level(mode)
 for enemy: Node in game.enemies:enemy.free()
 game.enemies.clear();game.rng.seed=44117
 for role: String in ["rusher","enforcer","shield","flusher","elite"]:
  var enemy: Node=game.spawn_enemy(role,Vector3(0,.03,5));enemy.set_physics_process(false)
  enemy.take_damage(10000,enemy.global_position+Vector3.UP*1.7,true,true)
  if mode>0:cut_times.append({"mode":mode,"role":role,"cut_ms":game.presentation.corpse_nodes[-1].get_meta("last_cut_ms")})
  enemy.take_damage(10000,enemy.global_position+Vector3.UP*1.7,true,true)
 var drops: Array=[]
 for pickup: Node in game.pickups:drops.append(pickup.kind)
 return {"kills":game.kills,"score":game.score,"credits":game.credits,"drops":drops,"rng":game.rng.state}
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();game.is_test=true;root.add_child(game);game.set_process(false)
 report.off=economy(0);await physics_frame
 report.reduced=economy(1);await physics_frame
 report.full=economy(2);await physics_frame
 assert(report.off==report.reduced and report.off==report.full)
 for i: int in 18:
  var enemy: Node=game.spawn_enemy("enforcer",Vector3(0,.03,5));enemy.set_physics_process(false)
  enemy.take_damage(10000,enemy.global_position+Vector3.UP*1.7,true,true);await physics_frame
 assert(game.presentation.blood_budget.total(&"gibs")<=16)
 assert(get_nodes_in_group("gib").size()<=16)
 report.last_warm_head_cut_ms=game.presentation.corpse_nodes[-1].get_meta("last_cut_ms")
 report.budget_gibs=game.presentation.blood_budget.total(&"gibs");report.actual_gibs=get_nodes_in_group("gib").size()
 var actor: Node=game.presentation.corpse_nodes[-1];var gore: Node=actor.get_meta("gore_presenter")
 assert(gore.sever("right_leg",Vector3.RIGHT));assert(not gore.sever("right_leg",Vector3.RIGHT))
 var kills: int=game.kills
 for i: int in 1100:await physics_frame
 var forwards: int=0
 for child: Node in actor.get_children():
  if child is StaticBody3D and child.has_method("take_damage"):forwards+=1
 assert(forwards>0);report.frozen_hit_forwarders=forwards
 var point: Vector3=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("LeftHand")).origin
 for child: Node in actor.get_children():
  if child is StaticBody3D and child.has_method("take_damage"):
   child.call("take_damage",10000,point,false,true);break
 assert(gore.cuts.has("left_arm"));report.settled_hit_sever_pass=true
 assert(actor.handoff_count==1 and game.kills==kills)
 game.set_gore_level(0);await physics_frame;await physics_frame
 assert(get_nodes_in_group("gib").is_empty());report.off_clears_gibs=true
 game.start_run(true);await physics_frame;var count_before: int=get_node_count()
 game.start_run(true);await physics_frame;var count_after: int=get_node_count()
 assert(count_before==count_after);report.restart_nodes=[count_before,count_after]
 report.cut_times=cut_times
 var file:=FileAccess.open("res://data/playtest/results/new_gore_contracts.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 game.free();await process_frame;print("NEW_GORE_CONTRACTS_PASS ",JSON.stringify(report));quit()
