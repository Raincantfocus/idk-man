extends CharacterBody3D

var game
var kind: String = "enforcer"
var health: float = 100
var max_health: float = 100
var alive: bool = true
var stagger: float = 0
var speed: float = 3
var attack_timer: float = 1.2
var windup: float = 0
var grenade_timer: float = 5
var path_timer: float = 0
var sight_timer: float = 0
var sees_player: bool = false
var last_known := Vector3.ZERO
var path := PackedVector3Array()
var path_index: int = 0
var age: float = 0
var body := Node3D.new()
var color: Color
var elite_dash: float = 0
var dash_cooldown: float = 6
var attack_direction := Vector3.ZERO
var training_dummy: bool = false
var descent_time := 0.0
var descent_total := 3.0
var descent_from := Vector3.ZERO
var descent_to := Vector3.ZERO
var rope: MeshInstance3D
var animated_visual: Node3D

func setup(owner_game, archetype: String) -> void:
	game = owner_game
	kind = archetype
	var stats: Dictionary = game.balance.enemies[kind]
	health = stats.health
	max_health = health
	speed = stats.speed
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.3
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.36
	collider.shape = shape
	collider.position.y = 0.90
	add_child(collider)
	add_child(body)
	color = {"enforcer": Color("a89d81"), "rusher": Color("b7805c"), "shield": Color("728d8c"), "flusher": Color("929e65"), "elite": Color("9c6c66")}[kind]
	if kind == "elite":
		body.scale = Vector3(1.12, 1.06, 1.12)
	animated_visual = preload("res://scripts/operator_visual.gd").new()
	body.add_child(animated_visual)
	animated_visual.setup(kind)
	last_known = game.player.global_position
	path_timer = game.rng.randf_range(0, 0.25)
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	if not alive or not game.is_playing() or game.player.health <= 0:
		return
	if descent_time > 0:
		descent_time = maxf(0,descent_time-delta)
		global_position = descent_from.lerp(descent_to,1-descent_time/descent_total)
		if descent_time <= 0:
			collision_layer = 2
			if is_instance_valid(rope): rope.queue_free()
		return
	stagger = maxf(0, stagger - delta)
	if animated_visual != null:
		if animated_visual.has_method("set_windup"):
			animated_visual.set_windup(windup / 0.6)
		animated_visual.update_pose(delta, Vector2(velocity.x, velocity.z).length(), stagger > 0)
	if training_dummy:
		velocity = Vector3(0, velocity.y - 16 * delta, 0)
		move_and_slide()
		return
	age += delta
	attack_timer -= delta
	grenade_timer -= delta
	dash_cooldown -= delta
	sight_timer -= delta
	path_timer -= delta
	if sight_timer <= 0:
		sight_timer = 0.15
		sees_player = _can_see_player()
		if sees_player:
			last_known = game.player.global_position
	var target := last_known
	var offset := target - global_position
	var flat := Vector3(offset.x, 0, offset.z)
	if flat.length() > 0.1:
		body.rotation.y = lerp_angle(body.rotation.y, atan2(-flat.x, -flat.z), minf(1, delta * 7))
	if path_timer <= 0:
		path_timer = game.rng.randf_range(0.45, 0.7)
		path = game.arena.path_to(global_position, target)
		path_index = 1 if path.size() > 1 else 0
	var direction := Vector3.ZERO
	var desired_range: float = 2.0 if kind in ["rusher", "shield"] else 9.0
	if flat.length() > desired_range or not sees_player or absf(offset.y) > 1.8:
		if path_index < path.size():
			var next := path[path_index]
			var next_flat := Vector3(next.x - global_position.x, 0, next.z - global_position.z)
			if next_flat.length() < 0.35 and absf(next.y - global_position.y) < 0.7:
				path_index += 1
			else:
				direction = next_flat.normalized()
	elif sees_player and flat.length() > 4:
		direction = Vector3(-flat.z, 0, flat.x).normalized() * sin(age * 0.6 + get_instance_id() % 8) * 0.35
	# Limited pairwise separation prevents formations becoming a single stacked target.
	for other in game.enemies:
		if other != self and is_instance_valid(other) and other.alive:
			var separation: Vector3 = global_position - other.global_position
			if absf(separation.y) > 1.8:
				continue
			separation.y = 0
			if separation.length_squared() < 1.0 and separation.length_squared() > 0.001:
				direction += separation.normalized() * 0.6
	if stagger > 0:
		direction = Vector3.ZERO
		windup = 0
	if kind == "elite" and sees_player and dash_cooldown <= 0 and flat.length() > 5:
		elite_dash = 0.45
		dash_cooldown = 7
		attack_direction = flat.normalized()
		game.notice("ELITE // BREACH", 1.0)
	if elite_dash > 0:
		elite_dash -= delta
		direction = attack_direction * 3
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y -= 16 * delta
	move_and_slide()
	if stagger > 0 or age < 1.2:
		return
	if windup > 0:
		windup -= delta
		if windup <= 0:
			_attack()
	elif sees_player and attack_timer <= 0 and game.attacking_count() < mini(5, 2 + game.wave / 3):
		windup = 0.6
		attack_timer = game.balance.enemies[kind].fire_interval
		game.tracer(global_position + Vector3(0, 1.5, 0), global_position + Vector3(0, 2.0, 0), Color("ef8051"), 0.15)
	if kind == "flusher" and sees_player and grenade_timer <= 0 and game.live_grenades() < 2:
		grenade_timer = 8
		game.spawn_grenade(global_position + Vector3.UP * 1.4, game.player.global_position + Vector3.UP * 0.5)

