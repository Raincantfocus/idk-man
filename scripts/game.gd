extends Node3D

const ArenaScript = preload("res://scripts/arena.gd")
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const HudScript = preload("res://scripts/hud.gd")
const SoundScript = preload("res://scripts/sound.gd")
const RagdollScript = preload("res://scripts/ragdoll.gd")
const MAX_ACTIVE_RAGDOLLS := 6
const MAX_RETAINED_RAGDOLLS := 10

var balance: Dictionary
var arena
var arena_factory = ArenaScript
var spawn_type_counts: Dictionary = {}
var player
var hud
var sound
var menu_camera := Camera3D.new()
var rng := RandomNumberGenerator.new()
var cosmetic_rng := RandomNumberGenerator.new()
var state: String = "menu"
var wave: int = 0
var score: int = 0
var credits: int = 0
var kills: int = 0
var recovered: float = 0
var combo: float = 1
var combo_time: float = 0
var elapsed: float = 0
var best_score: int = 0
var spawn_timer: float = 0
var resolve_timer: float = 0
var pressure_timer: float = 0
var relief: bool = false
var queue: Array[String] = []
var enemies: Array = []
var pickups: Array = []
var corpses: Array = []
var effect_count: int = 0
var wave_style_start: int = 0
var pending: Array[Dictionary] = []
var message: String = ""
var message_time: float = 0
var pickup_flash: float = 0
var last_damage_direction := Vector3.ZERO
var gore_enabled: bool = true
var gore_level: int = 1
var presentation: Node
var camera_motion: float = 1
var mouse_sensitivity: float = 0.0022
var purchased: Array[String] = []
var shop_message: String = ""
var paused_state: String = ""
var capture_path: String = ""
var capture_frames: int = 0
var capture_limit: int = 90
var is_test: bool = false
var completed_reward: bool = false
var pause_from_focus: bool = false
var practice: bool = false
var practice_route: int = 0
var practice_dummy_index := 0
const PRACTICE_KINDS := ["enforcer", "rusher", "shield", "flusher", "elite"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.seed = 17042
	cosmetic_rng.seed = 17043
	balance = JSON.parse_string(FileAccess.get_file_as_string("res://data/trial_balance.json"))
	_bind_inputs()
	_load_settings()
	arena = arena_factory.new()
	add_child(arena)
	arena.build()
	if arena.has_method("choose_spawn"): arena.game = self
	sound = SoundScript.new()
	sound.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(sound)
	var audio_config := ConfigFile.new()
	if audio_config.load("user://profile.cfg") == OK:
		sound.muted = audio_config.get_value("settings", "muted", false)
	player = PlayerScript.new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.setup(self)
	player.position = arena.PLAYER_START
	menu_camera.position = Vector3(0, 11, -12)
	menu_camera.fov = 73
	add_child(menu_camera)
	menu_camera.look_at(Vector3(0, 2, 3))
	menu_camera.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = HudScript.new()
	hud.game = self
	layer.add_child(hud)
	presentation = preload("res://scripts/playtest/runtime.gd").new()
	add_child(presentation)
	presentation.setup(self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_path = arg.trim_prefix("--capture=")
		if arg.begins_with("--capture-frames="):
			capture_limit = maxi(1, int(arg.trim_prefix("--capture-frames=")))
		if arg == "--showcase":
			start_run()
			for p in [Vector3(-5, 0.1, 7), Vector3(5, 0.1, 3), Vector3(-7, 0.1, -5)]:
				spawn_enemy("enforcer", p)
			player.pitch = -0.045
			spawn_pickup(Vector3(1, 0.3, 10), "health")
			spawn_pickup(Vector3(-1, 0.3, 9), "armor")
		if arg == "--movement-lab":
			start_run(true)
		if arg == "--art-showcase":
			start_run(true)
			player.position = Vector3(-8, 0.05, 31)
			player.rotation.y = -0.55

func _bind_inputs() -> void:
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "sprint": KEY_SHIFT, "slide": KEY_CTRL, "dash": KEY_ALT, "reload": KEY_R, "focus": KEY_Q, "shroud": KEY_E, "melee": KEY_F, "weapon_0": KEY_1, "weapon_1": KEY_2, "weapon_2": KEY_3, "accept": KEY_ENTER, "pause": KEY_ESCAPE, "training_dummy": KEY_T}
	keys["practice_route"] = KEY_V
	keys["training_type"] = KEY_B
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	# Browser-friendly alternatives avoid Ctrl+W and Alt browser shortcuts.
	for mapping in [["slide", KEY_C], ["dash", KEY_X]]:
		var alternate := InputEventKey.new()
		alternate.physical_keycode = mapping[1]
		InputMap.action_add_event(mapping[0], alternate)
	for action in ["fire", "aim"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT if action == "fire" else MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(action, event)

func is_playing() -> bool:
	return state in ["combat", "resolve"] and not get_tree().paused

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("training_type") and practice and is_playing():
		cycle_training_type()
	if event.is_action_pressed("training_dummy") and practice and is_playing():
		spawn_training_dummy()
	if event.is_action_pressed("practice_route") and practice and is_playing():
		cycle_practice_route()
	if event.is_action_pressed("pause"):
		if is_playing():
			pause_game()
		elif state == "paused":
			resume_game()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("accept"):
		if state == "menu" or state == "defeat":
			start_run()
		elif state == "shop":
			start_wave()
		elif state == "complete":
			start_wave()
		elif state == "paused":
			resume_game()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and state in ["menu", "paused", "defeat", "shop", "complete"]:
		if event.physical_keycode == KEY_M:
			sound.muted = not sound.muted
			_save_settings()
		elif event.physical_keycode == KEY_G:
			set_gore_level((gore_level + 1) % 3)
		elif event.physical_keycode == KEY_H:
			camera_motion = 0 if camera_motion > 0 else 1
			_save_settings()
		elif event.physical_keycode == KEY_BRACKETLEFT:
			mouse_sensitivity = maxf(0.0005, mouse_sensitivity - 0.0002)
			_save_settings()
		elif event.physical_keycode == KEY_BRACKETRIGHT:
			mouse_sensitivity = minf(0.006, mouse_sensitivity + 0.0002)
			_save_settings()

func _process(delta: float) -> void:
	var dt := delta / maxf(Engine.time_scale, 0.01)
	if state == "menu":
		menu_camera.position.x = 0 + sin(Time.get_ticks_msec() * 0.00012) * 0.6
		menu_camera.look_at(Vector3(0, 2, 3))
	if is_playing():
		elapsed += dt
		message_time = maxf(0, message_time - dt)
		pickup_flash = maxf(0, pickup_flash - dt)
		combo_time = maxf(0, combo_time - dt)
		if combo_time <= 0:
			combo = move_toward(combo, 1, dt * 0.25)
		clean_references()
		if state == "combat" and not practice:
			_director(dt)
		elif state == "resolve":
			resolve_timer -= dt
			if resolve_timer <= 0 and get_tree().get_nodes_in_group("projectile").is_empty():
				_finish_wave()
	if capture_path != "":
		capture_frames += 1
		if capture_frames == capture_limit:
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			var error := image.save_png(capture_path)
			print("CAPTURE ", error, " ", capture_path)
			get_tree().quit(0 if error == OK else 1)

func _director(dt: float) -> void:
	pressure_timer -= dt
	if pressure_timer <= 0:
		relief = not relief
		pressure_timer = (4.0 if relief else 10.0)
	for i in range(pending.size() - 1, -1, -1):
		# Spawn tells respect world time and cannot release while Focus is active.
		pending[i].time -= dt * Engine.time_scale
		if pending[i].time <= 0 and player.ability != "focus":
			var entry: Dictionary = pending[i]
			if arena.has_method("safe_spawn") and not arena.safe_spawn(entry.position):
				pending[i].time = .5
				pending[i].retries = pending[i].get("retries",0)+1
				if pending[i].retries > 8:
					queue.push_front(entry.kind)
					pending.remove_at(i)
				continue
			var enemy = spawn_enemy(entry.kind,entry.position)
			if entry.get("type","") == "sky":
				enemy.begin_descent(entry.position+Vector3.UP*13.9,entry.position,3.0)
			pending.remove_at(i)
	spawn_timer -= dt
	if spawn_timer <= 0 and not relief and player.ability != "focus" and not queue.is_empty():
		var cap: int = int(balance.waves[mini(wave - 1, 9)].cap) if wave <= 10 else 20
		if enemies.size() + pending.size() < cap:
			if arena.has_method("choose_spawn"):
				var choice: Dictionary = arena.choose_spawn()
				if not choice.is_empty():
					var source: Dictionary = arena.spawns[choice.index]
					var batch: int = mini(2 if source.type=="sky" else 1,mini(queue.size(),cap-enemies.size()-pending.size()))
					for j in batch:
						var offset := Vector3((j-.5)*1.0,0,0) if batch>1 else Vector3.ZERO
						pending.append({"kind":queue.pop_front(),"position":choice.point+offset,"time":source.warning,"source":choice.index,"type":source.type})
					spawn_type_counts[source.type] = spawn_type_counts.get(source.type,0)+batch
					arena.warn_spawn(choice.index)
			else:
				var point := _spawn_point()
				if point != Vector3.INF:
					pending.append({"kind":queue.pop_front(),"position":point,"time":.8})
			spawn_timer = .9 if wave > 3 else 1.35
	if queue.is_empty() and pending.is_empty() and enemies.is_empty():
		state = "resolve"
		resolve_timer = 2.0
		player.end_ability()
		notice("SECTOR CLEAR // RESOLVING", 2.0)

func _spawn_point() -> Vector3:
	var best := Vector3.INF
	var best_score_value: float = -INF
	for point in arena.spawn_points:
		var candidate: Vector3 = point
		var distance: float = player.global_position.distance_to(candidate)
		if distance < 8:
			continue
		var visible: bool = player.camera.is_position_in_frustum(candidate + Vector3.UP)
		var occlusion := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(player.camera.global_position, candidate + Vector3.UP, 1))
		if visible and occlusion.is_empty():
			continue
		# Favor nearby approaches in the enlarged arena, while preserving occlusion.
		var value: float = -absf(distance - 24) - absf(candidate.y - player.position.y) * 0.7 + rng.randf_range(0, 5)
		if value > best_score_value:
			best = candidate
			best_score_value = value
	return best

func start_run(training: bool = false) -> void:
	get_tree().paused = false
	Engine.time_scale = 1
	if arena.has_method("reset_map"): arena.reset_map()
	if presentation != null: presentation.reset_run()
	practice = training
	practice_route = 0
	practice_dummy_index = 0
	for group in ["enemy", "pickup", "projectile", "corpse", "transient"]:
		for node in get_tree().get_nodes_in_group(group):
			node.free()
	enemies.clear()
	pickups.clear()
	corpses.clear()
	queue.clear()
	pending.clear()
	player.free()
	player = PlayerScript.new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.setup(self)
	player.position = arena.PLAYER_START
	player.camera.current = true
	wave = 0
	score = 0
	credits = 0
	kills = 0
	recovered = 0
	combo = 1
	combo_time = 0
	elapsed = 0
	effect_count = 0
	purchased.clear()
	rng.seed = 17042
	cosmetic_rng.seed = 17043
	if practice:
		state = "combat"
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		for point in arena.lab_stations:
			var dummy = spawn_enemy("elite" if point.y > 8 else "enforcer", point)
			dummy.training_dummy = true
		notice("MOVEMENT LAB // T: PLACE TEST DUMMY + REFILL", 5.0)
	else:
		start_wave()

func return_to_menu() -> void:
	get_tree().paused = false
	player.end_ability()
	Engine.time_scale = 1
	state = "menu"
	practice = false
	sound.stop_all()
	for group in ["enemy", "pickup", "projectile", "corpse", "transient"]:
		for node in get_tree().get_nodes_in_group(group):
			node.queue_free()
	enemies.clear()
	pickups.clear()
	corpses.clear()
	queue.clear()
	pending.clear()
	menu_camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func cycle_training_type() -> void:
	if not practice or not is_playing(): return
	practice_dummy_index = (practice_dummy_index + 1) % PRACTICE_KINDS.size()
	notice("TARGET // " + PRACTICE_KINDS[practice_dummy_index].to_upper() + " // T: PLACE", 2.5)

func spawn_training_dummy() -> void:
	if not practice:
		return
	clean_references()
	if enemies.size() >= 6:
		var oldest = enemies.pop_front()
		oldest.queue_free()
	var desired: Vector3 = player.global_position - player.global_basis.z * 6
	var point: Vector3 = arena.nearest_walkable(desired)
	var dummy = spawn_enemy(PRACTICE_KINDS[practice_dummy_index], point + Vector3.UP * 0.05)
	dummy.training_dummy = true
	refill_practice_resources()
	notice("TEST DUMMY PLACED // RESOURCES REFILLED", 1.5)

func refill_practice_resources() -> void:
	if not practice:
		return
	player.health = 100
	player.armor = 100
	player.focus = player.focus_max
	player.shroud = player.shroud_max
	player.ability_delay = 0
	player.dash_charges = 2
	player.dash_cooldown = 0
	player.reload_time = 0
	player.reload_stage = 0
	player.magazine_seated = [true, true, true]
	for i in range(3):
		player.reserve[i] = int(balance.weapons[player.weapon_ids[i]].reserve)
		player.ammo[i] = int(balance.weapons[player.weapon_ids[i]].magazine) + (player.magazine_bonus if i != 2 else 0)

func cycle_practice_route() -> void:
	if not practice or not is_playing():
		return
	practice_route = (practice_route + 1) % arena.PRACTICE_ROUTES.size()
	var route: Dictionary = arena.PRACTICE_ROUTES[practice_route]
	player.end_ability()
	player.position = route.point
	player.traversal.cancel()
	player.rotation.y = route.yaw
	player.pitch = 0
	player.velocity = Vector3.ZERO
	player.dash_time = 0
	player.slide_time = 0
	player.slide_lock = 0
	player.wall_time = 0
	player.wall_side = 0
	player.jump_buffer = 0
	player.coyote = 0
	refill_practice_resources()
	notice("PRACTICE // " + route.name + " // V: NEXT ROUTE", 3.0)

func start_wave() -> void:
	wave += 1
	spawn_type_counts.clear()
	if arena.has_method("apply_wave"): arena.apply_wave(wave)
	completed_reward = false
	wave_style_start = score
	queue.clear()
	pending.clear()
	var definition: Dictionary = balance.waves[mini(wave - 1, 9)]
	for kind in definition.roster:
		for i in int(definition.roster[kind]):
			queue.append(kind)
	if wave > 10:
		while queue.size() < mini(40, 30 + (wave - 10) * 4):
			queue.append("enforcer" if queue.size() % 2 == 0 else "rusher")
	# Seeded Fisher-Yates rather than global RNG-dependent Array.shuffle.
	for i in range(queue.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp := queue[i]
		queue[i] = queue[j]
		queue[j] = temp
	spawn_timer = 1.2
	pressure_timer = 12
	relief = false
	state = "combat"
	player.camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	notice("WAVE %02d // %s" % [wave, definition.lesson], 3.5)
	sound.play_cue("wave")

func spawn_enemy(kind: String, point: Vector3):
	var enemy = EnemyScript.new()
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(enemy)
	enemy.position = point
	enemy.setup(self, kind)
	if wave > 10:
		enemy.health *= minf(1.3, 1 + (wave - 10) * 0.03)
		enemy.max_health = enemy.health
	enemies.append(enemy)
	return enemy

func enemy_killed(enemy, headshot: bool) -> void:
	if enemy not in enemies:
		return
	enemies.erase(enemy)
	kills += 1
	var bonus: int = 0
	if player.ability == "focus":
		bonus += 25
	if player.slide_time > 0:
		bonus += 25
	if headshot:
		bonus += 20
	combo = minf(3, combo + 0.25) if combo_time > 0 else 1
	combo_time = 4
	score += int((int(balance.enemies[enemy.kind].score) + bonus) * combo)
	player.hit_timer = 0.23
	player.kill_hit = true
	if player.ability != "focus":
		player.focus = minf(player.focus_max, player.focus + 8)
	if player.ability != "shroud":
		player.shroud = minf(player.shroud_max, player.shroud + 6)
	var type: String = "health" if rng.randf() < 0.6 else "armor"
	if player.health <= 35 and player.armor <= 20:
		type = "health" if kills % 2 == 1 else "armor"
	elif player.health <= 35:
		type = "health"
	elif player.armor <= 20:
		type = "armor"
	spawn_pickup(enemy.global_position + Vector3.UP * 0.4, type)
	if kills % 3 == 0:
		spawn_pickup(enemy.global_position + Vector3(0.3, 0.4, 0), "ammo")
	if enemy.kind == "elite":
		spawn_pickup(enemy.global_position + Vector3(-0.3, 0.4, 0), "armor" if type == "health" else "health")
		spawn_pickup(enemy.global_position + Vector3(0, 0.4, 0.3), "ammo")

func spawn_pickup(point: Vector3, kind: String):
	var pickup = PickupScript.new()
	pickup.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(pickup)
	pickup.setup(self, kind)
	pickup.position = point
	pickups.append(pickup)
	return pickup

func collect_along(from: Vector3, to: Vector3) -> void:
	if player.health <= 0:
		return
	for pickup in pickups:
		if not is_instance_valid(pickup) or pickup.is_queued_for_deletion():
			continue
		var closest := Geometry3D.get_closest_point_to_segment(pickup.global_position, from, to)
		if absf(closest.y - pickup.global_position.y) > 1.0:
			continue
		if closest.distance_to(pickup.global_position) > player.pickup_radius:
			continue
		var ray := PhysicsRayQueryParameters3D.create(closest, pickup.global_position, 1)
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			pickup.collect(player)

func clean_references() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and e.alive)
	pickups = pickups.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	corpses = corpses.filter(func(c): return is_instance_valid(c))

func _finish_wave() -> void:
	if completed_reward or player.health <= 0:
		return
	completed_reward = true
	for pickup in pickups:
		if is_instance_valid(pickup):
			pickup.state = pickup.State.AVAILABLE
			pickup.collect(player)
			pickup.queue_free()
	player.health = minf(100, player.health + 25)
	player.focus = player.focus_max
	player.shroud = player.shroud_max
	player.dash_charges = 2
	player.ability_delay = 0
	player.reload_time = 0
	for i in range(3):
		player.reserve[i] = int(balance.weapons[player.weapon_ids[i]].reserve)
		player.ammo[i] = int(balance.weapons[player.weapon_ids[i]].magazine) + (player.magazine_bonus if i < 2 else 0)
	credits += int(balance.waves[mini(wave - 1, 9)].credits) + mini(200, (score - wave_style_start) / 100)
	state = "complete" if wave == 10 else "shop"
	shop_message = "RECOVERY RESOLVED. AMMUNITION REPLENISHED."
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_save_score()

func purchase(id: String) -> bool:
	if state != "shop" or id in purchased:
		return false
	var prices := {"magazine": 250, "brake": 200, "pickup": 250, "capacitor": 300, "dash": 300}
	if not prices.has(id) or credits < prices[id]:
		shop_message = "INSUFFICIENT CREDITS."
		return false
	credits -= prices[id]
	purchased.append(id)
	match id:
		"magazine": player.magazine_bonus = 8
		"brake": player.recoil_multiplier = 0.72
		"pickup": player.pickup_radius = 1.4
		"capacitor":
			player.focus_max = 120
			player.focus = 120
		"dash": player.dash_interval = 2.1
	shop_message = "UPGRADE INSTALLED // " + id.to_upper()
	sound.play_cue("pickup")
	return true

func defeat() -> void:
	state = "defeat"
	Engine.time_scale = 1
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_save_score()

func pause_game() -> void:
	paused_state = state
	pause_from_focus = player.ability == "focus"
	state = "paused"
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume_game() -> void:
	state = paused_state
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func attacking_count() -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.windup > 0:
			count += 1
	return count

func live_grenades() -> int:
	var count := 0
	for projectile in get_tree().get_nodes_in_group("projectile"):
		if projectile.grenade:
			count += 1
	return count

func spawn_bullet(origin: Vector3, direction: Vector3, amount: float):
	var projectile = ProjectileScript.new()
	projectile.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(projectile)
	projectile.position = origin
	projectile.setup(self, direction, amount)
	return projectile

func spawn_grenade(origin: Vector3, target: Vector3):
	var projectile = ProjectileScript.new()
	projectile.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(projectile)
	projectile.position = origin
	var velocity := (target - origin) / 1.1 + Vector3.UP * 6.8
	projectile.setup(self, velocity, 40, true)
	notice("FRAGMENTATION // MOVE", 1.5)
	return projectile

func notice(text: String, duration: float = 2) -> void:
	message = text
	message_time = duration

func tracer(from: Vector3, to: Vector3, color: Color, duration: float) -> void:
	if effect_count >= 90 or is_test:
		return
	var distance := from.distance_to(to)
	if distance < 0.01:
		return
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.012, 0.012, distance)
	instance.mesh = mesh
	instance.material_override = arena.material(color, 0, 1)
	add_child(instance)
	instance.add_to_group("transient")
	instance.global_position = (from + to) * 0.5
	instance.look_at(to, Vector3.RIGHT if absf((to - from).normalized().y) > 0.98 else Vector3.UP)
	effect_count += 1
	var tween := instance.create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(func():
		effect_count = maxi(0, effect_count - 1)
		instance.queue_free())

