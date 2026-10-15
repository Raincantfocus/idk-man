extends Node3D
const BOUNDS := Rect2(-30, -15, 60, 30)
const PLAYER_START := Vector3(-27, 4.55, 0)
const MID_HEIGHT := 4.5
const HIGH_HEIGHT := 4.5
const PRACTICE_ROUTES := [
 {"name":"OFFICE FALLBACK", "point":PLAYER_START,"yaw":-PI/2},
 {"name":"CENTRAL SPRINT", "point":Vector3(0,.05,-8),"yaw":PI},
 {"name":"NORTH DESCENT", "point":Vector3(-17,4.55,13.5),"yaw":0.0},
 {"name":"SOUTH DESCENT", "point":Vector3(21,4.55,-13.5),"yaw":PI},
 {"name":"WALLRUN", "point":Vector3(-10,.05,9),"yaw":-PI/2},
 {"name":"MANTLE CHAIN", "point":Vector3(7,.05,5.5),"yaw":0.0},
 {"name":"LOADING DOCK", "point":Vector3(25,.65,-4),"yaw":PI/2},
 {"name":"NORTH CACHE", "point":Vector3(0,4.55,13.5),"yaw":0.0},
 {"name":"ZIPLINE", "point":Vector3(-12.8,4.55,13.5),"yaw":PI/2}]
var art = preload("res://scripts/industrial_art.gd").new()
var navigation := AStar3D.new()
var cells: Dictionary = {}
var blockers: Array[AABB] = []
var surfaces: Array[Dictionary] = []
var spawn_points: Array[Vector3] = []
var lab_stations: Array[Vector3] = [Vector3(0,.05,5),Vector3(-28,4.55,6),Vector3(18,4.55,14)]
var concrete: StandardMaterial3D
var dark: StandardMaterial3D
var steel: StandardMaterial3D
var acid: StandardMaterial3D
var amber: StandardMaterial3D
var objects: Dictionary = {}
var definitions: Dictionary
var spawns: Array = []
var lights: Array[OmniLight3D] = []
var map_wave := 0
var material_cache: Dictionary = {}
var event_nodes: Array[Node] = []
var ambient_environment: Environment
var daylight: DirectionalLight3D
var flank_requests := 0
var game
var clock := 0.0
var hazard_tick := 0.0
var camp_time := 0.0
var camp_anchor := Vector3.ZERO
var station_use: Dictionary = {}
var zip_time := 0.0
var zip_from := Vector3.ZERO

func material(color: Color, metallic: float = 0.0, emission: float = 0.0) -> StandardMaterial3D:
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.metallic = metallic
 mat.roughness = .8
 if emission > 0:
  mat.emission_enabled = true
  mat.emission = color
  mat.emission_energy_multiplier = emission
 return mat

func box(pos: Vector3, size: Vector3, mat: Material, solid: bool = true, nav_block: bool = false) -> Node3D:
 var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
 add_child(root)
 root.position = pos
 root.set_meta("surface_tag", "CLIMB_MANTLE")
 var mesh := MeshInstance3D.new()
 var shape := BoxMesh.new()
 shape.size = size
 mesh.mesh = shape
 mesh.material_override = mat
 root.add_child(mesh)
 if solid:
  root.collision_layer = 1
  var collider := CollisionShape3D.new()
  var collision := BoxShape3D.new()
  collision.size = size
  collider.shape = collision
  root.add_child(collider)
 if nav_block: blockers.append(AABB(pos-size/2,size))
 return root

func label_3d(text: String, pos: Vector3, size: int = 60, color: Color = Color.WHITE, rotation_y: float = 0) -> Label3D:
 var label := Label3D.new()
 label.text = text
 label.font_size = size
 label.pixel_size = .009
 label.position = pos
 label.rotation.y = rotation_y
 label.modulate = color
 label.outline_size = 0
 add_child(label)
 return label

