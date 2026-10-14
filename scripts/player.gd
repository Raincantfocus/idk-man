extends CharacterBody3D
const TraversalScript = preload("res://scripts/traversal.gd")
var traversal = TraversalScript.new()

var game
var camera := Camera3D.new()
var weapon_root := Node3D.new()
var capsule := CollisionShape3D.new()
var standing_shape := CapsuleShape3D.new()
var health: float = 100.0
var armor: float = 75.0
var focus: float = 100.0
var shroud: float = 100.0
var focus_max: float = 100.0
var shroud_max: float = 100.0
var ability: String = ""
var ability_delay: float = 0.0
var dash_charges: int = 2
var dash_cooldown: float = 0.0
var dash_interval: float = 2.5
var dash_time: float = 0.0
var dash_dir := Vector3.ZERO
var slide_time: float = 0.0
var slide_lock: float = 0.0
var wall_time: float = 0.0
var wall_side: float = 0.0
var jump_buffer: float = 0.0
var coyote: float = 0.0
var grounded_before: bool = false
var mode: String = "READY"
var pitch: float = 0.0
var recoil: float = 0.0
var bob: float = 0.0
var hurt: float = 0.0
var shot_timer: float = 0.0
var muzzle_timer: float = 0.0
var hit_timer: float = 0.0
var kill_hit: bool = false
var reload_time: float = 0.0
var reload_total: float = 0.0
var reload_stage: int = 0
var melee_timer: float = 0.0
var weapon_index: int = 0
var weapon_ids := ["carbine", "shotgun", "sidearm"]
var ammo := [30, 8, 12]
var reserve := [150, 40, -1]
var magazine_bonus: int = 0
var recoil_multiplier: float = 1.0
var pickup_radius: float = 1.1
var slide_victims: Array[int] = []
var flash := OmniLight3D.new()
var gun_color: StandardMaterial3D
var muzzle: MeshInstance3D
var look_delta := Vector2.ZERO
var visual_roll: float = 0.0

func setup(owner_game) -> void:
	game = owner_game
	traversal.setup(self)
	name = "Operator"
	collision_layer = 4
	collision_mask = 3
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(52)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.72
	capsule.shape = shape
	standing_shape.radius = shape.radius
	standing_shape.height = shape.height
	capsule.position.y = 0.86
	add_child(capsule)
	camera.position.y = 1.55
	camera.fov = 86
	camera.near = 0.045
	add_child(camera)
	camera.add_child(weapon_root)
	weapon_root.position = Vector3(0.27, -0.26, -0.48)
	_build_weapon()
	flash.light_color = Color("ffdca2")
	flash.light_energy = 0
	flash.omni_range = 5
	flash.position = Vector3(0, 0, -0.85)
	weapon_root.add_child(flash)
	add_to_group("player")

