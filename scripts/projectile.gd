extends Node3D

var game
var velocity := Vector3.ZERO
var damage: float = 10
var life: float = 2.0
var grenade: bool = false
var age: float = 0
var mesh := MeshInstance3D.new()

func setup(owner_game, direction: Vector3, amount: float, is_grenade: bool = false) -> void:
	game = owner_game
	damage = amount
	grenade = is_grenade
	velocity = direction if grenade else direction * 42
	life = 1.5 if grenade else 2
	var sphere := SphereMesh.new()
	sphere.radius = 0.12 if grenade else 0.05
	sphere.height = sphere.radius * 2
	mesh.mesh = sphere
	mesh.material_override = game.arena.material(Color("ff8955"), 0, 2.5)
	add_child(mesh)
	add_to_group("projectile")

func _physics_process(delta: float) -> void:
	if not game.is_playing():
		return
	age += delta
	life -= delta
	if life <= 0:
		if grenade:
			explode()
		else:
			queue_free()
		return
	if grenade:
		velocity.y -= 13 * delta
	var next := global_position + velocity * delta
	var ray := PhysicsRayQueryParameters3D.create(global_position, next, 5)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		global_position = hit.position + hit.normal * 0.06
		if grenade:
			velocity = velocity.bounce(hit.normal) * 0.45
		else:
			if hit.collider == game.player:
				game.player.take_damage(damage, global_position)
			game.impact(hit.position, Color("e8a76b"), 2)
			queue_free()
	else:
		global_position = next
	if grenade:
		mesh.scale = Vector3.ONE * (1 + sin(age * 24) * 0.18)

func explode() -> void:
	var distance := global_position.distance_to(game.player.global_position + Vector3.UP * 0.6)
	if distance < 4:
		var result := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position, game.player.global_position + Vector3.UP, 5))
		if result.is_empty() or result.collider == game.player:
			game.player.take_damage(40 * (1 - distance / 4), global_position, 0.5)
	game.impact(global_position, Color("ffa75c"), 16)
	game.sound.play_cue("explosion")
	queue_free()