func impact(point: Vector3, color: Color, count: int) -> void:
	if is_test:
		return
	for i in range(mini(count, 90 - effect_count)):
		var instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * cosmetic_rng.randf_range(0.025, 0.075)
		instance.mesh = box
		instance.material_override = arena.material(color, 0, 0.2)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		instance.add_to_group("transient")
		instance.position = point
		effect_count += 1
		var tween := instance.create_tween().set_parallel(true)
		tween.tween_property(instance, "position", point + Vector3(cosmetic_rng.randf_range(-0.6, 0.6), cosmetic_rng.randf_range(-0.3, 0.7), cosmetic_rng.randf_range(-0.6, 0.6)), 0.25)
		tween.tween_property(instance, "scale", Vector3.ZERO, 0.35)
		tween.chain().tween_callback(func():
			effect_count = maxi(0, effect_count - 1)
			instance.queue_free())

func spawn_corpse(body: Node3D, point: Vector3, _color: Color):
	if is_test:
		return null
	clean_references()
	while corpses.size() >= MAX_RETAINED_RAGDOLLS:
		var old = corpses.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	var active_count := 0
	for old in corpses:
		if old.active:
			active_count += 1
	for old in corpses:
		if active_count < MAX_ACTIVE_RAGDOLLS:
			break
		if old.active:
			old.settle()
			active_count -= 1
	var corpse = RagdollScript.new()
	add_child(corpse)
	var direction: Vector3 = (point - player.global_position).normalized()
	corpse.game = self
	corpse.setup(body, direction * 2.2 + Vector3.UP * 0.6)
	corpses.append(corpse)
	return corpse

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://profile.cfg") == OK:
		best_score = config.get_value("trial", "best", 0)
		gore_level = clampi(int(config.get_value("settings", "gore_level", 1)), 0, 2)
		gore_enabled = gore_level > 0
		camera_motion = config.get_value("settings", "camera_motion", 1.0)
		mouse_sensitivity = config.get_value("settings", "sensitivity", 0.0022)

