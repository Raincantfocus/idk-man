extends SceneTree
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	root.add_child(game)
	game.set_process(false)
	game.hud.visible = false
	game.menu_camera.position = Vector3(0, 3.2, 24)
	game.menu_camera.fov = 55
	game.menu_camera.look_at(Vector3(0, .4, 28))
	var enemy = game.spawn_enemy("enforcer", Vector3(0,.05,28))
	enemy.set_physics_process(false)
	game.is_test = false
	game.gore_enabled = true
	var corpse = game.spawn_corpse(enemy.body, enemy.position, enemy.color)
	game.is_test = true
	enemy.free()
	corpse.sever("left_arm")
	corpse.sever("head")
	for i in 70: await physics_frame
	corpse.settle()
	var center: Vector3 = corpse.bodies.torso.global_position
	print("BODY POSITIONS ", corpse.bodies.values().map(func(b): return b.global_position))
	game.menu_camera.position = center + Vector3(0, 5, -5)
	game.menu_camera.look_at(center)
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/dismemberment.png")
	game.free()
	await process_frame
	quit()
