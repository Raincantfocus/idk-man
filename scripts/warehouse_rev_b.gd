extends Node3D
## PDF Rev B replacement arena, metres, origin at floor centre.
const BOUNDS := Rect2(-50, -35, 100, 70)
const PLAYER_START := Vector3(0, 0.05, 31.5)
const PRACTICE_ROUTES := [
	{"name":"BRAVO APPROACH", "point":PLAYER_START, "yaw":0.0},
	{"name":"ALPHA APPROACH", "point":Vector3(0,.05,-31.5), "yaw":PI},
	{"name":"WEST CATWALK", "point":Vector3(-48,4.05,0), "yaw":-PI/2},
	{"name":"EAST CATWALK", "point":Vector3(48,4.05,0), "yaw":PI/2},
	{"name":"CENTRAL TOWER", "point":Vector3(0,6.05,0), "yaw":0.0},
	{"name":"WEST AISLES", "point":Vector3(-32,.05,-12), "yaw":0.0},
	{"name":"EAST VEHICLES", "point":Vector3(38,.05,14), "yaw":0.0}
]
@export var auto_build: bool = false
var zip_time: float = 0.0
var spawn_points: Array[Vector3] = []
var lab_stations: Array[Vector3] = [Vector3(-32,.05,0), Vector3(32,.05,0), Vector3(0,6.05,0)]
var config: Dictionary
var nav: NavigationRegion3D
var nav_ready: bool = false
var zones: Dictionary = {}
var mats: Dictionary = {}
var shapes: Array[Dictionary] = []
var doors: Array[Vector3] = []
var ramps: Array[Dictionary] = []
var built: bool = false
var _models: Dictionary = {}

func _ready() -> void:
	if auto_build:
		build()