func palette(stem: String) -> Material:
 if material_cache.has(stem): return material_cache[stem]
 if stem == "fence":
  var shader := Shader.new()
  shader.code = "shader_type spatial; render_mode cull_disabled; void fragment(){vec2 p=fract(UV*vec2(30.0,20.0)); if(abs(p.x-p.y)>.08 && abs(p.x+p.y-1.0)>.08) discard; ALBEDO=vec3(.24,.27,.28); METALLIC=.6; ROUGHNESS=.7;}"
  var fence := ShaderMaterial.new()
  fence.shader = shader
  material_cache[stem] = fence
  return fence
 var colors := {"red":Color("794135"),"blue":Color("355b70"),"olive":Color("535d3e"),"yellow":Color("b79638"),"oil":Color("202725"),"amber":Color("f0a647"),"white":Color("c7e1e8"),"glass":Color("34494e"),"hazard":Color("d0a72b")}
 var mat: StandardMaterial3D
 if stem in ["floor","concrete","steel"]:
  mat = preload("res://scripts/surface_library.gd").make("steel" if stem=="steel" else "concrete",Color.WHITE,.7)
 elif stem in ["red","blue","olive","yellow"]:
  mat = art.pbr("tile_painted_gun_metal",1.0).duplicate()
  mat.albedo_color = colors[stem].lightened(.15)
 else: mat = material(colors.get(stem, Color.WHITE),.25,1.5 if stem in ["white","amber"] else 0)
 if stem == "glass":
  mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  mat.albedo_color.a = .18
  mat.roughness = .15
 material_cache[stem] = mat
 return mat

func build() -> void:
 process_mode = Node.PROCESS_MODE_PAUSABLE
 art.setup()
 definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/warehouse.json"))
 concrete = palette("concrete")
 dark = palette("steel")
 steel = dark
 acid = palette("yellow")
 amber = palette("amber")
 for d in definitions.objects:
  var p := Vector3(d.position[0],d.position[1],d.position[2])
  var size := Vector3(d.size[0],d.size[1],d.size[2])
  if d.role == "ramp":
   var before := get_child_count()
   ramp(Rect2(d.rect[0],d.rect[1],d.rect[2],d.rect[3]),d.low,d.high)
   var node := get_child(before)
   node.set_meta("surface_tag",d.tag)
   node.name = d.name
   objects[d.name] = node
   continue
  if d.role == "dock":
   objects[d.name] = make_dock(p.z)
   continue
  if d.role == "light":
   var light := OmniLight3D.new()
   light.position = p
   light.omni_range = 24
   light.light_energy = 1.3
   light.light_color = Color("c7dce5")
   add_child(light)
   lights.append(light)
   objects[d.name] = light
   continue
  var node = box(p,size,palette(d.material),d.solid,d.block)
  node.name = d.name
  node.set_meta("surface_tag",d.tag)
  node.set_meta("role",d.role)
  objects[d.name] = node
  if d.name == "zipline_cable":
   node.look_at(Vector3(-12.8,1.1,4))
  if d.role in ["fuel","crane"]:
   node.set_script(preload("res://scripts/warehouse_hazard.gd"))
   node.arena = self
   node.kind = d.role
   node.original_position = p
  if d.role == "forklift":
   node.get_child(0).visible = false
   var chassis = box(p+Vector3(0,-.45,0),Vector3(3.5,1,1.8),palette("yellow"),false)
   for side in [-1,1]:
    for end in [-1,1]:
     box(p+Vector3(end*1.2,-.55,side*.87),Vector3(.6,.85,.25),palette("oil"),false)
   box(p+Vector3(.8,.55,0),Vector3(.12,.9,1.6),steel,false)
   box(p+Vector3(.2,.95,0),Vector3(1.5,.1,1.9),palette("yellow"),false)
   for side in [-1,1]:box(p+Vector3(-1.6,-.85,side*.45),Vector3(1.5,.12,.16),steel,false)
  elif d.role == "tank":
   node.get_child(0).visible = false
   art.add_model(node,"industrial_drum",Vector3(0,-size.y/2,0),size)
  elif d.role in ["ammo","health","cache"]:
   label_3d(d.role.to_upper(),p+Vector3(0,.8,0),22)
  if d.material == "hazard":
   for i in range(int(size.x/.4)):
    var stripe = box(p+Vector3(-size.x/2+.2+i*.4,0,-size.z/2-.006),Vector3(.16,size.y,.012),palette("oil"),false)
    stripe.rotation.z = .18
  if d.name.begins_with("east_shutter"):
   for j in 16: box(p+Vector3(-.17,-1.9+j*.24,0),Vector3(.025,.035,4.9),palette("oil"),false)
 surfaces.clear()
 for s in definitions.surfaces:
  surfaces.append({"rect":Rect2(s.rect[0],s.rect[1],s.rect[2],s.rect[3]),"high":s.high,"low":s.low,"ai":s.ai,"axis":s.get("axis","z")})
 spawns = definitions.spawns
 for s in spawns:
  var p: Array = s.get("landing",s.position)
  spawn_points.append(Vector3(p[0],p[1],p[2]))
 label_3d("EAST / FREIGHT INTAKE",Vector3(29.3,5,0),48,Color("d6b670"),PI/2)
 label_3d("WEST / CONTROL",Vector3(-21.8,7,0),48,Color("84acbc"),-PI/2)
 label_3d("ZERO LINE / SHIPPING DIVISION",Vector3(0,10,14.7),90,Color("c7d7d8"),PI)
 var environment := WorldEnvironment.new()
 var settings := Environment.new()
 settings.background_mode = Environment.BG_COLOR
 settings.background_color = Color("16252d")
 settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 settings.ambient_light_color = Color("98acb7")
 settings.ambient_light_energy = .55
 settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 settings.fog_enabled = true
 settings.fog_density = .009
 settings.fog_light_color = Color("45555e")
 ambient_environment = settings
 environment.environment = settings
 add_child(environment)
 var key := DirectionalLight3D.new()
 daylight = key
 key.rotation_degrees = Vector3(-65,-30,0)
 key.light_energy = .55
 key.shadow_enabled = true
 add_child(key)
 _build_navigation()

