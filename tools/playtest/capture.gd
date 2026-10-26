extends SceneTree
var game: Node
func _initialize() -> void:call_deferred("run")
func save(name: String) -> void:
 await process_frame;RenderingServer.force_draw(true)
 root.get_texture().get_image().save_png("res://test-output/playtest_"+name+".png")
 print("CAPTURE ",name)
func run() -> void:
 root.size=Vector2i(960,600)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.start_run(true);game.set_process(false)
 game.player.set_physics_process(false);game.hud.visible=false
 for child: Node in game.presentation.get_children():
  if child is CanvasLayer:child.visible=false
 for enemy: Node in game.enemies:enemy.free()
 game.enemies.clear()
 var origin:=Vector3(-25,.05,-8);var facing:=Vector3.RIGHT
 await physics_frame
 var found: bool=false
 for z: int in range(-11,12,2):
  for x: int in range(-26,7,2):
   var start:=Vector3(x,1.6,z)
   var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,start+Vector3.RIGHT*22,1))
   var safe: bool=hit.is_empty()
   for distance: int in [0,5,20]:
    var point: Vector3=Vector3(x,.05,z)+Vector3.RIGHT*distance
    var shape:=CapsuleShape3D.new();shape.radius=.4;shape.height=1.8
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=point+Vector3.UP*.9;query.collision_mask=1
    safe=safe and game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
    var floor_hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*.1,point-Vector3.UP*.2,1))
    safe=safe and not floor_hit.is_empty()
   if safe:origin=Vector3(x,.05,z);found=true;break
  if found:break
 assert(found,"Need a clear real-map camera lane")
 print("CAMERA_LANE ",origin)
 game.player.position=origin;game.player.rotation.y=-PI/2;game.player.pitch=0;game.player.camera.rotation=Vector3.ZERO;game.player.camera.current=true
 game.player.weapon_view.visible=false
 for role: String in ["rusher","enforcer","shield","flusher","elite"]:
  for distance: int in [5,20]:
   var enemy: Node=game.spawn_enemy(role,origin+facing*distance);enemy.set_physics_process(false);enemy.body.rotation.y=PI/2
   enemy.animated_visual.update_pose(.2,0,false)
   for i: int in 3:await process_frame
   await save(role+"_"+str(distance)+"m");enemy.free();game.enemies.clear()
 game.set_gore_level(2)
 var enemy: Node=game.spawn_enemy("enforcer",origin+facing*5);enemy.set_physics_process(false)
 game.presentation.forced_clip="death";enemy.take_damage(100000,enemy.global_position+Vector3.UP*1.7,true,true)
 for i: int in 1100:await physics_frame
 game.player.position=origin+facing*2.5;game.player.camera.rotation.x=-.35
 await save("new_corpse_pool")
 game.presentation.clear_corpses();await physics_frame
 game.presentation.toggle_models()
 enemy=game.spawn_enemy("enforcer",origin+facing*5);enemy.set_physics_process(false)
 enemy.take_damage(100000,enemy.global_position+Vector3.UP*1.7,true,true)
 for i: int in 400:await physics_frame
 await save("legacy_dismemberment")
 var wall: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin+Vector3.UP,origin+Vector3.UP+Vector3(0,0,-5),1))
 if not wall.is_empty():
  game.blood_burst(wall.position+wall.normal*.1,-wall.normal,12)
  for i: int in 180:await physics_frame
  game.player.global_position=wall.position+wall.normal*2-Vector3.UP*.6
  game.player.camera.look_at(wall.position,Vector3.UP)
  await save("blood_wall")
 game.free();await process_frame;quit()
