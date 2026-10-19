extends Node3D
const Importer=preload("res://scripts/trauma/neck_cap_importer.gd")
const Budget=preload("res://scripts/trauma/cosmetic_budget.gd")
const Effect=preload("res://scripts/trauma/neck_wound_effect.gd")
const HeadPool=preload("res://scripts/trauma/head_review_pool.gd")
var budget:=Budget.new()
var effect: Effect
var heads: HeadPool
var settings: Dictionary
const BloodPool=preload("res://scripts/trauma/corpse_blood_pool.gd")
var pools: BloodPool
var floor_surface: MeshInstance3D
var runoff:=ShaderMaterial.new()
var owner_serial: int=0
var importer:=Importer.new()
var camera: Camera3D
var key: DirectionalLight3D
var fill: DirectionalLight3D
var env: WorldEnvironment
var cap: Node3D
var exterior: Node3D
var gore_mode: int=2
var off_head: Node3D
var variant: int=0
var lod: int=0
var distance_index: int=0
var arena: bool=false
var orthographic: bool=false
var status: Label
var distances: Array[float]=[.5,2.0,8.0]
func _ready() -> void:
 assert(importer.configure("res://manifest.json")==OK)
 settings=JSON.parse_string(FileAccess.get_file_as_string("res://data/trauma/neck_rework.json"));budget.configure(settings)
 effect=Effect.new();add_child(effect)
 pools=BloodPool.new();add_child(pools);pools.setup(budget,load("res://pool_albedo.png"),load("res://pool_normal.png"),load("res://pool_wet_orm.png"),load("res://pool_dry_orm.png"))
 heads=HeadPool.new();add_child(heads);heads.configure(importer,budget,settings)
 var floor_body:=StaticBody3D.new();floor_body.position.y=-.12;floor_body.collision_layer=1;floor_body.collision_mask=0;add_child(floor_body)
 var floor_shape:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(10,.1,10);floor_shape.shape=shape;floor_body.add_child(floor_shape)
 floor_surface=MeshInstance3D.new();var floor_mesh:=PlaneMesh.new();floor_mesh.size=Vector2(5,5);floor_surface.mesh=floor_mesh;floor_surface.position.y=-.07
 var floor_mat:=StandardMaterial3D.new();floor_mat.albedo_color=Color(.16,.17,.18);floor_mat.roughness=.8;floor_surface.material_override=floor_mat;floor_surface.visible=false;add_child(floor_surface)
 env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;add_child(env)
 key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-45,-25,0);add_child(key)
 fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(25,145,0);add_child(fill)
 camera=Camera3D.new();camera.near=.005;camera.fov=50;add_child(camera);camera.current=true
 exterior=(load("res://supplied_stump.glb") as PackedScene).instantiate() as Node3D;add_child(exterior)
 off_head=(load("res://supplied_head.glb") as PackedScene).instantiate() as Node3D;add_child(off_head);off_head.visible=false
 runoff.shader=preload("res://scripts/trauma/wound_runoff.gdshader")
 for node: Node in exterior.find_children("*","MeshInstance3D",true,false):(node as MeshInstance3D).material_overlay=runoff
 var layer:=CanvasLayer.new();add_child(layer);var box:=VBoxContainer.new();box.position=Vector2(12,12);layer.add_child(box)
 status=Label.new();box.add_child(status);var row:=HBoxContainer.new();box.add_child(row)
 for title: String in ["Variant","Distance","Light","Side view","LOD","Pulse","Drop head","Head pop","Gore"]:
  var button:=Button.new();button.text=title;row.add_child(button)
  match title:
   "Variant":button.pressed.connect(func() -> void:variant=(variant+1)%12;refresh())
   "Distance":button.pressed.connect(func() -> void:distance_index=(distance_index+1)%3;refresh())
   "Light":button.pressed.connect(func() -> void:arena=not arena;refresh())
   "Side view":button.pressed.connect(func() -> void:orthographic=not orthographic;refresh())
   "Pulse":button.pressed.connect(func() -> void:effect.configure(cap,settings,710+variant,gore_mode,budget,owner_serial))
   "Gore":button.pressed.connect(func() -> void:gore_mode=(gore_mode+1)%3;budget.set_gore_mode(gore_mode);refresh())
   "Drop head":button.pressed.connect(drop_head)
   "Head pop":button.pressed.connect(pop_head)
   "LOD":button.pressed.connect(func() -> void:lod=(lod+1)%3;refresh())
 refresh()
func refresh() -> void:
 if effect!=null:effect.reset()
 if cap!=null:cap.free()
 cap=importer.instantiate_cap(variant,lod);assert(cap!=null);add_child(cap);cap.visible=gore_mode>0;off_head.visible=gore_mode==0
 if arena:
  env.environment.background_color=Color(.018,.025,.03);env.environment.ambient_light_color=Color(.32,.42,.48);env.environment.ambient_light_energy=.4
  key.light_color=Color(.70,.84,1);key.light_energy=1.4;fill.light_color=Color(1,.40,.15);fill.light_energy=.6
 else:
  env.environment.background_color=Color(.12,.13,.14);env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.55
  key.light_color=Color.WHITE;key.light_energy=1.5;fill.light_color=Color.WHITE;fill.light_energy=.5
 if orthographic:
  camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.26;camera.position=Vector3(.4,.015,0);camera.look_at(Vector3(0,.015,0))
 else:
  camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.position=Vector3(0,.72,.69).normalized()*distances[distance_index];camera.look_at(Vector3.ZERO)
 status.text="HEAD / NECK REWORK — REVIEW\n%s | LOD%d | %.1f m | %s\nUnapproved; isolated cosmetic geometry" % [str(importer.manifest.variants[variant].id),lod,distances[distance_index],"arena light" if arena else "neutral light"]
 status.text+=" | Gore: "+["Off","Reduced","Full"][gore_mode]
 if orthographic:status.text+="\nOrthographic span: 0.26 m (distance label does not apply)"

func _process(delta: float) -> void:
 if effect!=null:
  effect.advance(delta)
  pools.advance(delta)
  for node: Node in exterior.find_children("*","MeshInstance3D",true,false):
   var mesh: MeshInstance3D=node as MeshInstance3D
   mesh.set_instance_shader_parameter("wet_front",clampf(effect.elapsed/3.0,0,1))
   mesh.set_instance_shader_parameter("age",effect.elapsed)

func drop_head() -> void:
 owner_serial+=1;var corpse_owner: int=owner_serial;floor_surface.visible=true
 var body: RigidBody3D=heads.spawn_head(variant,owner_serial,Transform3D(Basis.IDENTITY,Vector3(.12,.18,0)),Vector3(.1,.1,0),Vector3(.1,.2,.1))
 await get_tree().create_timer(1.2).timeout
 if is_instance_valid(body) and body.visible:pool_below(body.global_position,corpse_owner)
func pop_head() -> void:
 owner_serial+=1;var corpse_owner: int=owner_serial;floor_surface.visible=true
 var pieces: Array[RigidBody3D]=heads.spawn_head_pop(owner_serial,Transform3D(Basis.IDENTITY,Vector3(.12,.18,0)),Vector3(.1,.2,0),owner_serial+40)
 await get_tree().create_timer(1.2).timeout
 if not pieces.is_empty() and is_instance_valid(pieces[0]) and pieces[0].visible:pool_below(pieces[0].global_position,corpse_owner)
func pool_below(point: Vector3, owner_id: int) -> bool:
 var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.2,point-Vector3.UP*2,1)
 var hit: Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
 if hit.is_empty():return false
 return pools.add_pool(owner_id,hit.position,hit.normal,1)