func configure_player(p) -> void:
 p.capsule.shape.radius = .5
 p.capsule.shape.height = 1.8
 p.standing_shape.radius = .5
 p.standing_shape.height = 1.8
 p.capsule.position.y = .9
 p.jump_speed = sqrt(2*14.7*1.2)
 p.rotation.y = -PI/2

func reset_map() -> void:
 map_wave = 0
 clock = 0
 station_use.clear()
 camp_time = 0
 flank_requests = 0
 zip_time = 0
 for node in event_nodes:
  if is_instance_valid(node): node.free()
 event_nodes.clear()
 objects.erase("collapsed_shutter")
 objects.erase("pit_escape")
 ambient_environment.ambient_light_color = Color("98acb7")
 ambient_environment.ambient_light_energy = .55
 daylight.light_energy = .55
 for name in objects:
  if name.begins_with("strip_light_"): objects[name].get_child(0).material_override = palette("white")
 # Reset dynamic geometry from authored data and rebuild its navigation records.
 blockers.clear()
 surfaces.clear()
 for d in definitions.objects:
  if d.block: blockers.append(AABB(Vector3(d.position[0],d.position[1],d.position[2])-Vector3(d.size[0],d.size[1],d.size[2])/2,Vector3(d.size[0],d.size[1],d.size[2])))
  if objects.has(d.name) and d.role not in ["ramp","dock"]:
   var node = objects[d.name]
   node.position = Vector3(d.position[0],d.position[1],d.position[2])
   node.visible = true
   if node is StaticBody3D: node.collision_layer = 1
   if node.has_method("reset_hazard"): node.reset_hazard()
 for s in definitions.surfaces: surfaces.append({"rect":Rect2(s.rect[0],s.rect[1],s.rect[2],s.rect[3]),"high":s.high,"low":s.low,"ai":s.ai,"axis":s.get("axis","z")})
 for light in lights:
  light.light_color = Color("c7dce5")
  light.light_energy = 1.3
 _build_navigation()

