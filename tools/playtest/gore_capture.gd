extends SceneTree
var game: Node
func _initialize() -> void:call_deferred("run")
func save(name: String) -> void:
 await process_frame;RenderingServer.force_draw(true)
 root.get_texture().get_image().save_png("res://test-output/gore_"+name+".png");print("CAPTURE ",name)
func run() -> void:
 root.size=Vector2i(1000,700)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.start_run(true);game.set_process(false);game.player.set_physics_process(false);game.hud.visible=false;game.player.weapon_view.visible=false
 for n: Node in game.presentation.get_children():
  if n is CanvasLayer:n.visible=false
 for e: Node in game.enemies:e.free()
 game.enemies.clear();game.set_gore_level(2)
 game.player.position=Vector3(0,.03,10);game.player.rotation.y=0;game.player.camera.current=true
 var enemy: Node=game.spawn_enemy("enforcer",Vector3(0,.03,5));enemy.set_physics_process(false)
 var actor: Node=enemy.animated_visual.actor
 enemy.take_damage(10000,enemy.global_position+Vector3.UP*1.7,true,true)
 for i: int in 8:await physics_frame
 var point: Vector3=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("Neck")).origin
 game.player.camera.global_position=point+Vector3(.4,.4,.5);game.player.camera.look_at(point)
 await save("neck_close")
 var gore: Node=actor.get_meta("gore_presenter");gore.sever("left_arm",Vector3.LEFT);gore.sever("right_leg",Vector3.RIGHT)
 for i: int in 1100:await physics_frame
 var hip: Vector3=actor.physical.Hips.global_position
 game.player.camera.global_position=hip+Vector3(1,2,2);game.player.camera.look_at(hip)
 await save("corpse_limbs")
 game.set_gore_level(0);await physics_frame;await save("off_restored")
 game.free();await process_frame;quit()
