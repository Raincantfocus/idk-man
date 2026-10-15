extends SceneTree
var passed := 0
var failed := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	game.arena_factory = preload("res://tests/fixtures/arena_v08.gd")
	root.add_child(game)
	game.set_process(false)
	game.start_run(true)
	var p = game.player
	p.set_physics_process(false)
	p.switch_weapon(1)
	p.ammo[1] = 3
	p.reserve[1] = 5
	check(p.begin_reload(), "tube reload starts with partially filled shotgun")
	p._reload_tick(p.reload_total*.5)
	check(p.ammo[1] == 3 and p.reserve[1] == 5, "shell not committed before insertion finishes")
	p._reload_tick(p.reload_total*.5)
	check(p.ammo[1] == 4 and p.reserve[1] == 4, "one insertion adds exactly one shell")
	p.switch_weapon(0)
	p.switch_weapon(1)
	check(p.ammo[1] == 4 and p.reserve[1] == 4, "interrupted tube reload retains inserted shells")
	p.begin_reload()
	for i in 4: p._reload_tick(p.reload_total)
	check(p.ammo[1] == 8 and p.reserve[1] == 0 and p.reload_time == 0, "tube reload stops full without duplicating ammunition")
	p.weapon_view.update_pose(0)
	check(not p.weapon_view.magazines[1].visible, "loading shell is hidden outside tube reload")
	for stem in ["steel","cloth","skin","tissue","concrete"]:
		var mat = preload("res://scripts/surface_library.gd").make(stem)
		check(mat.albedo_texture.get_width() == 2048 and mat.normal_texture != null and mat.ao_texture == mat.roughness_texture and mat.metallic_texture == mat.roughness_texture, stem + " uses 2K albedo, normal and packed ORM")
	game.is_test = false
	game.gore_enabled = true
	for i in 8: game.blood_burst(Vector3(0,2,28), Vector3.DOWN, 12)
	check(get_nodes_in_group("blood_drop").size() == 48, "blood droplet cap is enforced")
	game.is_test = true
	for i in 90: await physics_frame
	check(get_nodes_in_group("blood_stain").size() > 0, "ballistic drops leave stains on actual world collisions")
	check(get_nodes_in_group("blood_stain").size() <= 64, "surface stain budget stays bounded")
	game.pause_game()
	var drop = get_nodes_in_group("blood_stain")[0]
	var age: float = drop.age
	for i in 5: await physics_frame
	check(drop.age == age, "pause freezes blood lifetime")
	game.resume_game()
	game.gore_enabled = false
	game.is_test = false
	game.blood_burst(Vector3.ZERO, Vector3.UP)
	check(get_nodes_in_group("blood_drop").is_empty(), "gore toggle blocks new blood emission")
	game.is_test = true
	game.start_run(true)
	check(get_nodes_in_group("blood_stain").is_empty(), "restart removes blood stains")
	game.sound.stop_all()
	game.free()
	await process_frame
	print("ART DAMAGE RESULT: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
