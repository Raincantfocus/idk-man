extends CharacterBody3D
const TraversalScript = preload("res://scripts/traversal.gd")
var traversal = TraversalScript.new()

var game
var camera := Camera3D.new()
var weapon_root := Node3D.new()
var capsule := CollisionShape3D.new()
var jump_speed := 5.6
var slope_boost := 0.0
var on_boost_slope := false
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
const SLIDE_MAX_SPEED := 18.0
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
var weapon_view: Node3D
var magazine_seated := [true, true, true]
var reload_had_magazine := true
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
	if game.arena.has_method("configure_player"): game.arena.configure_player(self)
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

func _build_weapon() -> void:
	weapon_view = preload("res://scripts/weapon_view.gd").new()
	weapon_root.add_child(weapon_view)
	weapon_view.setup(self)

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
	slope_boost = maxf(0,slope_boost-dt)
	if slide_time <= 0: on_boost_slope = false
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
	if not game.arena.has_method("configure_player") or game.arena.zip_time <= 0:
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
			if not result.is_empty() and absf(result.normal.y) < 0.2 and result.collider.get_meta("surface_tag","WALLRUN_OK") == "WALLRUN_OK":
				wall_side = side
				wall_normal = result.normal
				break
	var crouch := Input.is_action_pressed("slide") or slide_time > 0
	if dash_time > 0:
		dash_time -= dt
		flat = dash_dir * 14
		mode = "DASH"
	elif slide_time > 0:
		flat = _slide_momentum(flat, direction, dt)
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
			flat = flat.limit_length(maxf(11, minf(SLIDE_MAX_SPEED, Vector2(velocity.x, velocity.z).length())))
		mode = "CROUCH" if crouch else ("SPRINT" if speed > 5 and input.length() > 0 else "READY")
		if not is_on_floor():
			mode = "AIRBORNE"
	if jump_buffer > 0 and (coyote > 0 or wall_side != 0):
		velocity.y = jump_speed
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
	if not crouch and capsule.shape.height < standing_shape.height:
		crouch = not can_stand()
	capsule.shape.height = 1.0 if crouch else standing_shape.height
	capsule.position.y = capsule.shape.height / 2
	camera.position.y = lerpf(camera.position.y, 0.90 if crouch else 1.55, minf(1, dt * 16))
	floor_snap_length = 0.6 if slide_time > 0 else 0.4
	if slide_time > 0 and is_on_floor() and jump_buffer <= 0:
		var normal := get_floor_normal()
		velocity.y = -(normal.x * flat.x + normal.z * flat.z) / maxf(normal.y, 0.1)
	velocity.x = flat.x
	velocity.z = flat.z
	# Small step-up handles low lips and continuous ramp transitions.
	if is_on_floor() and flat.length() > 0.1 and (slide_time <= 0 or get_floor_normal().y > 0.995):
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
	if dash_time <= 0 and flat.length() > SLIDE_MAX_SPEED:
		var limited := Vector3(velocity.x, 0, velocity.z).limit_length(SLIDE_MAX_SPEED)
		velocity.x = limited.x
		velocity.z = limited.z

func _slide_momentum(flat: Vector3, direction: Vector3, dt: float) -> Vector3:
	# Gravity projected onto the actual contact plane: no downhill speed bonus
	# from camera direction, and no acceleration while airborne.
	slide_time = maxf(0, slide_time - dt)
	if not is_on_floor():
		return flat
	var normal := get_floor_normal()
	var gravity := Vector3.DOWN * 22.0
	var slope_force := gravity.slide(normal)
	slope_force.y = 0
	var downhill := flat.normalized().dot(slope_force) > 0.6
	var tagged := false
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		if hit.get_normal().y > .5 and hit.get_collider().get_meta("surface_tag","") == "SLIDE_OK": tagged = true
	if on_boost_slope and normal.y > .995:
		slope_boost = 2.0
		flat = (flat*1.25).limit_length(SLIDE_MAX_SPEED)
	on_boost_slope = downhill and tagged
	if slope_boost > 0: slide_time = maxf(slide_time,.24)
	if downhill and flat.length() > 4.0:
		slide_time = maxf(slide_time, 0.24)
	var friction := 1.2 if normal.y < 0.995 else 5.0
	flat = (flat + slope_force * dt).move_toward(Vector3.ZERO, friction * dt)
	# Steering changes heading, not energy; backward input acts as a brake.
	if direction.length_squared() > 0.1:
		if flat.normalized().dot(direction) < -0.5:
			flat = flat.move_toward(Vector3.ZERO, 9.0 * dt)
		else:
			flat = flat.normalized().lerp(direction, dt * 1.3).normalized() * flat.length()
	if flat.length() < 3.0:
		slide_time = 0
	return flat.limit_length(SLIDE_MAX_SPEED)

