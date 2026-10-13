extends RigidBody3D
## Resource transfer is immediate and idempotent; attraction is presentation only.

enum State { SPAWNING, AVAILABLE, RESERVED, CONSUMED }
var game
var kind: String = "health"
var remaining: float = 20
var state: State = State.SPAWNING
var age: float = 0
var transfer_sequence: int = 0
var visual := Node3D.new()

func setup(owner_game, type: String) -> void:
	game = owner_game
	kind = type
	remaining = {"health": 20.0, "armor": 25.0, "ammo": 30.0}[kind]
	collision_layer = 8
	collision_mask = 1
	mass = 0.2
	linear_damp = 1.2
	angular_damp = 2
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.28, 0.15, 0.25)
	shape.shape = box
	add_child(shape)
	add_child(visual)
	var color: Color = {"health": Color("df947e"), "armor": Color("96dbd1"), "ammo": Color("d4e786")}[kind]
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.30, 0.13, 0.25)
	item.mesh = mesh
	item.material_override = game.arena.material(color, 0.2, 0.5)
	visual.add_child(item)
	var label := Label3D.new()
	label.text = {"health": "+", "armor": "A", "ammo": "="}[kind]
	label.font_size = 56
	label.pixel_size = 0.008
	label.position.y = 0.38
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.no_depth_test = false
	visual.add_child(label)
	linear_velocity = Vector3(game.rng.randf_range(-1.2, 1.2), 2, game.rng.randf_range(-1.2, 1.2))
	add_to_group("pickup")

func _physics_process(delta: float) -> void:
	age += 1.0 / Engine.physics_ticks_per_second
	if state == State.SPAWNING and age >= 0.08:
		state = State.AVAILABLE
	if global_position.y < -3:
		global_position = Vector3(clampf(global_position.x, -21, 21), 0.4, clampf(global_position.z, -17, 17))
		linear_velocity = Vector3.ZERO

func collect(player) -> float:
	if state != State.AVAILABLE or player.health <= 0:
		return 0
	var capacity: float = 0
	var weapon_index: int = player.weapon_index if player.weapon_index < 2 else 0
	if kind == "health":
		capacity = 100 - player.health
	elif kind == "armor":
		capacity = 100 - player.armor
	else:
		if player.reserve[weapon_index] >= int(game.balance.weapons[player.weapon_ids[weapon_index]].reserve):
			weapon_index = 1 - weapon_index
		capacity = int(game.balance.weapons[player.weapon_ids[weapon_index]].reserve) - player.reserve[weapon_index]
	var amount := minf(remaining, capacity)
	if amount <= 0:
		return 0
	state = State.RESERVED
	transfer_sequence += 1
	if kind == "health":
		player.health += amount
	elif kind == "armor":
		player.armor += amount
	else:
		player.reserve[weapon_index] += int(amount)
	remaining -= amount
	game.pickup_flash = 0.3
	game.recovered += amount if kind != "ammo" else 0
	game.sound.play_cue("pickup")
	if remaining <= 0:
		state = State.CONSUMED
		collision_layer = 0
		freeze = true
		var tween := create_tween().set_ignore_time_scale(true)
		tween.tween_property(visual, "scale", Vector3.ZERO, 0.10)
		tween.tween_callback(queue_free)
	else:
		state = State.AVAILABLE
	return amount