func material(color: Color, metallic: float = 0.0, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = .65
	if emission > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

func _mat(key: String) -> Material:
	if mats.has(key): return mats[key]
	var m: StandardMaterial3D
	match key:
		"floor": m = preload("res://scripts/ambient_materials.gd").make("tile_simple_floor",.5)
		"concrete": m = preload("res://scripts/ambient_materials.gd").make("concrete",.7)
		"steel", "paint": m = preload("res://scripts/ambient_materials.gd").make("steel",.7)
		"shell": m = preload("res://scripts/ambient_materials.gd").make("tile_painted_gun_metal",.5)
		"grating": m = preload("res://scripts/ambient_materials.gd").make("tile_anti_slip",1)
		"yellow": m = material(Color("d9ae39"),.2)
		"wood": m = material(Color("6b5132"))
		"rubber": m = material(Color("20252a"))
		"glass": m = material(Color("354b58"),.4)
		"light": m = material(Color("e8eee2"),0,1.2)
		_: m = material(Color("9da5aa"))
	if key in ["steel","paint"]: m.albedo_color = Color("59717d") if key=="paint" else Color("6c747c")
	if key=="shell": m.albedo_color = Color("87939e")
	if key in ["steel","paint","shell","grating"]: m.metallic = .35; m.roughness = .7
	if key=="floor": m.albedo_color = Color("a8afb3")
	m.uv1_world_triplanar = true
	mats[key] = m
	return m

func _zone(name_: String, parent: Node = self) -> Node3D:
	var node := Node3D.new()
	node.name = name_
	parent.add_child(node)
	zones[name_] = node
	return node

func _collider(parent: Node3D, center: Vector3, size: Vector3, layer: int = 1, navigation: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = center
	body.collision_layer = layer
	body.collision_mask = 0
	parent.add_child(body)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	if navigation: body.add_to_group("rev_b_navigation")
	return body

func _box(parent: Node3D, center: Vector3, size: Vector3, mat: String, solid: bool = true, navigation: bool = true, layer: int = 1) -> Node3D:
	var node: Node3D
	if solid:
		node = _collider(parent,center,size,layer,navigation)
	else:
		node = Node3D.new()
		node.position = center
		parent.add_child(node)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = _mat(mat)
	node.add_child(mesh)
	if solid and not navigation: node.add_to_group("rev_b_roof_review")
	return node

func _beam(parent: Node3D, a: Vector3, b: Vector3, thickness: float, mat: String = "steel") -> void:
	var beam := _box(parent,(a+b)/2,Vector3(thickness,thickness,a.distance_to(b)),mat,false)
	beam.look_at_from_position((a+b)/2,b,Vector3.UP if absf((b-a).normalized().y)<.99 else Vector3.RIGHT)

func _ramp(parent: Node3D, start: Vector3, finish: Vector3, width: float) -> void:
	ramps.append({"start":parent.global_transform*start,"finish":parent.global_transform*finish,"width":width})
	var delta := finish-start
	var along := Vector3(delta.x,0,delta.z).normalized()
	var across := Vector3(-along.z,0,along.x)*width/2
	var v := PackedVector3Array([start-across,start+across,finish+across,finish-across,start-across-Vector3.UP*.18,start+across-Vector3.UP*.18,finish+across-Vector3.UP*.18,finish-across-Vector3.UP*.18])
	var body := StaticBody3D.new()
	body.collision_layer = 1
	parent.add_child(body)
	body.add_to_group("rev_b_navigation")
	var col := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = v
	col.shape = shape
	body.add_child(col)
	# Visual treads, continuous ramp collider to avoid movement snags.
	var steps := ceili(absf(delta.y)/.18)
	for i in range(steps):
		var t := (float(i)+.5)/steps
		var pos := start.lerp(finish,t)
		pos.y = lerpf(start.y,finish.y,float(i+1)/steps)-.045
		var length := Vector2(delta.x,delta.z).length()/steps+.015
		var tread := _box(parent,pos,Vector3(width,.09,length),"grating",false)
		tread.rotation.y = atan2(along.x,along.z)
	for sign_: float in [-1.0,1.0]:
		var side := across.normalized()*(width/2+.07)*sign_
		_beam(parent,start+side+Vector3.UP*.95,finish+side+Vector3.UP*.95,.055)
		for i in range(4):
			var base := start.lerp(finish,float(i)/3)+side
			_beam(parent,base,base+Vector3.UP, .055)

func _wall_with_gaps(parent: Node3D, axis: String, fixed: float, lo: float, hi: float, gaps: Array, height: float=3.5) -> void:
	gaps.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.center < b.center)
	var cursor := lo
	for g: Dictionary in gaps:
		var left: float = maxf(lo,g.center-g.width/2)
		var right: float = minf(hi,g.center+g.width/2)
		if left>cursor: _wall_piece(parent,axis,fixed,cursor,left,0,height)
		if float(g.get("bottom",0))>0: _wall_piece(parent,axis,fixed,left,right,0,float(g.bottom))
		if g.height<height: _wall_piece(parent,axis,fixed,left,right,g.height,height)
		cursor = maxf(cursor,right)
	if cursor<hi: _wall_piece(parent,axis,fixed,cursor,hi,0,height)

func _wall_piece(parent: Node3D, axis: String, fixed: float, lo: float, hi: float, bottom: float, top: float) -> void:
	var center := Vector3(fixed,(top+bottom)/2,(lo+hi)/2) if axis=="x" else Vector3((lo+hi)/2,(top+bottom)/2,fixed)
	var size := Vector3(.18,top-bottom,hi-lo) if axis=="x" else Vector3(hi-lo,top-bottom,.18)
	_box(parent,center,size,"concrete")

func build() -> void:
	if built: return
	built = true
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/warehouse_rev_b.json"))
	nav = NavigationRegion3D.new()
	nav.name = "Navigation"
	add_child(nav)
	var world := _zone("Warehouse_Main",nav)
	var shell := _zone("Shell",world)
	_box(shell,Vector3(0,-.2,0),Vector3(100,.4,70),"floor")
	for x in [-50.0,50.0]: _box(shell,Vector3(x,4,0),Vector3(.3,8,70),"shell")
	for z in [-35.0,35.0]: _box(shell,Vector3(0,4,z),Vector3(100,8,.3),"shell")
	# Roof strips are actual openings; no glass. Solid invisible cover blocks shots.
	var skylights := _zone("Skylights",world)
	for interval: Vector2 in [Vector2(-35,-17),Vector2(-12,12),Vector2(17,35)]:
		_box(shell,Vector3(0,8.15,(interval.x+interval.y)/2),Vector3(100,.3,interval.y-interval.x),"shell",true,false)
	for z in [-14.5,14.5]:
		_collider(skylights,Vector3(0,8.1,z),Vector3(100,.2,5),1,false)
		for x in range(-48,49,4): _box(skylights,Vector3(x,8.1,z),Vector3(.08,.12,5),"steel",false)
		for dz in [-2.5,0.0,2.5]: _box(skylights,Vector3(0,8.1,z+dz),Vector3(100,.12,.10),"steel",false)
		var area := Area3D.new()
		area.name = "NorthShaft" if z<0 else "SouthShaft"
		area.collision_layer = 0
		area.collision_mask = 4
		skylights.add_child(area)
		var trigger := CollisionShape3D.new()
		var trigger_shape := BoxShape3D.new()
		trigger_shape.size = Vector3(98,7.8,5)
		trigger.shape = trigger_shape
		trigger.position = Vector3(0,4,z)
		area.add_child(trigger)
	for z in [-30,-20,-10,10,20,30]:
		_box(shell,Vector3(0,7.4,z),Vector3(100,.15,.15),"steel",false)
		for x in range(-50,50,10):
			_beam(shell,Vector3(x,7.4,z),Vector3(x+5,7.85,z),.12)
			_beam(shell,Vector3(x+5,7.85,z),Vector3(x+10,7.4,z),.12)
	# Safety lines make lane boundaries readable without artificial corridor walls.
	for x in [-25.0,25.0]:
		for z in range(-24,25,3): _box(world,Vector3(x,.012,z),Vector3(.10,.02,1.8),"yellow",false)
	var lanes := _zone("Lanes",world)
	for lane in ["West","Mid","East","Alpha","Bravo","Killhouse"]: _zone(lane,lanes)
	var inner := _zone("Inner_Killhouse",world)
	for z in [-7.5,7.5]: _wall_with_gaps(inner,"z",z,-15,15,[{"center":0.0,"width":2.4,"height":2.6}])
	for x in [-15.0,15.0]: _wall_with_gaps(inner,"x",x,-7.5,7.5,[{"center":0.0,"width":2.4,"height":2.6}])
	for x in [-5.0,5.0]:
		var gaps: Array = []
		for door: Dictionary in config.internal_doors:
			if door.axis=="x" and door.x==x: gaps.append({"center":float(door.z),"width":float(door.width),"height":float(door.height)})
		for z in [-2.5,2.5]: gaps.append({"center":z,"width":1.5,"height":3.5,"bottom":2.7})
		_wall_with_gaps(inner,"x",x,-7.5,7.5,gaps)
	for x in [-10.0,10.0]: _wall_with_gaps(inner,"z",0,x-5,x+5,[{"center":x,"width":2.0,"height":2.4}])
	for door: Dictionary in config.internal_doors: doors.append(Vector3(door.x,.05,door.z))
	var tower := _zone("CentralTower",inner)
	_box(tower,Vector3(0,5.85,0),Vector3(6,.3,6),"grating")
	for x in [-2.85,2.85]:
		for z in [-2.85,2.85]: _box(tower,Vector3(x,3,z),Vector3(.22,6,.22),"steel")
	# Four switchback stair routes around the 6x6 deck. Each flight rises 3m.
	for i in range(4):
		var stairs := Node3D.new()
		stairs.name = "TowerStairs"+str(i)
		tower.add_child(stairs)
		stairs.rotation.y = i*PI/2
		_ramp(stairs,Vector3(-2.9,0,-5.35),Vector3(2.0,3,-5.35),1.2)
		_box(stairs,Vector3(2.5,2.85,-4.55),Vector3(1,.3,2.8),"grating")
		_ramp(stairs,Vector3(2,3,-3.75),Vector3(-1.8,6,-3.75),1.2)
		_box(stairs,Vector3(-2.4,5.85,-3.275),Vector3(1.2,.3,2.15),"grating")
		# Short windowed parapets with route gaps; exposed deck remains contestable.
		_box(stairs,Vector3(.1,6.48,-2.96),Vector3(3.6,.96,.10),"steel")
		for x in [-1.6,1.8]: _box(stairs,Vector3(x,7.05,-2.96),Vector3(.08,1.1,.08),"steel")
		_box(stairs,Vector3(.1,7.57,-2.96),Vector3(3.6,.06,.08),"steel",false)
	var top := Marker3D.new()
	top.name = "TowerTop"
	top.position = Vector3(0,6.05,0)
	tower.add_child(top)
	var catwalks := _zone("Catwalks",world)
	for x in [-48.7,48.7]:
		_box(catwalks,Vector3(x,3.87,0),Vector3(1.5,.26,40),"grating")
		for z in [-20.0,20.0]:
			_ramp(catwalks,Vector3(x,0,z+signf(z)*6.4),Vector3(x,4,z),1.5)
		for side in [-1.0,1.0]:
			var rx: float = x+side*.72
			_box(catwalks,Vector3(rx,5,0),Vector3(.05,.06,40),"steel")
			for z in range(-20,21,4): _box(catwalks,Vector3(rx,4.5,z),Vector3(.06,1,.06),"steel",false)
	for row: Dictionary in config.props: _prop(row)
	var spawns := _zone("Spawns",world)
	for row: Dictionary in config.spawns:
		var marker := Marker3D.new()
		marker.name = row.id
		marker.position = Vector3(row.position[0],row.position[1],row.position[2])
		marker.set_meta("team",row.team)
		spawns.add_child(marker)
		spawn_points.append(marker.position)
	# Additional wave approaches use the same routes, not inaccessible roof spawns.
	for p in [Vector3(-43,.05,0),Vector3(43,.05,0),Vector3(-24,.05,-19),Vector3(24,.05,19)]: spawn_points.append(p)
	_lighting(world)
	_bake_navigation()

func _prop(row: Dictionary) -> void:
	var zone: Node3D = zones[row.zone]
	var foot := Vector3(row.position[0],row.position[1],row.position[2])
	var size := Vector3(row.size[0],row.size[1],row.size[2])
	var holder := Node3D.new()
	holder.name = row.id
	holder.position = foot
	holder.rotation.y = deg_to_rad(row.yaw_degrees)
	zone.add_child(holder)
	var layer: int = 128 if row.bullet_permeable else 1
	if row.kind in ["lowwall","woodwall"]:
		_box(holder,Vector3(0,size.y/2,0),size,"wood" if row.kind=="woodwall" else "concrete",true,true,layer)
		return
	if row.kind=="fence":
		_collider(holder,Vector3(0,1,0),size,128)
		var panel := MeshInstance3D.new()
		var plane := QuadMesh.new()
		plane.size = Vector2(5,2)
		panel.mesh = plane
		panel.position.y = 1
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = load("res://assets/maps/warehouse_rev_b/chainlink.png")
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.uv1_scale = Vector3(10,4,1)
		panel.material_override = mat
		holder.add_child(panel)
		for x in [-2.5,0,2.5]: _box(holder,Vector3(x,1,0),Vector3(.07,2,.07),"steel",false)
		return
	if not _models.has(row.kind): _models[row.kind] = load("res://assets/maps/warehouse_rev_b/props/"+row.kind+".glb")
	var model: Node3D = _models[row.kind].instantiate()
	holder.add_child(model)
	var bounds := AABB()
	var first := true
	for child: Node in model.find_children("*","MeshInstance3D",true,false):
		var m := child as MeshInstance3D
		var b: AABB = (model.global_transform.affine_inverse()*m.global_transform)*m.get_aabb()
		bounds = b if first else bounds.merge(b)
		first = false
		for surface in m.mesh.get_surface_count():
			var original := m.mesh.surface_get_material(surface)
			if original != null: m.set_surface_override_material(surface,_mat(original.resource_name))
	model.scale = size/bounds.size
	model.position = -Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*model.scale
	if row.kind=="car":
		_collider(holder,Vector3(0,.50,0),Vector3(size.x,1,size.z),layer)
		_collider(holder,Vector3(0,1.2,0),Vector3(1.6,.6,1.6),layer)
	elif row.kind=="forklift":
		_collider(holder,Vector3(-.2,.55,0),Vector3(1.8,1.1,1.3),layer)
		for z in [-.45,.45]: _collider(holder,Vector3(.8,1.1,z),Vector3(.15,2.2,.15),layer)
	else: _collider(holder,Vector3(0,size.y/2,0),size,layer)

func _lighting(parent: Node3D) -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("8fa9bd")
	sky_material.sky_horizon_color = Color("c6d5dd")
	sky_material.ground_bottom_color = Color("5b6872")
	sky_material.ground_horizon_color = Color("9eafb9")
	var sky := Sky.new()
	sky.sky_material = sky_material
	settings.sky = sky
	settings.background_mode = Environment.BG_SKY
	settings.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	settings.background_color = Color("8597a6")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b9cedd")
	settings.ambient_light_energy = .8
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = settings
	parent.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-72,-18,0)
	sun.light_color = Color("fff1d3")
	sun.light_energy = .85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100
	parent.add_child(sun)
	for z in [-14.5,14.5]:
		for x in [-25.0,25.0]:
			var light := OmniLight3D.new()
			light.position = Vector3(x,6.9,z)
			light.omni_range = 32
			light.light_energy = .7
			light.light_color = Color("ffeac4")
			parent.add_child(light)

	for x in [-25.0,25.0]:
		for z in [-17.0,17.0]:
			var probe := ReflectionProbe.new()
			probe.position = Vector3(x,4,z)
			probe.size = Vector3(52,9,37)
			probe.interior = true
			probe.box_projection = true
			probe.max_distance = 65
			parent.add_child(probe)

func _bake_navigation() -> void:
	var mesh := NavigationMesh.new()
	mesh.cell_size = .20
	mesh.cell_height = .10
	mesh.agent_radius = .40
	mesh.agent_height = 1.8
	mesh.agent_max_climb = .20
	mesh.agent_max_slope = 40
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 129
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	mesh.geometry_source_group_name = "rev_b_navigation"
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map,.20)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map,.10)
	nav.navigation_mesh = mesh
	nav.set_navigation_map(get_world_3d().navigation_map)
	nav.bake_navigation_mesh(false)
	NavigationServer3D.map_force_update(get_world_3d().navigation_map)
	nav_ready = true

func nearest_walkable(pos: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map,pos) if nav_ready else PLAYER_START

func path_to(from: Vector3, to: Vector3) -> PackedVector3Array:
	return NavigationServer3D.map_get_path(get_world_3d().navigation_map,from,to,true) if nav_ready else PackedVector3Array()

func configure_player(player: CharacterBody3D) -> void:
	player.collision_mask = 131

func configure_enemy(enemy: CharacterBody3D) -> void:
	enemy.collision_mask = 129
