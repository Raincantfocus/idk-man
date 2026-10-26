extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(1000,700)
 var game: Node=load("res://scenes/main.tscn").instantiate();game.is_test=true;root.add_child(game);game.start_run(true);game.set_process(false);game.player.set_physics_process(false);game.hud.visible=false;game.set_gore_level(2)
 for c: Node in game.presentation.get_children():
  if c is CanvasLayer:c.visible=false
 var enemy: Node=game.spawn_enemy("enforcer",Vector3(0,0,15));enemy.set_physics_process(false)
 for i: int in 3:await physics_frame
 var actor: Node=enemy.animated_visual.actor
 var chest: Vector3=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("Chest")).origin
 var camera:=Camera3D.new();game.add_child(camera);camera.position=chest+Vector3(0,.1,1.1);camera.look_at(chest);camera.current=true
 var light:=OmniLight3D.new();game.add_child(light);light.position=chest+Vector3(.5,.5,1);light.omni_range=3;light.light_energy=3
 var pool: Node=game.presentation.wound_pool
 var timings: Array=[]
 for offset: Vector3 in [Vector3(-.08,0,0),Vector3(.08,-.12,0),Vector3(0,.10,0)]:
  assert(pool.add_wound(actor,chest+offset+Vector3(0,0,.4),Vector3.BACK)>=0)
  timings.append(actor.get_meta("last_wound_ms"))
 await process_frame;RenderingServer.force_draw(true)
 root.get_texture().get_image().save_png("res://test-output/wound_"+RenderingServer.get_current_rendering_method()+".png")
 print("WOUND_CAPTURE renderer=",RenderingServer.get_current_rendering_method()," hit_ms=",timings)
 game.free();await process_frame;quit()