func can_stand() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = standing_shape
	query.transform = global_transform.translated_local(Vector3.UP * (standing_shape.height/2+.02))
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
	muzzle_timer = 0.035
	weapon_view.on_fire()
	recoil = minf(0.12, recoil + 0.055 * recoil_multiplier)
	var origin := camera.global_position
	var forward := -camera.global_transform.basis.z
	var spread: float = stats.spread * (0.35 if Input.is_action_pressed("aim") else 1.0)
	for pellet in int(stats.pellets):
		var direction: Vector3 = (forward + camera.global_basis.x * game.rng.randf_range(-spread, spread) + camera.global_basis.y * game.rng.randf_range(-spread, spread)).normalized()
		var ray := PhysicsRayQueryParameters3D.create(origin, origin + direction * 90, 19)
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		var target: Vector3 = hit.position if not hit.is_empty() else origin + direction * 70
		# Authoritative muzzle obstruction avoids shooting through a nearby wall.
		var muzzle_position: Vector3 = weapon_view.muzzle_position()
		var obstruction := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, muzzle_position, 1))
		if not obstruction.is_empty():
			hit = obstruction
			target = hit.position
		elif not hit.is_empty():
			var muzzle_hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(muzzle_position, target + direction * 0.05, 19))
			if not muzzle_hit.is_empty():
				hit = muzzle_hit
				target = hit.position
		if not hit.is_empty():
			if hit.collider.has_method("take_damage"):
				var headshot: bool = target.y - hit.collider.global_position.y > 1.55
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
	reload_had_magazine = magazine_seated[weapon_index]
	reload_total = weapon().reload_seconds
	reload_time = reload_total
	reload_stage = 0
	game.sound.play_cue("reload")
	return true

func _reload_tick(dt: float) -> void:
	if reload_time <= 0:
		return
	reload_time = maxf(0, reload_time - dt)
	if weapon_index == 1:
		# Tube-fed shotgun: each completed cycle commits exactly one shell.
		if reload_time <= 0:
			if ammo[1] < max_ammo() and reserve[1] > 0:
				ammo[1] += 1
				reserve[1] -= 1
				game.sound.play_cue("reload")
			if ammo[1] < max_ammo() and reserve[1] > 0: reload_time = reload_total
		magazine_seated[1] = true
		return
	var progress := 1 - reload_time / reload_total
	if progress >= 0.28 and reload_stage == 0:
		if weapon_index != 2:
			reserve[weapon_index] += ammo[weapon_index]
		ammo[weapon_index] = 0
		reload_stage = 1
		magazine_seated[weapon_index] = false
	if progress >= 0.78 and reload_stage == 1:
		var amount: int = max_ammo() if weapon_index == 2 else mini(max_ammo(), reserve[weapon_index])
		ammo[weapon_index] = amount
		if weapon_index != 2:
			reserve[weapon_index] -= amount
		reload_stage = 2
		magazine_seated[weapon_index] = true
		game.sound.play_cue("reload")

func switch_weapon(index: int) -> void:
	reload_time = 0
	reload_stage = 0
	weapon_index = index
	muzzle_timer = 0
	flash.light_energy = 0
	shot_timer = 0.15
	recoil = 0.10
	weapon_view.select_weapon(index)

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
		muzzle_timer = 0
		weapon_view.muzzle_flash.visible = false
		flash.light_energy = 0
		end_ability()
		game.defeat()

func _visuals(dt: float) -> void:
	weapon_root.visible = ability != "shroud"
	var ads := Input.is_action_pressed("aim")
	bob += dt * Vector2(velocity.x, velocity.z).length() * 0.95
	recoil = move_toward(recoil, 0, dt * 0.45)
	muzzle_timer = maxf(0, muzzle_timer - dt)
	weapon_view.update_pose(dt)
	flash.light_energy = 3 if muzzle_timer > 0 else 0
	var target_pos: Vector3 = weapon_view.HIP[weapon_index]
	if ads:
		target_pos = weapon_view.ads_position()
	var bob_strength: float = (0.002 if ads else 0.009) * game.camera_motion
	target_pos += Vector3(sin(bob) * bob_strength, cos(bob * 2) * bob_strength, recoil)
	target_pos.x -= clampf(look_delta.x * 0.1, -0.025, 0.025)
	var tilt := Vector3(recoil * (1.6 if weapon_index == 1 else 0.65), 0, 0)
	target_pos.y -= weapon_view.equip_time * 0.8
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