func apply_wave(number: int) -> void:
 station_use.clear()
 if number >= 3 and map_wave < 3:
  var shutter = box(Vector3(0,1.5,9),Vector3(3,3,1),steel,true,true)
  shutter.set_meta("surface_tag","NO_GRIP")
  objects.collapsed_shutter = shutter
  event_nodes.append(shutter)
  game.notice("NORTH RUNWAY // SHUTTER COLLAPSE",3)
 if number >= 6 and map_wave < 6:
  for light in lights:
   light.light_color = Color("f04030")
   light.light_energy = .55
  ambient_environment.ambient_light_color = Color("8d3530")
  ambient_environment.ambient_light_energy = .16
  daylight.light_energy = .08
  for name in objects:
   if name.begins_with("strip_light_"): objects[name].get_child(0).material_override = palette("red")
  game.notice("POWER CUT // EMERGENCY LIGHTING",3)
 if number >= 9 and map_wave < 9:
  objects.pit_panel.position.y -= 1
  for s in surfaces:
   if s.rect == Rect2(-2,-2,4,4): s.low = -1; s.high = -1
  var before := get_child_count()
  ramp(Rect2(-2,-2,4,3),-1,0)
  objects.pit_escape = get_child(before)
  for i in range(before,get_child_count()): event_nodes.append(get_child(i))
  game.notice("CENTRAL FLOOR // PIT OPEN",3)
 map_wave = number
 _build_navigation()

func safe_spawn(point: Vector3) -> bool:
 if game.player.global_position.distance_to(point) < 12: return false
 var target := point + Vector3.UP
 var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(game.player.camera.global_position,target,1))
 return not hit.is_empty()

func choose_spawn() -> Dictionary:
 var choices: Array = []
 for i in spawns.size():
  var s: Dictionary = spawns[i]
  if game.wave < int(s.unlock): continue
  var count := 0
  for pending in game.pending:
   if pending.get("source",-1) == i: count += 1
  if count >= int(s.capacity): continue
  var p: Array = s.get("landing",s.position)
  var point := Vector3(p[0],p[1],p[2])
  if not safe_spawn(point): continue
  var used: int = game.spawn_type_counts.get(s.type,0)
  choices.append({"index":i,"score":used*100+game.player.position.distance_to(point)-(10000 if flank_requests>0 and s.type in ["sky","catwalk"] else 0),"point":point})
 if choices.is_empty(): return {}
 choices.sort_custom(func(a,b): return a.score < b.score)
 return choices[0]

func warn_spawn(index: int) -> void:
 flank_requests = maxi(0,flank_requests-1)
 var s: Dictionary = spawns[index]
 objects["spawn_beacon_"+str(index)].get_child(0).scale = Vector3.ONE * 2.5
 if s.has("door"):
  var door = objects[s.door]
  door.position.y += 5 if door.collision_layer != 0 else 0
  door.collision_layer = 0
 game.sound.play_cue("wave" if s.type=="east" else "ability")
 game.notice("INCOMING // "+s.name+" // "+str(s.warning)+"s",2.5)

func _physics_process(dt: float) -> void:
 if game == null or not game.is_playing(): return
 clock += dt
 hazard_tick -= dt
 for key in ["electric_0","electric_1"]:
  var grate = objects[key]
  var phase := fmod(clock,6.0)
  grate.get_child(0).material_override = palette("amber") if phase > 4.5 else steel
  if phase > 5.5 and hazard_tick <= 0 and game.player.position.distance_to(grate.position) < 2:
   game.player.take_damage(12,grate.position)
 if hazard_tick <= 0: hazard_tick = .5
 for d in definitions.objects:
  if d.role not in ["ammo","health","cache"] or station_use.has(d.name): continue
  var p: Vector3 = objects[d.name].position
  if game.player.position.distance_to(p) > 1.6: continue
  if d.role == "health":
   if game.player.health >= 100: continue
   game.player.health = 100
  elif d.role == "ammo":
   if game.player.reserve[0] >= 150 and game.player.reserve[1] >= 40: continue
   game.player.reserve[0] = maxi(game.player.reserve[0],150)
   game.player.reserve[1] = maxi(game.player.reserve[1],40)
  else:
   var index := maxi(0,game.wave-1)%3
   game.player.ammo[index] = int(game.balance.weapons[game.player.weapon_ids[index]].magazine)
   game.player.switch_weapon(index)
  station_use[d.name] = true
  game.sound.play_cue("pickup")
  game.notice(d.role.to_upper()+" // USED THIS WAVE",1.5)
 # A stationary office defender triggers a valid flanking reservation, never a teleport attack.
 if game.player.position.x < -22 and game.player.position.y > 4 and game.player.position.distance_to(camp_anchor) < 1:
  camp_time += dt
 else:
  camp_time = 0
  camp_anchor = game.player.position
 if camp_time > 20 and not game.practice:
  game.queue.append("rusher")
  game.queue.append("rusher")
  flank_requests = 2
  game.spawn_timer = 0
  game.relief = false
  game.notice("FLANKERS // OFFICE PRESSURE",2)
  camp_time = 0
 # Hold Space near the zipline anchor to ride down; swept movement aborts on obstacles.
 if zip_time > 0:
  zip_time = maxf(0,zip_time-dt)
  var elapsed := 1.5-zip_time
  var lip := Vector3(-12.8,4.55,11.8)
  var target := zip_from.lerp(lip,elapsed/.3) if elapsed < .3 else lip.lerp(Vector3(-12.8,.1,4),(elapsed-.3)/1.2)
  var collision = game.player.move_and_collide(target-game.player.position)
  game.player.velocity = Vector3.ZERO
  if collision: zip_time = 0
 elif game.player.position.distance_to(Vector3(-12.8,4.5,13.5)) < 1.3 and Input.is_action_pressed("jump"):
  zip_time = 1.5
  zip_from = game.player.position

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
 var ramp_material := art.pbr("tile_anti_slip", 0.7).duplicate() as StandardMaterial3D
 ramp_material.cull_mode = BaseMaterial3D.CULL_DISABLED
 instance.material_override = ramp_material
 body.add_child(instance)
 surfaces.append({"rect": rect, "low": low, "high": high})
 # Flush lane markers follow the slope instead of creating stair-sized lips.
 for x in [rect.position.x + 0.15, rect.end.x - 0.15]:
  var length := Vector2(rect.size.y, high - low).length()
  var stripe := box(Vector3(x, (low + high) / 2 + 0.025, rect.get_center().y), Vector3(0.10, 0.025, length), acid, false)
  stripe.rotation.x = atan2(high - low, rect.size.y)