func _can_see_player() -> bool:
	if game.player.ability == "shroud":
		# The first prototype retains last-known position, without hidden tracking.
		return false
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.5, game.player.global_position + Vector3.UP, 5)
	var result := get_world_3d().direct_space_state.intersect_ray(ray)
	return not result.is_empty() and result.collider == game.player

func _attack() -> void:
	if animated_visual.has_method("on_attack"):
		animated_visual.on_attack()
	var target := last_known + Vector3.UP * 1.05
	if kind in ["rusher", "shield"] and global_position.distance_to(last_known) < 2.4:
		if global_position.distance_to(game.player.global_position) < 2.4:
			game.player.take_damage(float(game.balance.enemies[kind].damage), global_position, 0.25)
		return
	if kind == "shield":
		return
	var origin := global_position + Vector3.UP * 1.3 - body.global_basis.z * 0.65
	var spread := Vector3(game.rng.randf_range(-0.6, 0.6), game.rng.randf_range(-0.25, 0.25), game.rng.randf_range(-0.6, 0.6))
	game.spawn_bullet(origin, (target + spread - origin).normalized(), float(game.balance.enemies[kind].damage))
	game.impact(origin, Color("ffad60"), 2)

func take_damage(amount: float, hit_position: Vector3, headshot: bool = false, bypass_shield: bool = false) -> void:
	if not alive:
		return
	if kind == "shield" and not bypass_shield and hit_position.y - global_position.y > 0.5:
		var to_player: Vector3 = (game.player.global_position - global_position).normalized()
		if (-body.global_basis.z).dot(to_player) > 0.45:
			game.impact(hit_position, Color("ffda99"), 5)
			game.sound.play_cue("metal")
			return
	health -= amount
	game.blood_burst(hit_position, (hit_position - game.player.camera.global_position).normalized(), 4)
	game.impact(hit_position, Color("ab493a") if game.gore_enabled else Color("d8cc9e"), 5)
	if health <= 0:
		alive = false
		collision_layer = 0
		collision_mask = 0
		game.enemy_killed(self, headshot)
		var local_hit := body.to_local(hit_position)
		var corpse = game.spawn_corpse(body, global_position, color)
		if corpse != null and game.gore_enabled:
			var region: String = corpse.region_at(local_hit)
			if region != "torso": corpse.sever(region)
		queue_free()

func begin_descent(from: Vector3, to: Vector3, duration: float) -> void:
	descent_time = duration
	descent_total = duration
	descent_from = from
	descent_to = to
	global_position = from
	collision_layer = 2
	rope = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = .025
	mesh.bottom_radius = .025
	mesh.height = from.distance_to(to)
	rope.mesh = mesh
	rope.material_override = game.arena.material(Color("49473e"))
	add_child(rope)
	rope.set_as_top_level(true)
	rope.global_position = (from+to)/2
