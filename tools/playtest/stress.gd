extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(960,600)
 var game: Node=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.start_run(true);game.set_process(false);game.player.set_physics_process(false)
 for e: Node in game.enemies:e.free()
 game.enemies.clear();game.set_gore_level(2)
 game.player.position=Vector3(0,.05,-8);game.player.rotation.y=PI;game.player.camera.current=true
 for i: int in 36:
  var e: Node=game.spawn_enemy(["rusher","enforcer","shield","flusher","elite"][i%5],Vector3(-9+(i%6)*3,.05,2+(i/6)*1.5))
  e.training_dummy=true
 for i: int in 6:
  var e: Node=game.enemies[-1];e.take_damage(100000,e.global_position+Vector3.UP*1.7,true,true)
 for i: int in 96:game.presentation.pools.add_pool(i,Vector3(-9+(i%12)*1.5,.001,-7+(i/12)*1.2),Vector3.UP,1)
 var timings: Array[float]=[];var peak_active: int=0;var peak_corpses: int=0
 var previous: int=Time.get_ticks_usec()
 for frame: int in 180:
  await process_frame
  var now: int=Time.get_ticks_usec()
  if frame>29:timings.append((now-previous)/1000.0)
  previous=now
  var active: int=0
  for actor: Node in game.presentation.corpse_nodes:
   if is_instance_valid(actor) and actor.is_simulating():active+=1
  peak_active=maxi(peak_active,active);peak_corpses=maxi(peak_corpses,game.presentation.corpse_nodes.size())
 var total: float=0
 for ms: float in timings:total+=ms
 var report: Dictionary={"renderer":RenderingServer.get_video_adapter_name(),"driver":RenderingServer.get_current_rendering_method(),"viewport":[960,600],"average_frame_ms":total/timings.size(),"worst_frame_ms":timings.max(),"samples":timings.size(),"enemies":game.enemies.size(),"peak_active_ragdolls":peak_active,"peak_corpses":peak_corpses,"decals":game.presentation.blood_budget.total(&"decals"),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"valid_hardware_performance":false,"notes":"Software-rendered llvmpipe; fixed world clock; full real warehouse, 30 living enemies, six dying actors, 96 pools. Not a target-PC benchmark."}
 var file:=FileAccess.open("res://test-output/playtest-stress.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close();print("STRESS ",JSON.stringify(report))
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test-output/playtest_stress.png")
 game.free();await process_frame;quit()