func _piece(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = mat
	mesh.position = pos
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	weapon_root.add_child(mesh)
	return mesh

func _build_weapon() -> void:
	gun_color = game.arena.material(Color("233036"), 0.7)
	var rail = game.arena.material(Color("63706b"), 0.8)
	var glove = game.arena.material(Color("3e4b43"))
	var sleeve = game.arena.material(Color("637260"))
	_piece(Vector3(0, 0, -0.15), Vector3(0.13, 0.16, 0.53), gun_color)
	_piece(Vector3(0, 0.008, -0.5), Vector3(0.09, 0.10, 0.34), rail)
	_piece(Vector3(0, -0.075, 0.12), Vector3(0.12, 0.22, 0.15), gun_color)
	_piece(Vector3(0, -0.15, -0.12), Vector3(0.075, 0.24, 0.13), rail)
	_piece(Vector3(0, 0.09, -0.18), Vector3(0.045, 0.025, 0.42), rail)
	_piece(Vector3(0, 0.125, -0.04), Vector3(0.075, 0.04, 0.065), gun_color)
	_piece(Vector3(-0.035, 0.16, -0.04), Vector3(0.016, 0.085, 0.06), gun_color)
	_piece(Vector3(0.035, 0.16, -0.04), Vector3(0.016, 0.085, 0.06), gun_color)
	_piece(Vector3(0, 0.20, -0.04), Vector3(0.075, 0.015, 0.06), gun_color)
	_piece(Vector3(0, 0.15, -0.06), Vector3(0.008, 0.009, 0.01), game.arena.acid)
	_piece(Vector3(0.07, 0.025, -0.04), Vector3(0.015, 0.035, 0.13), rail)
	_piece(Vector3(0.05, -0.15, 0.15), Vector3(0.115, 0.15, 0.20), glove)
	_piece(Vector3(0.08, -0.24, 0.25), Vector3(0.13, 0.17, 0.37), sleeve)
	var hand = _piece(Vector3(-0.04, -0.1, -0.39), Vector3(0.14, 0.10, 0.16), glove)
	hand.rotation.z = 0.3
	var arm = _piece(Vector3(-0.14, -0.19, -0.23), Vector3(0.13, 0.13, 0.38), sleeve)
	arm.rotation.y = -0.55
	muzzle = _piece(Vector3(0, 0, -0.79), Vector3(0.12, 0.12, 0.22), game.arena.material(Color("ffde88"), 0, 3))
	muzzle.visible = false

func weapon() -> Dictionary:
	return game.balance.weapons[weapon_ids[weapon_index]]

func max_ammo() -> int:
	return int(weapon().magazine) + (magazine_bonus if weapon_index != 2 else 0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and game.is_playing():
		var motion = event.relative * game.mouse_sensitivity
		rotation.y -= motion.x
		pitch = clampf(pitch - motion.y, -1.45, 1.45)
		camera.rotation.x = pitch
		look_delta += motion

func _physics_process(delta: float) -> void:
	if not game or not game.is_playing() or health <= 0:
		return
	# Global time scale can change during this very tick. The fixed action step
	# must not divide an already-issued delta by a newly changed global value.
	var dt := 1.0 / Engine.physics_ticks_per_second
	var previous := global_position
	shot_timer = maxf(0, shot_timer - dt)
	melee_timer = maxf(0, melee_timer - dt)
	hit_timer = maxf(0, hit_timer - dt)
	hurt = maxf(0, hurt - dt * 1.5)
	slide_lock = maxf(0, slide_lock - dt)
	traversal.cooldown = maxf(0, traversal.cooldown - dt)
	_abilities(dt)
	_reload_tick(dt)
	if Input.is_action_just_pressed("reload"):
		begin_reload()
	for i in range(3):
		if Input.is_action_just_pressed("weapon_%d" % i):
			switch_weapon(i)
	if Input.is_action_pressed("fire") and melee_timer <= 0:
		fire()
	if Input.is_action_just_pressed("melee"):
		melee()
	_move_player(dt)
	game.collect_along(previous + Vector3(0, 0.55, 0), global_position + Vector3(0, 0.55, 0))
	if position.y < -8:
		take_damage(1000, global_position, 0)
	_visuals(dt)

func _move_player(dt: float) -> void:
	if traversal.active:
		traversal.step(dt)
		return
	var input := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var grab := Input.is_action_just_pressed("jump") or (Input.is_action_pressed("jump") and not is_on_floor() and velocity.y <= 1.0)
	if grab and input.y < -0.5 and dash_time <= 0 and slide_time <= 0 and traversal.try_start(-global_basis.z):
		traversal.step(dt)
		return
	var flat := Vector3(velocity.x, 0, velocity.z)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.12
	else:
		jump_buffer = maxf(0, jump_buffer - dt)
	if is_on_floor():
		coyote = 0.10
		wall_time = 0
	else:
		coyote = maxf(0, coyote - dt)
	if Input.is_action_just_pressed("slide") and is_on_floor() and flat.length() > 6.0 and slide_lock <= 0:
		slide_time = 0.85
		slide_victims.clear()
		flat = flat.normalized() * minf(flat.length() + 1.2, 11)
		game.sound.play_cue("slide")
	if Input.is_action_just_pressed("dash") and dash_charges > 0 and dash_time <= 0:
		dash_charges -= 1
		dash_time = 0.16
		dash_dir = direction if direction.length() > 0.1 else -transform.basis.z
		game.sound.play_cue("dash")
	if dash_charges < 2:
		dash_cooldown += dt
		if dash_cooldown >= dash_interval:
			dash_charges += 1
			dash_cooldown = 0
	wall_side = 0
	var wall_normal := Vector3.ZERO
	if not is_on_floor() and flat.length() > 6.5 and wall_time < 1.25 and Input.is_action_pressed("jump"):
		for side in [-1.0, 1.0]:
			var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, global_position + Vector3.UP + transform.basis.x * side * 0.8, 1)
			var result := get_world_3d().direct_space_state.intersect_ray(ray)
			if not result.is_empty() and absf(result.normal.y) < 0.2:
				wall_side = side
				wall_normal = result.normal
				break
	var crouch := Input.is_action_pressed("slide") or slide_time > 0
	if dash_time > 0:
		dash_time -= dt
		flat = dash_dir * 14
		mode = "DASH"
	elif slide_time > 0:
		slide_time -= dt
		flat = flat.move_toward(direction * 4, dt * 4)
		mode = "SLIDE"
		_slide_kick()
		if slide_time <= 0:
			slide_lock = 0.35
	elif wall_side != 0:
		wall_time += dt
		flat = flat.slide(wall_normal).normalized() * maxf(flat.length(), 8)
		velocity.y = maxf(velocity.y, -1.4)
		mode = "WALL RUN"
	else:
		var speed: float = 9.5 if Input.is_action_pressed("sprint") else 5.0
		if crouch:
			speed = 3.0
		if is_on_floor():
			# Buffered hops preserve momentum instead of applying ground braking first.
			if jump_buffer <= 0:
				flat = flat.move_toward(direction * speed, dt * 38)
		else:
			flat += direction * dt * 8
			flat = flat.limit_length(11)
		mode = "CROUCH" if crouch else ("SPRINT" if speed > 5 and input.length() > 0 else "READY")
		if not is_on_floor():
			mode = "AIRBORNE"
	if jump_buffer > 0 and (coyote > 0 or wall_side != 0):
		velocity.y = 5.6
		if wall_side != 0:
			flat += wall_normal * 5
			wall_time = 1.25
		jump_buffer = 0
		coyote = 0
		slide_time = 0
		crouch = false
	if not is_on_floor():
		velocity.y -= (3.0 if wall_side != 0 else 14.7) * dt
	elif velocity.y < 0:
		velocity.y = -0.1
	# Check the whole standing volume, including roof edges beside our center.
	if not crouch and capsule.shape.height < 1.72:
		crouch = not can_stand()
	capsule.shape.height = 1.0 if crouch else 1.72
	capsule.position.y = capsule.shape.height / 2
	camera.position.y = lerpf(camera.position.y, 0.90 if crouch else 1.55, minf(1, dt * 16))
	velocity.x = flat.x
	velocity.z = flat.z
	# Small step-up handles low lips and continuous ramp transitions.
	if is_on_floor() and flat.length() > 0.1:
		var probe := global_position + flat.normalized() * 0.5
		var step_ray := PhysicsRayQueryParameters3D.create(probe + Vector3.UP * 0.38, probe + Vector3.UP * 0.02, 1)
		var step := get_world_3d().direct_space_state.intersect_ray(step_ray)
		if not step.is_empty() and step.position.y > global_position.y + 0.03 and step.normal.y > 0.8:
			if not test_move(global_transform, Vector3.UP * 0.34):
				global_position.y = step.position.y + 0.02
	# Godot move_and_slide reads engine delta; compensate velocity only for this call.
	var scale_factor := maxf(get_physics_process_delta_time() / dt, 0.01)
	velocity /= scale_factor
	move_and_slide()
	velocity *= scale_factor
	if dash_time <= 0 and flat.length() > 11:
		var limited := Vector3(velocity.x, 0, velocity.z).limit_length(11)
		velocity.x = limited.x
		velocity.z = limited.z

func can_stand() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = standing_shape
	query.transform = global_transform.translated_local(Vector3.UP * 0.88)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.margin = 0.005
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _slide_kick() -> void:
	if slide_time < 0.55:
		return
	for enemy in game.enemies:
		if is_instance_valid(enemy) and enemy.alive and global_position.distance_to(enemy.global_position) < 1.8:
			var toward: Vector3 = (enemy.global_position - global_position).normalized()
			var heading := Vector3(velocity.x, 0, velocity.z).normalized()
			if enemy.get_instance_id() not in slide_victims and heading.dot(toward) > 0.25:
				slide_victims.append(enemy.get_instance_id())
				if ability == "shroud":
					end_ability()
				enemy.stagger = 0.55
				enemy.take_damage(30, enemy.global_position + Vector3.UP, false, true)

func _abilities(dt: float) -> void:
	ability_delay = maxf(0, ability_delay - dt)
	if Input.is_action_just_pressed("focus"):
		toggle_ability("focus")
	if Input.is_action_just_pressed("shroud"):
		toggle_ability("shroud")
	if ability == "focus":
		focus = maxf(0, focus - dt * 25)
		if focus <= 0:
			end_ability()
	elif ability == "shroud":
		shroud = maxf(0, shroud - dt * 17)
		if shroud <= 0:
			end_ability()
	elif ability_delay <= 0:
		focus = minf(focus_max, focus + dt * 10)
		shroud = minf(shroud_max, shroud + dt * 8)

func toggle_ability(which: String) -> bool:
	if ability == which:
		end_ability()
		return true
	if ability_delay > 1.5 or (which == "focus" and focus < 20) or (which == "shroud" and shroud < 25):
		return false
	end_ability()
	ability = which
	ability_delay = 0
	if which == "focus":
		focus -= 10
		Engine.time_scale = 0.2
	else:
		shroud -= 15
	game.sound.play_cue("ability")
	return true

func end_ability() -> void:
	if ability != "":
		ability_delay = 3
	ability = ""
	Engine.time_scale = 1.0

func fire() -> bool:
	if shot_timer > 0 or health <= 0:
		return false
	if reload_time > 0:
		if ammo[weapon_index] <= 0:
			return false
		reload_time = 0
	if ammo[weapon_index] <= 0:
		begin_reload()
		return false
	if ability == "shroud":
		end_ability()
	var stats := weapon()
	ammo[weapon_index] -= 1
	shot_timer = 60.0 / float(stats.rpm)
	muzzle_timer = 0.045
	recoil = minf(0.12, recoil + 0.055 * recoil_multiplier)
	var origin := camera.global_position
	var forward := -camera.global_transform.basis.z
	var spread: float = stats.spread * (0.35 if Input.is_action_pressed("aim") else 1.0)
	for pellet in int(stats.pellets):
		var direction: Vector3 = (forward + camera.global_basis.x * game.rng.randf_range(-spread, spread) + camera.global_basis.y * game.rng.randf_range(-spread, spread)).normalized()
		var ray := PhysicsRayQueryParameters3D.create(origin, origin + direction * 90, 3)
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		var target: Vector3 = hit.position if not hit.is_empty() else origin + direction * 70
		# Authoritative muzzle obstruction avoids shooting through a nearby wall.
		var muzzle_position := weapon_root.to_global(Vector3(0, 0, -0.72))
		var obstruction := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, muzzle_position, 1))
		if not obstruction.is_empty():
			hit = obstruction
			target = hit.position
		elif not hit.is_empty():
			var muzzle_hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(muzzle_position, target + direction * 0.05, 3))
			if not muzzle_hit.is_empty():
				hit = muzzle_hit
				target = hit.position
		if not hit.is_empty():
			if hit.collider.has_method("take_damage"):
				var headshot: bool = target.y - hit.collider.global_position.y > 1.42
				hit.collider.take_damage(float(stats.damage) * (2 if headshot else 1), target, headshot)
				hit_timer = 0.13
			else:
				game.impact(target, Color("ffd796"), 3)
		game.tracer(muzzle_position, target, Color("f7dfb5"), 0.045)
	game.sound.play_cue("shotgun" if weapon_index == 1 else "shot")
	pitch = minf(pitch + 0.012 * recoil_multiplier, 1.45)
	return true

