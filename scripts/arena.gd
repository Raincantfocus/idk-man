extends Node3D
const ArtScript = preload("res://scripts/industrial_art.gd")
var art = ArtScript.new()
## Phase 1: three connected elevations, shared geometry/navigation definitions.

const BOUNDS := Rect2(-48, -40, 96, 80)
const PLAYER_START := Vector3(0, 0.05, 31)
const MID_HEIGHT := 4.2
const HIGH_HEIGHT := 8.4
const PRACTICE_ROUTES := [
	{"name": "GROUND RUN-UP", "point": PLAYER_START, "yaw": 0.0},
	{"name": "WEST GALLERY", "point": Vector3(-26, 4.25, 10), "yaw": 0.0},
	{"name": "OBSERVATION DECK", "point": Vector3(0, 8.45, -29), "yaw": PI},
	{"name": "GANTRY JUMP", "point": Vector3(0, 8.45, -9), "yaw": PI},
	{"name": "WALL-RUN LANE", "point": Vector3(40, 0.05, 30), "yaw": 0.0},
	{"name": "SLIDE TUNNEL", "point": Vector3(-12, 0.05, 32), "yaw": 0.0},
	{"name": "VAULT BAY", "point": Vector3(-5, 0.05, 32), "yaw": 0.0},
	{"name": "MANTLE BAY", "point": Vector3(5, 0.05, 25), "yaw": 0.0}
]
var navigation := AStar3D.new()
var spawn_points: Array[Vector3] = [
	Vector3(-26, 0.1, 34), Vector3(26, 0.1, 34),
	Vector3(-43, 0.1, 7), Vector3(43, 0.1, 7),
	Vector3(-43, 0.1, -29), Vector3(43, 0.1, -29),
	Vector3(-34, 4.3, 7), Vector3(34, 4.3, 7),
	Vector3(-29, 8.5, -29), Vector3(29, 8.5, -29)]