func surface_height(surface: Dictionary, z: float, x: float = 0) -> float:
 if surface.get("axis","z") == "x": return lerpf(surface.low,surface.high,clampf((x-surface.rect.position.x)/surface.rect.size.x,0,1))
 return lerpf(surface.high, surface.low, clampf((z - surface.rect.position.y) / surface.rect.size.y, 0, 1))

func walkable(point: Vector3) -> bool:
 var footprint := Vector2(point.x, point.z)
 for blocker in blockers:
  var horizontal := Rect2(blocker.position.x - 0.48, blocker.position.z - 0.48, blocker.size.x + 0.96, blocker.size.z + 0.96)
  if horizontal.has_point(footprint) and point.y < blocker.end.y - 0.02 and point.y + 1.85 > blocker.position.y:
   return false
 for surface in surfaces:
  if surface.rect.has_point(footprint):
   var ceiling := surface_height(surface, point.z, point.x)
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
  for x in range(floori(bounds.position.x), ceili(bounds.end.x)):
   for z in range(floori(bounds.position.y), ceili(bounds.end.y)):
    if not bounds.has_point(Vector2(x+.5,z+.5)): continue
    var point := Vector3(x + 0.5, surface_height(surface, z + 0.5, x + 0.5), z + 0.5)
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
     if absf(navigation.get_point_position(a).y - navigation.get_point_position(b).y) <= 0.40:
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

func make_dock(z: float) -> StaticBody3D:
 var points := PackedVector3Array([Vector3(22,0,z-2),Vector3(26,.56,z-2),Vector3(26,.56,z+2),Vector3(22,0,z+2),Vector3(22,-.35,z-2),Vector3(26,.21,z-2),Vector3(26,.21,z+2),Vector3(22,-.35,z+2)])
 var body := StaticBody3D.new()
 body.collision_layer = 1
 body.set_meta("surface_tag","SLIDE_OK")
 add_child(body)
 var collider := CollisionShape3D.new()
 var shape := ConvexPolygonShape3D.new()
 shape.points = points
 collider.shape = shape
 body.add_child(collider)
 var builder := SurfaceTool.new()
 builder.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in [0,2,1,0,3,2,4,5,6,4,6,7,0,1,5,0,5,4,1,2,6,1,6,5,2,3,7,2,7,6,3,0,4,3,4,7]: builder.add_vertex(points[i])
 builder.generate_normals()
 var mesh := MeshInstance3D.new()
 mesh.mesh = builder.commit()
 mesh.material_override = palette("floor")
 body.add_child(mesh)
 return body
