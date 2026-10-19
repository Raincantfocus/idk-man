extends Node3D
const Importer=preload("res://scripts/trauma/neck_cap_importer.gd")
var importer:=Importer.new()
var variant: int=0
var lod: int=0
var distance_index: int=0
var distances: Array[float]=[.5,2.0,8.0]
var arena: bool=false
var orthographic: bool=false
var cap: Node3D
var camera: Camera3D
var key: DirectionalLight3D
var fill: DirectionalLight3D
var environment: Environment
var status: Label
func _ready() -> void:
 assert(importer.configure("res://manifest.json")==OK)
 var world:=WorldEnvironment.new();environment=Environment.new();world.environment=environment
 environment.background_mode=Environment.BG_COLOR;environment.background_color=Color(.08,.09,.10)
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=.5;add_child(world)
 key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-55,-30,0);add_child(key)
 fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(25,140,0);add_child(fill)
 camera=Camera3D.new();camera.near=.005;camera.fov=50;camera.current=true;add_child(camera)
 var canvas:=CanvasLayer.new();add_child(canvas);var box:=VBoxContainer.new();box.position=Vector2(12,12);canvas.add_child(box)
 status=Label.new();box.add_child(status);var row:=HBoxContainer.new();box.add_child(row)
 for title: String in ["Variant","LOD","Distance","Light","Side"]:
  var button:=Button.new();button.text=title;row.add_child(button)
  match title:
   "Variant":button.pressed.connect(func() -> void:variant=(variant+1)%importer.manifest.variants.size();refresh())
   "LOD":button.pressed.connect(func() -> void:lod=(lod+1)%3;refresh())
   "Distance":button.pressed.connect(func() -> void:distance_index=(distance_index+1)%3;refresh())
   "Light":button.pressed.connect(func() -> void:arena=not arena;refresh())
   "Side":button.pressed.connect(func() -> void:orthographic=not orthographic;refresh())
 refresh()
func refresh() -> void:
 if cap!=null:cap.free()
 cap=importer.instantiate_cap(variant,lod);assert(cap!=null);add_child(cap)
 key.light_color=Color(.55,.72,1) if arena else Color.WHITE;key.light_energy=1.1
 fill.light_color=Color(1,.48,.18) if arena else Color(.85,.9,1);fill.light_energy=.6
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL if orthographic else Camera3D.PROJECTION_PERSPECTIVE
 camera.size=.45;camera.position=Vector3(0,.035,.5) if orthographic else Vector3(0,.85,.52).normalized()*distances[distance_index];camera.look_at(Vector3.ZERO)
 status.text="BODY CUT REVIEW | %s | LOD%d\n%s | %s\nUnapproved rest-pose cap; body/gear joining pending" % [importer.manifest.variants[variant].id,lod,"Orthographic side" if orthographic else str(distances[distance_index])+" m","arena-style light" if arena else "neutral light"]
