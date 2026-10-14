extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	root.add_child(game)
	game.set_process(false)
	game.start_run(true)
	game.hud.visible = false
	var p = game.player
	p.set_physics_process(false)
	p.position = Vector3(0, 0.05, 31)
	p.rotation.y = 0
	DirAccess.make_dir_recursive_absolute("res://test-output")
	for i in 3:
		p.switch_weapon(i)
		p.recoil = 0
		p.weapon_view.equip_time = 0
		for mode in ["hip", "ads", "reload"]:
			if mode == "ads": Input.action_press("aim")
			else: Input.action_release("aim")
			p.reload_time = 0
			if mode == "reload":
				p.ammo[i] = 5
				p.begin_reload()
				p._reload_tick(p.reload_total * 0.36)
			for j in 70: p._visuals(1.0/120.0)
			for j in 4: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test-output/weapon-%d-%s.png" % [i, mode])
	Input.action_release("aim")
	game.free()
	await process_frame
	quit()
