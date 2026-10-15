extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 game.is_test = true
 root.add_child(game)
 game.set_process(false)
 game.hud.visible = false
 game.menu_camera.position = Vector3(18,11,-12)
 game.menu_camera.look_at(Vector3(-7,1,3))
 for i in 6: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://test-output/warehouse-overview.png")
 game.menu_camera.position = Vector3(-26,6,3)
 game.menu_camera.look_at(Vector3(8,1,0))
 for i in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://test-output/warehouse-office.png")
 game.arena.apply_wave(9)
 for i in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://test-output/warehouse-emergency.png")
 game.free()
 await process_frame
 quit()