var lab_stations: Array[Vector3] = [Vector3(0, 0.05, 18), Vector3(-34, 4.25, 1), Vector3(12, 8.45, -29)]
var concrete: StandardMaterial3D
var dark: StandardMaterial3D
var steel: StandardMaterial3D
var acid: StandardMaterial3D
var amber: StandardMaterial3D
var blockers: Array[AABB] = []
var surfaces: Array[Dictionary] = []
var cells: Dictionary = {}

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
		blockers.append(AABB(pos - size / 2, size))
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
	art.setup()
	concrete = art.pbr("tile_default_metal", 0.5)
	dark = art.pbr("tile_painted_gun_metal", 0.5)
	steel = art.pbr("tile_default_metal", 1.0)
	acid = material(Color("d1e985"), 0.1, 0.8)
	amber = material(Color("f1a24d"), 0.1, 1.0)
	var floor_mat := art.pbr("tile_simple_floor", 0.25)
	box(Vector3(0, -0.5, 0), Vector3(96, 1, 80), floor_mat)
	surfaces.append({"rect": Rect2(-47, -39, 94, 78), "low": 0.0, "high": 0.0})
	box(Vector3(0, 9, -40), Vector3(96, 18, 1), concrete)
	box(Vector3(0, 9, 40), Vector3(96, 18, 1), concrete)
	box(Vector3(-48, 9, 0), Vector3(1, 18, 80), concrete)
	box(Vector3(48, 9, 0), Vector3(1, 18, 80), concrete)
	# The PBR floor supplies seams and surface detail without separate seam meshes.
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
		cargo_cover(pos, Vector3(3.8, 1.3, 1.5))
	# Broad, connected decks: both sides have independent ground and upper ramps.
	platform(Rect2(-38, -22, 18, 36), MID_HEIGHT)
	platform(Rect2(20, -22, 18, 36), MID_HEIGHT)
	platform(Rect2(-38, -34, 76, 12), HIGH_HEIGHT)
	platform(Rect2(-20, -18, 40, 6), MID_HEIGHT)
	for side in [-1, 1]:
		ramp(Rect2(side * 26 - 3, 14, 6, 16), 0, MID_HEIGHT)
		ramp(Rect2(side * 29 - 3, -22, 6, 16), MID_HEIGHT, HIGH_HEIGHT)
		# A wide wall-running bypass with a continuous 28 m wall and exit space.
		box(Vector3(side * 41, 3, 12), Vector3(0.5, 6, 28), concrete, true, true)
		box(Vector3(side * 40.73, 2.0, 12), Vector3(0.025, 0.17, 26), acid, false)
		box(Vector3(side * 40.73, 4.8, 12), Vector3(0.025, 0.08, 26), acid, false)
		for z in [-30, -12, 8]:
			box(Vector3(side * 36, 2, z), Vector3(0.6, 4, 0.6), steel, true, true)
		# Gallery edge barriers leave deliberately open jump/drop access points.
		for z in [-19, 5]:
			box(Vector3(side * 20.1, 4.75, z), Vector3(0.20, 1.1, 5), steel, true, true)
		cargo_cover(Vector3(side * 33, 4.85, 3), Vector3(3.8, 1.3, 1.5))
		label_3d("02 / GALLERY", Vector3(side * 30, 6.8, -21.6), 58, Color("d1e985"))
	# Upper gantry with a measured four-meter jump gap. The far pad is player-only.
	platform(Rect2(-3, -22, 6, 18), HIGH_HEIGHT)
	platform(Rect2(-3, 0, 6, 8), HIGH_HEIGHT, false)
	for z in [-4.1, 0.1]:
		box(Vector3(0, 8.42, z), Vector3(6, 0.02, 0.12), amber, false)
	label_3d("4m / GAP", Vector3(0, 9.0, -5.2), 34, Color("f1a24d"), PI)
	for x in [-13, 13]:
		cargo_cover(Vector3(x, 9.05, -28), Vector3(4.5, 1.3, 1.5))
	label_3d("03 / OBSERVATION", Vector3(0, 11.3, -33.5), 100, Color("d1e985"))
	# Jumpable ledges rise in 70 cm increments toward the east gallery.
	var ledges := [Vector3(10, 0.7, 26), Vector3(14, 1.4, 26), Vector3(18, 2.1, 26), Vector3(18, 2.8, 21), Vector3(18, 3.5, 16)]
	for p in ledges:
		box(Vector3(p.x, p.y / 2, p.z), Vector3(2.8, p.y, 2.8), concrete, true, true)
		box(p + Vector3.UP * 0.015, Vector3(2.8, 0.025, 2.8), steel, false)
		label_3d("+%.1fm" % p.y, p + Vector3(0, 0.5, 1.42), 24, Color("d1e985"))
	# Low tunnel across a real movement route: 1.25 m head clearance, 5.5 m length.
	box(Vector3(-12, 1.4, 26), Vector3(6, 0.3, 5.5), steel)
	for x in [-15, -9]:
		box(Vector3(x, 0.625, 26), Vector3(0.2, 1.25, 5.5), steel, true, true)
	# Exclude this player-only shortcut from standing enemy navigation.
	blockers.append(AABB(Vector3(-15, 0, 23.25), Vector3(6, 1.55, 5.5)))
	label_3d("SLIDE / 1.25m", Vector3(-12, 2.1, 29.0), 42, Color("d1e985"))
	label_3d("LEDGE ROUTE", Vector3(15, 2.8, 30), 48, Color("d1e985"))
	label_3d("RAMP / 02", Vector3(-26, 2.0, 31), 46, Color("d1e985"))
	label_3d("RAMP / 02", Vector3(26, 2.0, 31), 46, Color("d1e985"))
	# Clear practice approaches for the new traversal actions.
	authored_prop("safety_barrier", Vector3(-5, 0.55, 28), Vector3(3.5, 1.1, 0.65))
	cargo_cover(Vector3(5, 0.825, 21), Vector3(3.0, 1.65, 2.5), 2)
	label_3d("SPACE / VAULT", Vector3(-5, 1.9, 28.4), 35, Color("d1e985"))
	label_3d("SPACE / MANTLE", Vector3(5, 2.5, 22.3), 35, Color("d1e985"))
	for side in [-1, 1]:
		for z in [-28, -8, 16]:
			authored_prop("industrial_drum", Vector3(side * 45, 0.7, z), Vector3(1.2, 1.4, 0.75))
		for z in [-30, -32]:
			authored_prop("gas_cylinder", Vector3(side * 35, 9.25, z), Vector3(0.45, 1.7, 0.30))
	# Open run-up areas, rather than extra obstacles filling the expanded floor.
	for x in [-42, -28, -14, 0, 14, 28, 42]:
		box(Vector3(x, 17, 0), Vector3(0.25, 0.35, 80), dark, false)
		box(Vector3(x, 16.75, -2), Vector3(0.12, 0.10, 60), acid, false)
	label_3d("ZERO / LINE", Vector3(0, 14, -39.4), 200)
	label_3d("PHASE 02 / TRAVERSAL EVALUATION", Vector3(0, 4, 39.4), 90, Color("d1e985"), PI)
	for i in spawn_points.size():
		var p := spawn_points[i]
		box(p + Vector3(0, -0.075, 0), Vector3(3, 0.025, 3), amber, false)
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
	settings.fog_density = 0.003
	environment.environment = settings
	add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-65, -28, 0)
	key.light_color = Color("dbe6c8")
	key.light_energy = 1.1
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 115
	add_child(key)
	for p in [Vector3(-27, 10, 7), Vector3(27, 10, 7), Vector3(0, 13, -28), Vector3(0, 8, 22)]:
		var light := OmniLight3D.new()
		light.position = p
		light.light_color = Color("bfdfb3")
		light.light_energy = 1.1
		light.omni_range = 24
		add_child(light)
	_build_navigation()

func authored_prop(model_name: String, center: Vector3, size: Vector3) -> Node3D:
	var body := box(center, size, dark, true, true)
	body.get_child(0).visible = false
	art.add_model(body, model_name, Vector3(0, -size.y / 2, 0), size)
	return body

