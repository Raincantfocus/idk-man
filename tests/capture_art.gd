extends SceneTree
## Optional native visual inspection. Requires a rendered display (not --headless).
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	root.add_child(game)
	game.set_process(false)
	game.hud.visible = false
	var elite = game.spawn_enemy("elite", Vector3(6.7, 0.05, 10.8))
	elite.set_physics_process(false)
	elite.animated_visual.update_pose(0.4, 0, false)
	game.menu_camera.position = Vector3(4.2, 1.8, 7.5)
	game.menu_camera.fov = 65
	game.menu_camera.look_at(Vector3(6.7, 1.0, 10.8))
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output")
	var result := root.get_texture().get_image().save_png("res://test-output/phase2-elite.png")
	game.free()
	await process_frame
	quit(result)
