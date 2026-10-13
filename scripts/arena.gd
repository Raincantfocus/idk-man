extends Node3D
## Procedural greybox with an authored visual language and deterministic AI grid.

var navigation := AStarGrid2D.new()
var spawn_points: Array[Vector3] = [Vector3(-19, 1, -14), Vector3(19, 1, -14), Vector3(-19, 1, 14), Vector3(19, 1, 14)]
var concrete: StandardMaterial3D
var dark: StandardMaterial3D
var steel: StandardMaterial3D
var acid: StandardMaterial3D
var amber: StandardMaterial3D
var blockers: Array[Rect2] = []

func material(color: Color, metallic: float = 0.0, emission: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.78
	if emission > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	return mat

func box(pos: Vector3, size: Vector3, mat: Material, solid: bool = true, nav_block: bool = false) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.position = pos
	add_child(root)
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	root.add_child(mesh)
	if solid:
		root.collision_layer = 1
		root.collision_mask = 0
		var collider := CollisionShape3D.new()
		var collision := BoxShape3D.new()
		collision.size = size
		collider.shape = collision
		root.add_child(collider)
	if nav_block:
		blockers.append(Rect2(Vector2(pos.x - size.x / 2 - 0.55, pos.z - size.z / 2 - 0.55), Vector2(size.x + 1.1, size.z + 1.1)))
	return root

func label_3d(text: String, pos: Vector3, size: int = 100, color: Color = Color("d7dfd8"), rotation_y: float = 0.0) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.012
	label.position = pos
	label.rotation.y = rotation_y
	label.modulate = color
	label.outline_size = 0
	add_child(label)
	return label

func build() -> void:
	concrete = material(Color("454f51"))
	dark = material(Color("172528"), 0.4)
	steel = material(Color("627172"), 0.7)
	acid = material(Color("d1e985"), 0.1, 0.8)
	amber = material(Color("f1a24d"), 0.1, 1.0)
	var floor_mat := material(Color("283436"), 0.25)
	box(Vector3(0, -0.5, 0), Vector3(48, 1, 40), floor_mat)
	box(Vector3(0, 5, -20), Vector3(48, 10, 1), concrete)
	box(Vector3(0, 5, 20), Vector3(48, 10, 1), concrete)
	box(Vector3(-24, 5, 0), Vector3(1, 10, 40), concrete)
	box(Vector3(24, 5, 0), Vector3(1, 10, 40), concrete)
	# Floor seams and the yellow testing boundary are unlit, inexpensive geometry.
	for x in range(-22, 24, 4):
		box(Vector3(x, 0.008, 0), Vector3(0.035, 0.008, 38), dark, false)
	for z in range(-18, 20, 4):
		box(Vector3(0, 0.009, z), Vector3(46, 0.008, 0.035), dark, false)
	for x in [-11, 11]:
		box(Vector3(x, 0.018, 0), Vector3(0.10, 0.012, 25), acid, false)
	for z in [-12.5, 12.5]:
		box(Vector3(0, 0.018, z), Vector3(22, 0.012, 0.10), acid, false)
	# Main reactor: opaque mass breaks sight lines, gaps on both flanks.
	box(Vector3(0, 1.8, -1.5), Vector3(6, 3.6, 6), dark, true, true)
	box(Vector3(0, 3.7, -1.5), Vector3(6.4, 0.25, 6.4), steel)
	for x in [-3.06, 3.06]:
		for z in range(-4, 2):
			box(Vector3(x, 1.6, z), Vector3(0.04, 2.2, 0.10), acid, false)
	label_3d("K—17", Vector3(0, 2.0, 1.515), 110)
	label_3d("KINETIC EVALUATION / CORE", Vector3(0, 0.75, 1.52), 24, Color("aebeb7"))
	for pos in [Vector3(-9, 0.65, 5), Vector3(9, 0.65, -6), Vector3(-13, 0.65, -9), Vector3(13, 0.65, 9), Vector3(6.7, 0.65, 7)]:
		box(pos, Vector3(3.8, 1.3, 1.5), concrete, true, true)
		box(pos + Vector3(0, 0.68, 0), Vector3(3.9, 0.08, 1.6), steel)
		box(pos + Vector3(0, 0.43, 0.76), Vector3(3.2, 0.12, 0.025), acid, false)
	# Gallery and broad staircase; enemies use the ground grid in this first slice.
	box(Vector3(0, 4.0, -15.4), Vector3(34, 0.4, 6.4), dark)
	for x in [-16, -8, 8, 16]:
		box(Vector3(x, 2.0, -17), Vector3(0.65, 4, 0.65), steel, true, true)
		box(Vector3(x, 4.8, -12.3), Vector3(0.10, 1.35, 0.1), steel)
	for x in [-10, 10]:
		box(Vector3(x, 5.25, -12.3), Vector3(12, 0.10, 0.10), steel)
	for i in range(14):
		var y := 0.30 * (i + 1)
		box(Vector3(19.2, y / 2, -4.0 - i * 0.62), Vector3(3.8, y, 0.64), concrete)
		box(Vector3(19.2, y + 0.007, -3.72 - i * 0.62), Vector3(3.8, 0.01, 0.07), acid, false)
	blockers.append(Rect2(Vector2(16.7, -13.1), Vector2(5.0, 10.0)))
	# Wall-running lane and low clearance slide route.
	box(Vector3(-17, 1.6, 2), Vector3(0.5, 3.2, 12), concrete, true, true)
	box(Vector3(-16.73, 2.2, 2), Vector3(0.02, 0.18, 11), acid, false)
	box(Vector3(-10, 1.48, 11), Vector3(7, 0.28, 2.0), steel)
	for x in [-13.4, -6.6]:
		box(Vector3(x, 0.65, 11), Vector3(0.22, 1.3, 2), steel, true, true)
	# Repeated structural bays and overhead light strips.
	for x in [-21, -14, -7, 0, 7, 14, 21]:
		box(Vector3(x, 5, -19.35), Vector3(0.28, 10, 0.25), dark)
		box(Vector3(x, 7.3, 0), Vector3(0.25, 0.35, 40), dark, false)
		box(Vector3(x, 7.05, -2), Vector3(0.12, 0.10, 23), acid, false)
	label_3d("ZERO / LINE", Vector3(-7, 6.0, -19.42), 130)
	label_3d("ADAPTIVE COMBAT SYSTEMS     •     SECTOR 017", Vector3(-7, 4.9, -19.4), 26, Color("d1e985"))
	label_3d("SURVIVAL IS A PERFORMANCE METRIC.", Vector3(0, 4, 19.42), 62, Color("c4d0c5"), PI)
	for i in spawn_points.size():
		var p := spawn_points[i]
		var back := -19.3 if p.z < 0 else 19.3
		box(Vector3(p.x, 1.8, back), Vector3(4.1, 3.6, 0.25), dark, false)
		box(Vector3(p.x, 3.6, back + (0.2 if p.z < 0 else -0.2)), Vector3(4.1, 0.16, 0.15), amber, false)
		label_3d("0%d / ENTRY" % (i + 1), Vector3(p.x, 4.2, back + (0.2 if p.z < 0 else -0.2)), 38, Color("f1b367"), 0 if p.z < 0 else PI)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("172629")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("afc4be")
	settings.ambient_light_energy = 0.7
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	settings.fog_enabled = true
	settings.fog_light_color = Color("354845")
	settings.fog_density = 0.006
	environment.environment = settings
	add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-65, -28, 0)
	key.light_color = Color("dbe6c8")
	key.light_energy = 1.1
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 65
	add_child(key)
	for p in [Vector3(-12, 5, 6), Vector3(12, 5, -8), Vector3(2, 5, 10)]:
		var light := OmniLight3D.new()
		light.position = p
		light.light_color = Color("bfdfb3")
		light.light_energy = 2
		light.omni_range = 16
		add_child(light)
	_build_navigation()

func _build_navigation() -> void:
	navigation.region = Rect2i(-23, -19, 46, 38)
	navigation.cell_size = Vector2.ONE
	navigation.offset = Vector2(0.5, 0.5)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for x in range(-23, 23):
		for z in range(-19, 19):
			for rect in blockers:
				if rect.has_point(Vector2(x + 0.5, z + 0.5)):
					navigation.set_point_solid(Vector2i(x, z))
					break

func nearest_cell(pos: Vector3) -> Vector2i:
	var cell := Vector2i(clampi(floori(pos.x), -22, 21), clampi(floori(pos.z), -18, 17))
	if not navigation.is_point_solid(cell):
		return cell
	for radius in range(1, 7):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var candidate := cell + Vector2i(x, y)
				if navigation.is_in_boundsv(candidate) and not navigation.is_point_solid(candidate):
					return candidate
	return cell

func path_to(from: Vector3, to: Vector3) -> PackedVector2Array:
	return navigation.get_point_path(nearest_cell(from), nearest_cell(to))