func begin_reload() -> bool:
	if reload_time > 0 or ammo[weapon_index] >= max_ammo() or reserve[weapon_index] == 0:
		return false
	reload_total = weapon().reload_seconds
	reload_time = reload_total
	reload_stage = 0
	game.sound.play_cue("reload")
	return true

func _reload_tick(dt: float) -> void:
	if reload_time <= 0:
		return
	reload_time = maxf(0, reload_time - dt)
	var progress := 1 - reload_time / reload_total
	if progress >= 0.28 and reload_stage == 0:
		if weapon_index != 2:
			reserve[weapon_index] += ammo[weapon_index]
		ammo[weapon_index] = 0
		reload_stage = 1
	if progress >= 0.78 and reload_stage == 1:
		var amount: int = max_ammo() if weapon_index == 2 else mini(max_ammo(), reserve[weapon_index])
		ammo[weapon_index] = amount
		if weapon_index != 2:
			reserve[weapon_index] -= amount
		reload_stage = 2
		game.sound.play_cue("reload")

func switch_weapon(index: int) -> void:
	reload_time = 0
	reload_stage = 0
	weapon_index = index
	shot_timer = 0.15
	recoil = 0.10
	gun_color.albedo_color = [Color("233036"), Color("605e48"), Color("323947")][index]
	weapon_root.scale = [Vector3.ONE, Vector3(1.15, 1.05, 1.18), Vector3(0.82, 0.85, 0.66)][index]

