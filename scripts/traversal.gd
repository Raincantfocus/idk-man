extends RefCounted
## Fixed-action-time traversal with swept collision checks, never teleportation.
const MIN_HEIGHT := 0.45
const MAX_HEIGHT := 1.85
const VAULT_HEIGHT := 1.40
const REACH := 1.05
var player: CharacterBody3D
var active := false
var kind := ""
var cooldown := 0.0
var points := PackedVector3Array()
var elapsed := 0.0
var duration := 0.0
var total_length := 0.0
var exit_velocity := Vector3.ZERO

func setup(owner_player: CharacterBody3D) -> void:
	player = owner_player

func ray(from: Vector3, to: Vector3) -> Dictionary:
	return player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))

func clear_at(foot: Vector3, low_profile: bool = false) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = player.capsule.shape if low_profile else player.standing_shape
	query.transform = Transform3D(Basis.IDENTITY, foot + Vector3.UP * (query.shape.height/2))
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	query.margin = 0.005
	return player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func path_clear(route: PackedVector3Array, low_profile: bool = false) -> bool:
	var saved_height: float = player.capsule.shape.height
	var saved_y: float = player.capsule.position.y
	if low_profile:
		player.capsule.shape.height = 1.0
		player.capsule.position.y = .5
	var clear := true
	for i in range(1, route.size()):
		var pose := player.global_transform
		pose.origin = route[i - 1]
		if player.test_move(pose, route[i] - route[i - 1]):
			clear = false
			break
	clear = clear and clear_at(route[-1],low_profile)
	player.capsule.shape.height = saved_height
	player.capsule.position.y = saved_y
	return clear

func find_route(direction: Vector3) -> Dictionary:
	if direction.length_squared() < 0.5 or player.capsule.shape.height < 1.7:
		return {}
	direction = Vector3(direction.x, 0, direction.z).normalized()
	var start := player.global_position
	var face := ray(start + Vector3.UP * 0.35, start + Vector3.UP * 0.35 + direction * REACH)
	if face.is_empty():
		face = ray(start + Vector3.UP, start + Vector3.UP + direction * REACH)
	if face.is_empty() or face.collider.get_meta("surface_tag","") == "NO_GRIP" or absf(face.normal.y) > 0.2 or face.normal.dot(-direction) < 0.6:
		return {}
	# Explicit map-tagged windows only: tuck through the 1.2m aperture.
	# The standard standing vault path and all weapon/gameplay tuning stay intact.
	if face.collider.has_meta("vault_window_top"):
		var sill_y: float = face.collider.get_meta("vault_window_top")
		var peak := Vector3(start.x,sill_y+.035,start.z)
		var beyond: Vector3 = face.position+direction*1.25
		var floor_hit := ray(Vector3(beyond.x,sill_y,beyond.z),Vector3(beyond.x,start.y-1.25,beyond.z))
		if not floor_hit.is_empty() and floor_hit.normal.y>.85:
			var landing: Vector3 = floor_hit.position+Vector3.UP*.035
			var route := PackedVector3Array([start,peak,Vector3(landing.x,peak.y,landing.z),landing])
			if path_clear(route,true):return {"kind":"WINDOW VAULT","points":route,"low_profile":true}
		return {}
	var probe: Vector3 = face.position + direction * 0.48
	var top := ray(Vector3(probe.x, start.y + MAX_HEIGHT + 0.08, probe.z), Vector3(probe.x, start.y + MIN_HEIGHT, probe.z))
	if top.is_empty() or top.normal.y < 0.85:
		return {}
	var height: float = top.position.y - start.y
	if height < MIN_HEIGHT or height > MAX_HEIGHT:
		return {}
	var peak_y: float = top.position.y + 0.07
	var raised := Vector3(start.x, peak_y, start.z)
	# Prefer a vault only if there is a shallow obstacle AND a supported far landing.
	if height <= VAULT_HEIGHT:
		for depth in [1.0, 1.4, 1.8, 2.2]:
			var beyond: Vector3 = face.position + direction * depth
			var floor_hit := ray(Vector3(beyond.x, peak_y, beyond.z), Vector3(beyond.x, start.y - 1.25, beyond.z))
			if floor_hit.is_empty() or floor_hit.normal.y < 0.85 or floor_hit.position.y > start.y + 0.25:
				continue
			var landing: Vector3 = floor_hit.position + Vector3.UP * 0.035
			var route := PackedVector3Array([start, raised, Vector3(landing.x, peak_y, landing.z), landing])
			if path_clear(route):
				return {"kind": "VAULT", "points": route}
	var landing: Vector3 = top.position + Vector3.UP * 0.035
	var route := PackedVector3Array([start, raised, Vector3(landing.x, peak_y, landing.z), landing])
	if path_clear(route):
		return {"kind": "MANTLE", "points": route}
	return {}

func try_start(direction: Vector3) -> bool:
	if active or cooldown > 0 or player.health <= 0:
		return false
	var plan := find_route(direction)
	if plan.is_empty():
		return false
	if plan.get("low_profile",false):
		player.capsule.shape.height = 1.0
		player.capsule.position.y = .5
		player.camera.position.y = .9
	kind = plan.kind
	points = plan.points
	total_length = 0
	for i in range(1, points.size()):
		total_length += points[i - 1].distance_to(points[i])
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	exit_velocity = direction.normalized() * clampf(speed, 3.0, 11.0)
	duration = clampf(total_length / 10.5, 0.32, 0.72)
	elapsed = 0
	active = true
	player.velocity = Vector3.ZERO
	player.dash_time = 0
	player.slide_time = 0
	player.jump_buffer = 0
	player.coyote = 0
	player.wall_side = 0
	player.mode = kind
	return true

func step(dt: float) -> void:
	if not active:
		return
	elapsed = minf(duration, elapsed + dt)
	var distance := smoothstep(0, 1, elapsed / duration) * total_length
	var target := points[-1]
	for i in range(1, points.size()):
		var length := points[i - 1].distance_to(points[i])
		if distance <= length:
			target = points[i - 1].lerp(points[i], distance / maxf(length, 0.0001))
			break
		distance -= length
	# Recheck the actual motion every tick: newly arriving actors can block a climb.
	var collision := player.move_and_collide(target - player.global_position)
	player.mode = kind
	if collision != null:
		cancel()
	elif elapsed >= duration:
		active = false
		cooldown = 0.20
		player.velocity = exit_velocity

func cancel() -> void:
	active = false
	points.clear()
	cooldown = 0.20
	player.velocity = Vector3.ZERO
