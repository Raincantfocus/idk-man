extends Node3D
## User-supplied coordinate-layout arena, metres, origin at floor centre.
const BOUNDS := Rect2(-80,-50,160,100)
const PLAYER_START := Vector3(0,.05,0)
const PRACTICE_ROUTES := [
 {"name":"CENTRAL HUB","point":PLAYER_START,"yaw":0.0},
 {"name":"WEST BREACH","point":Vector3(-27,.05,-9),"yaw":-PI/2},
 {"name":"EAST BREACH","point":Vector3(27,.05,9),"yaw":PI/2},
 {"name":"NORTH SNIPER","point":Vector3(-55,6.05,-44),"yaw":0.0},
 {"name":"SOUTH SNIPER","point":Vector3(55,6.05,44),"yaw":PI},
 {"name":"NORTH OVERLOOK","point":Vector3(0,5.05,-47),"yaw":0.0},
 {"name":"WEST OVERLOOK","point":Vector3(-76,5.05,5),"yaw":-PI/2},
 {"name":"SOUTH OVERLOOK","point":Vector3(0,5.05,47),"yaw":PI},
 {"name":"EAST OVERLOOK","point":Vector3(76,5.05,-5),"yaw":PI/2}
]
@export var auto_build: bool = false
var zip_time: float = 0.0
var spawn_points: Array[Vector3] = []
var lab_stations: Array[Vector3] = [Vector3(-3,.05,1), Vector3(3,.05,-1), Vector3(0,.05,3)]
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
		"fabric": m = preload("res://scripts/ambient_materials.gd").make("cloth",1)
		"wood": m = material(Color("6b5132"))
		"rubber": m = material(Color("20252a"))
		"glass": m = material(Color("354b58"),.4)
		"light": m = material(Color("e8eee2"),0,1.2)
		_: m = material(Color("9da5aa"))
	if key in ["steel","paint"]: m.albedo_color = Color("59717d") if key=="paint" else Color("6c747c")
	if key=="shell": m.albedo_color = Color("87939e")
	if key in ["steel","paint","shell","grating"]: m.metallic = .35; m.roughness = .7
	if key=="fabric": m.albedo_color = Color("586054")
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
	var deck := _box(parent,(start+finish)/2-Vector3.UP*.045,Vector3(width,.09,delta.length()),"grating",false)
	deck.look_at_from_position(deck.position,deck.position+delta,Vector3.UP)
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

func _point(p: Array, height: float = 0.0) -> Vector3:
	# Source north is +Z; Godot north is -Z. Sizes are source [length, width, height].
	return Vector3(float(p[0]),height,-float(p[1]))

func _segment(parent: Node3D, row: Dictionary) -> void:
	var a := _point(row.a)
	var b := _point(row.b)
	var h := float(row.height)
	var node := _box(parent,(a+b)/2+Vector3.UP*(float(row.get("y_base",0))+h/2),Vector3(a.distance_to(b),h,float(row.thickness)),"wood" if row.get("type","")=="wood_wall" else "concrete")
	node.name = row.id
	node.rotation.y = atan2(-(b-a).z,(b-a).x)

func build() -> void:
	if built: return
	built = true
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/hangar_layout.json"))
	nav = NavigationRegion3D.new()
	nav.name = "Navigation"
	add_child(nav)
	var world := _zone("Hangar",nav)
	var shell := _zone("Shell",world)
	_box(shell,Vector3(0,-.2,0),Vector3(160,.4,100),"floor")
	for x in [-80.2,80.2]: _box(shell,Vector3(x,7,0),Vector3(.4,14,100.8),"shell")
	for z in [-50.2,50.2]: _box(shell,Vector3(0,7,z),Vector3(160,14,.4),"shell")
	var roof := _zone("Roof",world)
	roof.add_to_group("hangar_roof")
	for interval: Vector2 in [Vector2(-50,-33),Vector2(-27,27),Vector2(33,50)]:
		_box(roof,Vector3(0,14.15,(interval.x+interval.y)/2),Vector3(160,.3,interval.y-interval.x),"shell",true,false)
	for z in [-30,30]:
		_collider(roof,Vector3(0,14.15,z),Vector3(160,.3,6),1,false)
		for x in range(-80,81,5):_box(roof,Vector3(x,14.15,z),Vector3(.12,.2,6),"steel",false)
	for x in range(-70,80,20):
		_box(roof,Vector3(x,14.3,0),Vector3(.2,.4,100),"steel",false)
	var interior := _zone("Killhouse",world)
	for row: Dictionary in config.walls: _segment(interior,row)
	for row: Dictionary in config.openings:
		var horizontal: bool = absf(float(row.center[1]))==16 or (absf(float(row.center[1]))==8 and absf(float(row.center[0]))!=14)
		var wall_height := 3.4 if row.wall_kind=="perimeter" else 3.0
		var thickness := .4 if row.wall_kind=="perimeter" else .25
		var bottom := 1.1 if row.type=="window" else 0.0
		var top: float = bottom+float(row.height)
		var width := float(row.width)
		var sz := Vector3(width,wall_height-top,thickness) if horizontal else Vector3(thickness,wall_height-top,width)
		_box(interior,_point(row.center,(top+wall_height)/2),sz,"concrete").name = row.id+"_Lintel"
		if bottom>0:
			sz.y = bottom
			var sill := _box(interior,_point(row.center,bottom/2),sz,"concrete")
			sill.name = row.id+"_Sill"
			sill.set_meta("vault_window_top",bottom)
		else: doors.append(_point(row.center,.05))
	var props := _zone("Props",world)
	for row: Dictionary in config.objects:
		if row.has("a"):
			if row.type=="chain_fence": _fence(props,row)
			else: _segment(props,row)
			continue
		var kind: String = {"jersey_barrier":"barrier","box_truck":"truck"}.get(row.type,row.type)
		var foot := _point(row.center,float(row.y_base))
		_prop({"id":row.id,"zone":"Props","position":[foot.x,foot.y,foot.z],"size":[row.size[0],row.size[2],row.size[1]],"kind":kind,"yaw_degrees":row.rot_deg,"bullet_permeable":false})
	var elevated := _zone("Platforms",world)
	for row: Dictionary in config.platforms: _platform(elevated,row)
	for row: Dictionary in config.ramps:
		_ramp(elevated,_point(row.from_ground),_point(row.to_platform_edge,row.rise),row.width)
	var markers := _zone("Spawns",world)
	for row: Dictionary in config.spawns:
		var marker := Marker3D.new()
		marker.name = row.id
		marker.position = _point(row.pos,.05)
		marker.rotation.y = -PI/2 if row.faces=="east" else PI/2
		markers.add_child(marker)
		spawn_points.append(marker.position)
	for lane: Dictionary in config.wallrun_lanes:
		var a := _point(lane.a,.012)
		var b := _point(lane.b,.012)
		for i in range(26): _box(world,a.lerp(b,float(i)/26),Vector3(1.2,.02,.07),"yellow",false)
	_lighting(world)
	_bake_navigation()

