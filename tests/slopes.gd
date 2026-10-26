extends SceneTree
var game
var p
var failed := 0
var passed := 0
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
	for i in n:
		await physics_frame
func sample(pos: Vector3, heading: Vector3, focus: bool = false, frames: int = 140) -> Dictionary:
	p.end_ability()
	p.position = pos
	p.velocity = Vector3.ZERO
	p.slide_time = 0
	p.slide_lock = 0
	p.set_physics_process(true)
	await ticks(10)
	p.velocity = heading * 9.5
	p.slide_time = 0.85
	if focus:
		p.focus = 100
		p.ability_delay = 0
		p.toggle_ability("focus")
	var peak := 0.0
	var grounded := 0
	var active := 0
	for i in frames:
		await physics_frame
		peak = maxf(peak, Vector2(p.velocity.x, p.velocity.z).length())
		if p.is_on_floor(): grounded += 1
		if p.slide_time > 0: active += 1
	p.set_physics_process(false)
	return {"peak": peak, "grounded": grounded, "active": active, "end": p.position}
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	root.add_child(game)
	game.set_process(false)
	game.start_run(true)
	p = game.player
	# Long fixtures isolate slope behavior from scenery and enemy collisions.
	game.arena.box(Vector3(0, -0.5, 140), Vector3(40, 1, 90), game.arena.dark)
	game.arena.ramp(Rect2(-4, 100, 8, 60), 0, 15)
	var downhill := await sample(Vector3(0, 14.05, 104), Vector3.BACK)
	p.set_physics_process(true)
	Input.action_press("jump")
	await ticks(2)
	check(p.slide_time == 0 and not p.is_on_floor() and Vector2(p.velocity.x, p.velocity.z).length() > 12, "jump cancels slide and carries earned downhill momentum")
	Input.action_release("jump")
	var uphill := await sample(Vector3(0, 2.05, 152), Vector3.FORWARD)
	var flat := await sample(Vector3(14, 0.05, 140), Vector3.BACK)
	var focused := await sample(Vector3(0, 14.05, 104), Vector3.BACK, true)
	print("SLOPE SAMPLES ", downhill, uphill, flat, focused)
	check(downhill.active == 140 and downhill.peak > 12, "downhill sustains beyond old timeout and gains speed")
	check(downhill.grounded >= 130, "downhill slide stays attached to the contact plane")
	check(uphill.peak < 9.6 and uphill.active < downhill.active, "uphill loses speed and expires")
	check(flat.active < 105 and flat.peak < 9.6, "flat ground brakes and cannot sustain indefinitely")
	check(downhill.peak <= p.SLIDE_MAX_SPEED + 0.01, "slope speed stays bounded")
	check(absf(focused.peak - downhill.peak) < 0.15 and focused.active == downhill.active, "Focus preserves slope action speed and duration")
	var sustained := await sample(Vector3(0, 14.05, 104), Vector3.BACK, false, 300)
	check(absf(sustained.peak - p.SLIDE_MAX_SPEED) < 0.05, "long descent reaches the cap without exceeding it")
	p.end_ability()
	p.set_physics_process(true)
	p.position = Vector3(-17, 4.25, -2)
	p.velocity = Vector3.ZERO
	p.slide_time = 0
	await ticks(10)
	p.velocity = Vector3(0, 0, 10)
	p.slide_time = 0.85
	await ticks(360)
	check(p.position.z > 24 and p.position.y < 0.2, "new chute connects gallery to unobstructed ground run-out")
	check(not game.arena.path_to(Vector3(-26, 4.2, -2), Vector3(-17, 0, 30)).is_empty(), "AI navigation connects the new descent")
	game.sound.stop_all()
	game.free()
	await process_frame
	print("SLOPES RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
