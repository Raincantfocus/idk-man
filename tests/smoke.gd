extends SceneTree
## Executes real game components and physics queries; exits nonzero on failure.
var game
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func settle() -> void:
	await physics_frame
	await physics_frame

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	root.add_child(game)
	game.set_process(false)
	game.start_run()
	game.state = "shop"
	await settle()
	var p = game.player
	var expected := [8, 12, 14, 16, 17, 22, 24, 25, 29, 30]
	for i in range(10):
		var total: int = 0
		for count in game.balance.waves[i].roster.values():
			total += int(count)
		check(total == expected[i], "wave %d roster contains %d enemies" % [i + 1, expected[i]])
	game.state = "combat"
	p.take_damage(40, Vector3.ZERO)
	check(is_equal_approx(p.health, 90) and is_equal_approx(p.armor, 45), "armor absorbs 75% with health leakage")
	p.armor = 5
	p.take_damage(20, Vector3.ZERO)
	check(is_equal_approx(p.health, 75) and p.armor == 0, "armor overflow transfers to health")
	game.state = "shop"
	var med = game.spawn_pickup(Vector3(5, 0.3, 10), "health")
	med.freeze = true
	med.state = med.State.AVAILABLE
	p.health = 100
	check(med.collect(p) == 0 and med.remaining == 20, "full-health pickup stays available")
	p.health = 95
	check(med.collect(p) == 5 and med.remaining == 15 and p.health == 100, "partial pickup retains unused quantity")
	p.health = 80
	check(med.collect(p) == 15 and p.health == 95, "second transfer consumes partial remainder")
	check(med.collect(p) == 0 and med.transfer_sequence == 2, "consumed pickup cannot duplicate transfer")
	var swept = game.spawn_pickup(Vector3(8, 0.3, 10), "health")
	swept.freeze = true
	swept.state = swept.State.AVAILABLE
	p.health = 40
	await settle()
	game.collect_along(Vector3(5, 0.55, 10), Vector3(11, 0.55, 10))
	check(p.health == 60, "swept collection catches a drop between frame endpoints")
	var blocked = game.spawn_pickup(Vector3(-2.85, 0.3, -1.5), "health")
	blocked.freeze = true
	blocked.state = blocked.State.AVAILABLE
	await settle()
	game.collect_along(Vector3(-3.7, 0.55, -1.5), Vector3(-3.7, 0.55, -1.5))
	check(p.health == 60 and blocked.remaining == 20, "solid world geometry prevents through-wall pickup")
	p.health = 0
	check(blocked.collect(p) == 0, "pickup cannot resurrect a dead player")
	p.health = 100
	p.ability_delay = 0
	check(p.toggle_ability("focus") and is_equal_approx(Engine.time_scale, 0.2), "Focus applies world slow motion")
	p._abilities(1.0)
	check(is_equal_approx(p.focus, 65), "Focus spends entry cost and real-time drain")
	p.end_ability()
	check(Engine.time_scale == 1 and p.ability == "", "Focus cleanup restores normal time")
	p.ability_delay = 0
	check(p.toggle_ability("shroud"), "Shroud activates independently")
	var enemy = game.spawn_enemy("enforcer", Vector3(0, 0.05, 8))
	game.state = "shop"
	await settle()
	check(not enemy._can_see_player(), "Shroud blocks fresh AI visual acquisition")
	p.shot_timer = 0
	p.reload_time = 0
	game.state = "combat"
	p.fire()
	check(p.ability == "" and Engine.time_scale == 1, "offensive shot breaks Shroud")
	game.state = "shop"
	p.ammo[0] = 9
	p.reserve[0] = 50
	p.reload_time = 0
	check(p.begin_reload(), "partial magazine starts reload")
	p._reload_tick(0.6)
	check(p.ammo[0] == 0 and p.reserve[0] == 59, "magazine-out conserves ammunition")
	p.switch_weapon(1)
	p.switch_weapon(0)
	check(p.ammo[0] == 0 and p.reserve[0] == 59, "weapon switching preserves interrupted mechanical state")
	p.begin_reload()
	p._reload_tick(1.5)
	check(p.ammo[0] == 30 and p.reserve[0] == 29, "reload insertion transfers ammunition exactly once")
	p._reload_tick(1.0)
	check(p.ammo[0] + p.reserve[0] == 59, "reload completion does not duplicate ammunition")
	# Clear test debris, then exercise an actual camera/muzzle ray against a target.
	game.start_run()
	game.state = "shop"
	p = game.player
	var target = game.spawn_enemy("enforcer", Vector3(0, 0.05, 8))
	await settle()
	game.state = "combat"
	p.fire()
	game.state = "shop"
	check(target.health < 100, "camera and muzzle trace damage an actual enemy collider")
	var old_kills: int = game.kills
	target.take_damage(1000, target.global_position + Vector3.UP, false)
	target.take_damage(1000, target.global_position + Vector3.UP, false)
	check(game.kills == old_kills + 1 and game.enemies.is_empty(), "duplicate lethal hits commit one death and roster decrement")
	check(game.pickups.size() == 1, "one death creates one primary recovery drop")
	game.queue.clear()
	game.pending.clear()
	game.state = "combat"
	game._director(0.1)
	check(game.state == "resolve", "wave waits for hazard resolution after final death")
	game.resolve_timer = 0
	game._finish_wave()
	check(game.state == "shop" and game.credits >= 150, "wave clear grants credits and opens intermission")
	var earned: int = game.credits
	game._finish_wave()
	check(game.credits == earned, "wave-clear rewards are idempotent")
	check(not game.purchase("capacitor"), "shop rejects unaffordable purchase")
	game.credits = 500
	check(game.purchase("pickup") and game.credits == 250, "purchase spends credits and applies recovery upgrade")
	check(not game.purchase("pickup") and game.credits == 250, "duplicate purchase cannot charge or stack")
	game.state = "combat"
	p.ability_delay = 0
	p.toggle_ability("focus")
	game.pause_game()
	var charge: float = p.focus
	await create_timer(0.05, true, false, true).timeout
	check(p.focus == charge and paused, "pause freezes Focus consumption")
	game.resume_game()
	check(not paused and game.state == "combat", "resume restores active run")
	game.start_run()
	game.state = "shop"
	await settle()
	check(Engine.time_scale == 1 and game.player.health == 100, "restart restores time and player state")
	check(get_nodes_in_group("enemy").is_empty() and get_nodes_in_group("projectile").is_empty() and get_nodes_in_group("pickup").is_empty(), "restart removes old actors and hazards")
	check(game.wave == 1 and game.kills == 0 and game.credits == 0, "restart clears run progression")
	# Navigation routes around the central reactor instead of crossing it.
	var route: PackedVector3Array = game.arena.path_to(Vector3(-6, 0, -1), Vector3(6, 0, -1))
	var valid_route := route.size() > 2
	for point in route:
		if Rect2(-3, -4.5, 6, 6).grow(0.36).has_point(Vector2(point.x, point.z)):
			valid_route = false
	check(valid_route, "enemy navigation routes around structural cover")
	# Equal physics-tick windows avoid wall-clock timer jitter on shared CI machines.
	var distances: Array[float] = []
	for use_focus in [false, true]:
		game.start_run()
		p = game.player
		p.position = Vector3(4, 0.04, 12)
		for warmup_tick in range(20):
			await physics_frame
		p.velocity = Vector3.ZERO
		if use_focus:
			p.ability_delay = 0
			p.toggle_ability("focus")
		var start: Vector3 = p.global_position
		Input.action_press("forward")
		Input.action_press("sprint")
		for movement_tick in range(42):
			await physics_frame
		Input.action_release("forward")
		Input.action_release("sprint")
		distances.append(Vector2(p.global_position.x - start.x, p.global_position.z - start.z).length())
		p.end_ability()
		game.state = "shop"
	check(distances[0] > 1.5, "sprint input produces real swept movement")
	check(absf(distances[0] - distances[1]) < 0.25, "Focus preserves player travel speed within frame tolerance")
	print("Movement distances normal/focus: ", distances)
	print("\nRESULT: %d passed, %d failed" % [passed, failed])
	game.sound.stop_all()
	await create_timer(0.10, true, false, true).timeout
	game.free()
	await process_frame
	quit(1 if failed > 0 else 0)