func _save_settings() -> void:
	if is_test:
		return
	var config := ConfigFile.new()
	config.set_value("trial", "best", best_score)
	config.set_value("settings", "gore", gore_enabled)
	config.set_value("settings", "gore_level", gore_level)
	config.set_value("settings", "camera_motion", camera_motion)
	config.set_value("settings", "sensitivity", mouse_sensitivity)
	config.set_value("settings", "muted", sound.muted)
	config.save("user://profile.cfg")

func _save_score() -> void:
	if practice:
		return
	best_score = maxi(best_score, score)
	_save_settings()

func blood_burst(point: Vector3, direction: Vector3, count: int = 8) -> void:
	if not gore_enabled or is_test: return
	for i in mini(count if gore_level == 2 else maxi(1,count/2), 12):
		var drops := get_tree().get_nodes_in_group("blood_drop")
		if drops.size() >= 48: drops[0].free()
		var drop = preload("res://scripts/blood_drop.gd").new()
		drop.game = self
		add_child(drop)
		drop.global_position = point
		var spread := Vector3(sin(i * 2.4), cos(i * 1.7), sin(i * 3.1)) * 0.45
		drop.velocity = (direction.normalized() + spread).normalized() * (3.0 + i * 0.6)

func set_gore_level(level: int) -> void:
	gore_level = clampi(level, 0, 2)
	gore_enabled = gore_level > 0
	if presentation != null: presentation.set_gore(gore_level)
	_save_settings()
