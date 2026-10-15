extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	root.add_child(game)
	game.set_process(false)
	game.hud.visible = false
	game.menu_camera.position = Vector3(0, 1.5, 24)
	game.menu_camera.fov = 65
	game.menu_camera.look_at(Vector3(0, 1, 28))
	for i in 5:
		var kind: String = ["enforcer", "rusher", "shield", "flusher", "elite"][i]
		var enemy = game.spawn_enemy(kind, Vector3((i - 2)*1.05, 0.03, 28))
		enemy.set_physics_process(false)
		enemy.animated_visual.update_pose(0.15, 0, false)
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output")
	root.get_texture().get_image().save_png("res://test-output/operators-lineup.png")
	game.free()
	await process_frame
	quit()