func _fence(parent: Node3D, row: Dictionary) -> void:
	var a := _point(row.a)
	var b := _point(row.b)
	var holder := Node3D.new()
	holder.name = row.id
	parent.add_child(holder)
	holder.position = (a+b)/2
	holder.rotation.y = atan2(-(b-a).z,(b-a).x)
	var length := a.distance_to(b)
	var height := float(row.height)
	_collider(holder,Vector3(0,height/2,0),Vector3(length,height,.08),128)
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(length,height)
	mesh.mesh = quad
	mesh.position.y = height/2
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/maps/warehouse_rev_b/chainlink.png")
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.uv1_scale = Vector3(length*2,height*2,1)
	mesh.material_override = mat
	holder.add_child(mesh)
	for i in range(ceili(length/2.5)+1):
		_box(holder,Vector3(-length/2+length*i/ceili(length/2.5),height/2,0),Vector3(.06,height,.06),"steel",false)

func _platform(parent: Node3D, row: Dictionary) -> void:
	var holder := _zone(row.id,parent)
	holder.position = _point(row.center,row.top_y)
	var length := float(row.size[0])
	var width := float(row.size[1])
	_box(holder,Vector3(0,-.15,0),Vector3(length,.3,width),"grating")
	# Supports and free-edge rails leave every specified ramp entrance open.
	for x in [-length/2+.18,length/2-.18]:
		for z in [-width/2+.18,width/2-.18]:
			_box(holder,Vector3(x,-row.top_y/2,z),Vector3(.18,row.top_y,.18),"steel")
	if row.kind=="sniper":
		# SP2 is the 180-degree counterpart; feature prose uses SP1 coordinates.
		holder.rotation.y = PI if row.id=="SP2" else 0.0
		_box(holder,Vector3(0,.5,4),Vector3(12,1,.12),"wood")
		_box(holder,Vector3(-5.94,.6,0),Vector3(.12,1.2,8),"wood")
		_wall_with_gaps(holder,"z",-4,-6,6,[{"center":-3.5,"width":1.2,"bottom":1.1,"height":2.3},{"center":0.0,"width":1.2,"bottom":1.1,"height":2.3},{"center":3.5,"width":1.2,"bottom":1.1,"height":2.3}],2.4)
		_box(holder,Vector3(0,1.2,.5),Vector3(.15,2.4,3),"wood")
		for x in [-3.0,3.0]:
			_prop({"id":str(row.id)+"_Couch"+str(x),"zone":row.id,"position":[x,0,-2.7],"size":[2,.85,.9],"kind":"couch","yaw_degrees":0,"bullet_permeable":false})
		# Ramp enters the right edge at local z=2.9; rail only the remaining edge.
		_box(holder,Vector3(5.94,.55,-1.2),Vector3(.08,1.1,5.6),"steel")
	else:
		var north_south: bool = length>width
		if north_south:
			for x in range(-20,21,4):
				for z in [-width/2,width/2]:_box(holder,Vector3(x,.55,z),Vector3(.06,1.1,.06),"steel",false)
			for z in [-width/2,width/2]: _box(holder,Vector3(0,1.05,z),Vector3(length,.08,.08),"steel")
			for x in [-10,10]:_box(holder,Vector3(x,1.2,0),Vector3(3,2.4,.15),"wood")
		else:
			for z in range(-12,13,4):
				for x in [-length/2,length/2]:_box(holder,Vector3(x,.55,z),Vector3(.06,1.1,.06),"steel",false)
			for x in [-length/2,length/2]:_box(holder,Vector3(x,1.05,0),Vector3(.08,.08,width),"steel")
			# End opposite the ramp is closed; ramp occupies outer 2.2m at entry end.
			var end := 1.0 if row.id=="OV_W" else -1.0
			_box(holder,Vector3(0,1.05,12*end),Vector3(6,.08,.08),"steel")
			_box(holder,Vector3(0,1.2,0),Vector3(.15,2.4,3),"wood")

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
	settings.ambient_light_energy = .65
	settings.ambient_light_sky_contribution = 0.0
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
	for z in [-30.0,0.0,30.0]:
		for x in [-55.0,0.0,55.0]:
			var light := OmniLight3D.new()
			light.position = Vector3(x,12.5,z)
			light.omni_range = 42
			light.light_energy = .7
			light.light_color = Color("ffeac4")
			parent.add_child(light)

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
