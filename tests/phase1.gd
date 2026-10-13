extends SceneTree
## Real collision and navigation checks for the expanded movement blockout.
var game
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func ticks(count: int) -> void:
	for i in count:
		await physics_frame

func place_player(point: Vector3, yaw: float = 0) -> void:
	for action in ["forward", "sprint", "jump", "slide"]:
		Input.action_release(action)
	game.player.position = point
	game.player.rotation.y = yaw
	game.player.velocity = Vector3.ZERO
	game.player.slide_time = 0
	game.player.end_ability()
	await ticks(10)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	root.add_child(game)
	game.set_process(false)
	game.start_run(true)
	await ticks(3)
	check(game.practice and game.wave == 0 and game.queue.is_empty() and game.enemies.size() == 3, "movement lab starts without wave pressure")
	var arena = game.arena
	for side in [-1, 1]:
		var route: PackedVector3Array = arena.path_to(Vector3(side * 26, 0, 33), Vector3(side * 29, 8.4, -30))
		var valid := route.size() > 40
		var saw_mid := false
		for i in route.size():
			saw_mid = saw_mid or is_equal_approx(route[i].y, 4.2)
			if i > 0:
				valid = valid and absf(route[i].y - route[i - 1].y) <= 0.35
		check(valid and saw_mid and route[-1].y > 8, "continuous three-tier AI route on side %d" % side)
	for point in arena.spawn_points:
		var route: PackedVector3Array = arena.path_to(point, arena.PLAYER_START)
		check(route.size() > 0, "spawn connects to ground: " + str(point))
	# Walk the actual convex ramp colliders, not just the navigation graph.
	for side in [-1, 1]:
		await place_player(Vector3(side * 26, 0.05, 32))
		Input.action_press("forward")
		Input.action_press("sprint")
		await ticks(300)
		check(game.player.position.y > 4.1 and game.player.position.z < 14, "player climbs ground ramp on side %d" % side)
		await place_player(Vector3(side * 29, 4.25, -3))
		Input.action_press("forward")
		Input.action_press("sprint")
		await ticks(300)
		check(game.player.position.y > 8.3 and game.player.position.z < -22, "player climbs upper ramp on side %d" % side)
	await place_player(Vector3(-12, 0.05, 32))
	Input.action_press("forward")
	Input.action_press("sprint")
	await ticks(40)
	Input.action_press("slide")
	await ticks(42)
	Input.action_release("slide")
	await ticks(20)
	check(game.player.position.z < 28.75 and game.player.position.z > 23.25 and game.player.capsule.shape.height < 1.1, "slide enters tunnel and ceiling prevents standing")
	await ticks(100)
	check(game.player.position.z < 23 and game.player.capsule.shape.height > 1.7, "player exits slide tunnel and stands clear")
	await place_player(Vector3(0, 8.45, -10), PI)
	Input.action_press("forward")
	Input.action_press("sprint")
	await ticks(66)
	Input.action_press("jump")
	await ticks(95)
	check(game.player.position.z > 0 and game.player.position.z < 8 and game.player.position.y > 8.3, "sprint jump crosses four-meter upper gap")
	await place_player(Vector3(38, 3.5, 22))
	Input.action_press("jump")
	await ticks(20)
	game.player.position = Vector3(40.1, 2.5, 22)
	game.player.velocity = Vector3(0, 0, -9)
	Input.action_press("forward")
	await ticks(30)
	check(game.player.mode == "WALL RUN" and game.player.wall_time > 0 and game.player.position.z < 20, "wall-run lane supports sustained travel")
	await place_player(Vector3(0, 0.05, 31))
	# An actual enemy must climb, including the path follower's repeated replans.
	var enemy = game.spawn_enemy("rusher", Vector3(26, 0.05, 31))
	enemy.speed = 9
	enemy.last_known = Vector3(26, 4.2, 10)
	enemy.sight_timer = 100
	enemy.sees_player = false
	enemy.attack_timer = 100
	await ticks(360)
	check(enemy.position.y > 4.1 and enemy.position.z < 14, "enemy physically climbs ground ramp")
	enemy.position = Vector3(29, 4.25, -3)
	enemy.velocity = Vector3.ZERO
	enemy.last_known = Vector3(29, 8.4, -27)
	enemy.path_timer = 0
	await ticks(400)
	check(enemy.position.y > 8.3 and enemy.position.z < -22, "enemy physically climbs upper ramp")
	enemy.queue_free()
	# Real corpse setup, constrained bodies, pause, time dilation, and budgets.
	game.is_test = false
	var source = game.spawn_enemy("enforcer", Vector3(5, 3, 25))
	source.training_dummy = true
	var corpse = game.spawn_corpse(source.body, source.position, source.color)
	source.queue_free()
	check(corpse.bodies.size() == 6 and corpse.joints.size() == 5, "ragdoll has six bodies and five working joints")
	await ticks(120)
	var torso: RigidBody3D = corpse.bodies.torso
	check(torso.position.y < 3 and torso.position.y > 0, "ragdoll falls and collides with the floor")
	var before: Vector3 = torso.global_position
	game.pause_game()
	await ticks(20)
	check(torso.global_position.distance_to(before) < 0.001, "pause freezes articulated corpse")
	game.resume_game()
	Engine.time_scale = 0.2
	var age_before: float = corpse.age
	await ticks(60)
	check(corpse.age - age_before < 0.15, "Focus slows ragdoll simulation lifetime")
	Engine.time_scale = 1
	for i in range(12):
		var dummy = game.spawn_enemy("enforcer", Vector3(8 + i, 0.1, 32))
		game.spawn_corpse(dummy.body, dummy.position, dummy.color)
		dummy.queue_free()
		await ticks(1)
	var active_count := 0
	for body in game.corpses:
		if body.active:
			active_count += 1
	check(active_count <= 6 and game.corpses.size() <= 10, "ragdoll active and retained counts stay bounded")
	await ticks(740)
	var stable := true
	for body in game.corpses:
		stable = stable and not body.active
		for part in body.bodies.values():
			stable = stable and part.freeze and part.global_position.is_finite() and part.global_position.y > -0.5
	check(stable, "ragdolls settle without falling through the world")
	game.start_run(true)
	await ticks(2)
	check(get_nodes_in_group("corpse").is_empty() and game.practice, "lab restart clears bodies and keeps practice mode")
	game.player.toggle_ability("focus")
	game.pause_game()
	game.return_to_menu()
	await ticks(2)
	check(game.state == "menu" and not paused and Engine.time_scale == 1 and get_nodes_in_group("enemy").is_empty(), "return to title clears practice and restores time")
	game.start_run()
	check(not game.practice and game.wave == 1 and game.queue.size() > 0, "normal trial remains available after practice")
	game.free()
	print("PHASE 1 RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
