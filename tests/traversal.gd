extends SceneTree
var game
var p
var obstacle: Node3D
var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func ticks(count: int) -> void:
	for i in count:
		await physics_frame

func reset(height: float, depth: float) -> void:
	p.set_physics_process(false)
	p.traversal.cancel()
	p.traversal.cooldown = 0
	p.end_ability()
	p.position = Vector3(0, 0.05, 104)
	p.velocity = Vector3(0, 0, -9)
	p.rotation = Vector3.ZERO
	p.capsule.shape.height = 1.72
	p.capsule.position.y = 0.86
	if is_instance_valid(obstacle):
		obstacle.free()
	obstacle = game.arena.box(Vector3(0, height / 2, 103.2 - depth / 2), Vector3(4, height, depth), game.arena.concrete)
	await ticks(2)

func finish() -> int:
	p.set_physics_process(true)
	var frames := 0
	while p.traversal.active and frames < 150:
		await physics_frame
		frames += 1
	p.set_physics_process(false)
	return frames

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	root.add_child(game)
	game.set_process(false)
	game.start_run(true)
	p = game.player
	game.arena.box(Vector3(0, -0.5, 102), Vector3(20, 1, 20), game.arena.dark)
	await reset(1.1, 0.8)
	Input.action_press("forward")
	Input.action_press("jump")
	p.set_physics_process(true)
	await ticks(2)
	check(p.traversal.active, "forward plus Space enters traversal through normal player input")
	Input.action_release("forward")
	Input.action_release("jump")
	await finish()
	await reset(1.1, 0.8)
	check(p.traversal.try_start(Vector3.FORWARD) and p.traversal.kind == "VAULT", "low shallow cover selects vault")
	var normal_frames := await finish()
	check(p.position.z < 102.4 and p.position.y < 0.1 and not p.traversal.active, "vault crosses cover onto supported ground")
	check(p.velocity.z < -8, "vault preserves approach momentum")
	await reset(1.65, 3)
	check(p.traversal.try_start(Vector3.FORWARD) and p.traversal.kind == "MANTLE", "higher ledge selects mantle")
	await finish()
	check(p.position.y > 1.65 and p.position.z < 103.2, "mantle finishes on the ledge")
	await reset(1.65, 3)
	p.position.y = 0.65
	p.velocity.y = -1
	check(p.traversal.try_start(Vector3.FORWARD), "reachable ledge can be caught from the air")
	await finish()
	check(p.position.y > 1.65, "airborne ledge catch finishes above the platform")
	await reset(1.1, 0.8)
	p.toggle_ability("focus")
	check(p.traversal.try_start(Vector3.FORWARD), "Focus permits traversal")
	var focus_frames := await finish()
	check(absi(focus_frames - normal_frames) <= 1, "Focus preserves traversal action time")
	await reset(2.4, 3)
	check(not p.traversal.try_start(Vector3.FORWARD), "out-of-reach wall cannot be climbed")
	await reset(1.65, 3)
	var ceiling = game.arena.box(Vector3(0, 2.4, 103), Vector3(6, 0.2, 6), game.arena.dark)
	await ticks(2)
	check(not p.traversal.try_start(Vector3.FORWARD), "ceiling blocks the complete standing-capsule route")
	ceiling.free()
	await reset(1.1, 0.8)
	p.capsule.shape.height = 1.0
	check(not p.traversal.try_start(Vector3.FORWARD), "crouched player cannot expand into a climb")
	await reset(1.1, 0.8)
	check(not p.traversal.try_start(Vector3.ZERO), "zero approach direction cannot start traversal")
	p.traversal.try_start(Vector3.FORWARD)
	ceiling = game.arena.box(Vector3(0, 2.4, 104), Vector3(6, 0.4, 2), game.arena.dark)
	await ticks(2)
	await finish()
	check(not p.traversal.active and p.position.y < 0.6 and p.position.z > 103.8, "new obstruction aborts movement without teleporting through it")
	ceiling.free()
	await reset(1.1, 0.8)
	p.traversal.try_start(Vector3.FORWARD)
	p.set_physics_process(true)
	await ticks(10)
	game.pause_game()
	var paused_position: Vector3 = p.position
	var paused_elapsed: float = p.traversal.elapsed
	await ticks(12)
	check(p.position == paused_position and p.traversal.elapsed == paused_elapsed, "pause freezes an active vault")
	game.resume_game()
	await finish()
	check(p.position.z < 102.4, "resumed vault completes")
	await reset(1.65, 3)
	p.traversal.try_start(Vector3.FORWARD)
	p.shot_timer = 0
	check(p.fire(), "weapon remains usable during traversal")
	game.cycle_practice_route()
	check(not p.traversal.active and p.velocity == Vector3.ZERO, "practice teleport cancels the old traversal path")
	await reset(1.65, 3)
	p.traversal.try_start(Vector3.FORWARD)
	p.take_damage(1000, p.position, 0)
	check(not p.traversal.active and p.health == 0, "death cancels traversal without invulnerability")
	game.start_run(true)
	check(not game.player.traversal.active, "restart creates a clean traversal state")
	game.sound.stop_all()
	await create_timer(0.10, true, false, true).timeout
	game.free()
	await process_frame
	print("TRAVERSAL RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
