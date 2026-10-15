extends SceneTree
var game
var p
var view
var passed := 0
var failed := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)
func ticks(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	game.arena_factory = preload("res://tests/fixtures/arena_v08.gd")
	root.add_child(game)
	game.set_process(false)
	game.start_run(true)
	p = game.player
	p.set_physics_process(false)
	view = p.weapon_view
	check(view.models.size() == 3 and view.skeleton.get_bone_count() == 4, "three separate authored weapons and a four-bone deform rig load")
	for i in 3:
		p.switch_weapon(i)
		view.update_pose(0)
		var visible_count := 0
		for model in view.models: if model.visible: visible_count += 1
		check(visible_count == 1 and view.models[i].visible, "weapon %d selects exactly one model" % i)
		p.weapon_root.position = view.ads_position()
		p.weapon_root.rotation = Vector3.ZERO
		var line: Vector3 = p.camera.to_local(view.sights[i].global_position)
		check(absf(line.x) < 0.001 and absf(line.y) < 0.001, "weapon %d sight aligns with camera center" % i)
		check(view.muzzle_position().distance_to(p.camera.global_position) > 0.5, "weapon %d uses its actual barrel socket" % i)
	p.switch_weapon(0)
	p.ammo[0] = 9
	p.reserve[0] = 50
	p.begin_reload()
	p._reload_tick(p.reload_total * 0.30)
	view.update_pose(0)
	check(not p.magazine_seated[0] and view.magazines[0].position.y < -0.05 and p.ammo[0] + p.reserve[0] == 59, "magazine-out pose follows the authoritative ammo transfer")
	p.switch_weapon(1)
	p.switch_weapon(0)
	view.update_pose(0)
	check(not view.magazines[0].visible and p.ammo[0] == 0, "switching mid-reload preserves an empty magwell")
	p.begin_reload()
	view.update_pose(0)
	check(not view.magazines[0].visible, "restarting an interrupted reload does not resurrect the removed magazine")
	p._reload_tick(p.reload_total * 0.79)
	view.update_pose(0)
	check(p.magazine_seated[0] and view.magazines[0].visible and view.magazines[0].position.length() < 0.001 and p.ammo[0] + p.reserve[0] == 59, "magazine insertion restores pose without duplicating ammo")
	p.reload_time = 0
	p.switch_weapon(2)
	p.ammo[2] = 1
	p.shot_timer = 0
	check(p.fire(), "sidearm fires its final round")
	view.update_pose(0.2)
	check(view.actions[2].position.z > 0.04, "empty sidearm locks its slide back")
	p.begin_reload()
	view.update_pose(0)
	check(view.actions[2].position.z > 0.04, "empty slide stays locked while the magazine is replaced")
	p._reload_tick(p.reload_total)
	view.update_pose(0)
	check(is_zero_approx(view.actions[2].position.z) and p.ammo[2] == 12, "reloading releases the sidearm slide")
	for i in 20:
		p.shot_timer = 0
		p.ammo[2] = 12
		p.fire()
	var shells := get_nodes_in_group("shell_casing")
	check(shells.size() == view.MAX_CASINGS, "rapid firing enforces a twelve-casing budget")
	var safe := true
	for shell in shells: safe = safe and shell.collision_layer == 0 and shell.collision_mask == 1
	check(safe, "casings collide only with the arena and cannot hit actors")
	var age: float = shells[0].age
	game.pause_game()
	await ticks(8)
	check(shells[0].age == age, "pause freezes casing simulation")
	game.resume_game()
	p.ability_delay = 0
	p.toggle_ability("shroud")
	p._visuals(1.0/120)
	check(not p.weapon_root.visible, "Shroud hides both weapons and skeletal arms")
	p.end_ability()
	p.begin_reload()
	p._reload_tick(p.reload_total * 0.3)
	game.refill_practice_resources()
	view.update_pose(0)
	check(p.magazine_seated == [true, true, true] and view.magazines[2].visible, "practice refill restores magazines and cancels unfinished reload poses")
	game.start_run(true)
	check(get_nodes_in_group("shell_casing").is_empty(), "restart removes all spent casings")
	game.sound.stop_all()
	await create_timer(0.10, true, false, true).timeout
	game.free()
	await physics_frame
	await physics_frame
	await process_frame
	print("WEAPON ART RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