func cargo_cover(center: Vector3, size: Vector3, rows: int = 1) -> Node3D:
	var body := box(center, size, dark, true, true)
	body.get_child(0).visible = false
	for row in rows:
		for side in [-1, 1]:
			var dimensions := Vector3(size.x / 2, size.y / rows, size.z)
			var foot := Vector3(side * size.x / 4, -size.y / 2 + row * dimensions.y, 0)
			art.add_model(body, "cargo_case_a" if side < 0 else "cargo_case_b", foot, dimensions)
	return body

func platform(rect: Rect2, height: float, ai_accessible: bool = true) -> void:
	box(Vector3(rect.get_center().x, height - 0.2, rect.get_center().y), Vector3(rect.size.x, 0.4, rect.size.y), dark)
	surfaces.append({"rect": rect, "low": height, "high": height, "ai": ai_accessible})
	box(Vector3(rect.get_center().x, height + 0.015, rect.end.y - 0.08), Vector3(rect.size.x, 0.02, 0.10), acid, false)

func ramp(rect: Rect2, low: float, high: float) -> void:
	# A continuous convex slab: geometry and AI samples use the same height equation.
	var vertices := PackedVector3Array()
	for y_offset in [0.0, -0.35]:
		vertices.append(Vector3(rect.position.x, high + y_offset, rect.position.y))
		vertices.append(Vector3(rect.end.x, high + y_offset, rect.position.y))
		vertices.append(Vector3(rect.end.x, low + y_offset, rect.end.y))
		vertices.append(Vector3(rect.position.x, low + y_offset, rect.end.y))
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var shape := ConvexPolygonShape3D.new()
	shape.points = vertices
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	var instance := MeshInstance3D.new()
	var mesh_builder := SurfaceTool.new()
	mesh_builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0, 1, 2, 0, 2, 3, 7, 6, 5, 7, 5, 4, 0, 4, 5, 0, 5, 1, 1, 5, 6, 1, 6, 2, 2, 6, 7, 2, 7, 3, 3, 7, 4, 3, 4, 0]:
		mesh_builder.add_vertex(vertices[index])
	mesh_builder.generate_normals()
	instance.mesh = mesh_builder.commit()
	var ramp_material := concrete.duplicate() as StandardMaterial3D
	ramp_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = ramp_material
	body.add_child(instance)
	surfaces.append({"rect": rect, "low": low, "high": high})
	# Flush lane markers follow the slope instead of creating stair-sized lips.
	for x in [rect.position.x + 0.15, rect.end.x - 0.15]:
		var length := Vector2(rect.size.y, high - low).length()
		var stripe := box(Vector3(x, (low + high) / 2 + 0.025, rect.get_center().y), Vector3(0.10, 0.025, length), acid, false)
		stripe.rotation.x = atan2(high - low, rect.size.y)

func surface_height(surface: Dictionary, z: float) -> float:
	return lerpf(surface.high, surface.low, clampf((z - surface.rect.position.y) / surface.rect.size.y, 0, 1))

func walkable(point: Vector3) -> bool:
	var footprint := Vector2(point.x, point.z)
	for blocker in blockers:
		var horizontal := Rect2(blocker.position.x - 0.48, blocker.position.z - 0.48, blocker.size.x + 0.96, blocker.size.z + 0.96)
		if horizontal.has_point(footprint) and point.y < blocker.end.y - 0.02 and point.y + 1.85 > blocker.position.y:
			return false
	for surface in surfaces:
		if surface.rect.has_point(footprint):
			var ceiling := surface_height(surface, point.z)
			if ceiling > point.y + 0.08 and ceiling - 0.4 < point.y + 1.85:
				return false
	return true

func _build_navigation() -> void:
	navigation.clear()
	cells.clear()
	var id: int = 0
	for surface in surfaces:
		if not surface.get("ai", true):
			continue
		var bounds: Rect2 = surface.rect
		for x in range(ceili(bounds.position.x), floori(bounds.end.x)):
			for z in range(ceili(bounds.position.y), floori(bounds.end.y)):
				var point := Vector3(x + 0.5, surface_height(surface, z + 0.5), z + 0.5)
				if not walkable(point):
					continue
				var cell := Vector2i(x, z)
				if not cells.has(cell):
					cells[cell] = []
				var duplicate := false
				for existing in cells[cell]:
					if absf(navigation.get_point_position(existing).y - point.y) < 0.08:
						duplicate = true
				if duplicate:
					continue
				navigation.add_point(id, point)
				cells[cell].append(id)
				id += 1
	# Cardinal edges keep capsule clearance conservative at cover corners.
	for cell in cells:
		for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + offset
			if not cells.has(neighbor):
				continue
			for a in cells[cell]:
				for b in cells[neighbor]:
					if absf(navigation.get_point_position(a).y - navigation.get_point_position(b).y) <= 0.35:
						navigation.connect_points(a, b)

func nearest_walkable(pos: Vector3) -> Vector3:
	var id := navigation.get_closest_point(pos)
	return navigation.get_point_position(id) if id >= 0 else PLAYER_START

func path_to(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start := navigation.get_closest_point(from)
	var end := navigation.get_closest_point(to)
	if start < 0 or end < 0:
		return PackedVector3Array()
	return navigation.get_point_path(start, end)