func melee() -> void:
	if melee_timer > 0:
		return
	melee_timer = 0.6
	if ability == "shroud":
		end_ability()
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 2.1, 3))
	if not hit.is_empty() and hit.collider.has_method("take_damage"):
		hit.collider.stagger = 0.55
		hit.collider.take_damage(50, hit.position, false, true)
		hit_timer = 0.18
	game.sound.play_cue("dash")

func take_damage(amount: float, source: Vector3, armor_fraction: float = 0.75) -> void:
	if health <= 0 or not game.is_playing():
		return
	var absorbed := minf(armor, amount * armor_fraction)
	armor -= absorbed
	health = maxf(0, health - (amount - absorbed))
	hurt = minf(1, hurt + 0.35)
	game.last_damage_direction = source - global_position
	game.combo = maxf(1, game.combo - 0.5)
	game.sound.play_cue("hurt")
	if health <= 0:
		traversal.cancel()
		end_ability()
		game.defeat()

func _visuals(dt: float) -> void:
	weapon_root.visible = ability != "shroud"
	var ads := Input.is_action_pressed("aim")
	bob += dt * Vector2(velocity.x, velocity.z).length() * 0.95
	recoil = move_toward(recoil, 0, dt * 0.45)
	muzzle_timer = maxf(0, muzzle_timer - dt)
	muzzle.visible = muzzle_timer > 0
	flash.light_energy = 3 if muzzle_timer > 0 else 0
	var target_pos := Vector3(0.27, -0.26, -0.48)
	if ads:
		target_pos = Vector3(0, -0.153, -0.40)
	var bob_strength: float = (0.002 if ads else 0.009) * game.camera_motion
	target_pos += Vector3(sin(bob) * bob_strength, cos(bob * 2) * bob_strength, recoil)
	target_pos.x -= clampf(look_delta.x * 0.1, -0.025, 0.025)
	var tilt := Vector3.ZERO
	if traversal.active:
		target_pos.y -= 0.10
		tilt.x = -0.15
	if reload_time > 0:
		var phase := sin((1 - reload_time / reload_total) * PI)
		target_pos += Vector3(0.08, -0.15, 0.08) * phase
		tilt.z = -0.6 * phase
		tilt.x = 0.25 * phase
	if melee_timer > 0:
		tilt.y = sin(melee_timer / 0.6 * PI) * 0.7
		target_pos.z -= sin(melee_timer / 0.6 * PI) * 0.2
	weapon_root.position = weapon_root.position.lerp(target_pos, minf(1, dt * 20))
	weapon_root.rotation = weapon_root.rotation.lerp(tilt, minf(1, dt * 18))
	visual_roll = lerpf(visual_roll, wall_side * 0.045 * game.camera_motion, dt * 10)
	camera.rotation = Vector3(pitch, 0, visual_roll)
	camera.fov = lerpf(camera.fov, 68.0 if ads else 86.0, minf(1, dt * 13))
	look_delta = look_delta.lerp(Vector2.ZERO, minf(1, dt * 12))
