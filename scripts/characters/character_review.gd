extends Node3D
## Standalone review scene. Never instantiates game.gd or enemy.gd.
const ROLES: Array[String] = ["rusher","enforcer","shield","flusher","elite"]
const SHAPES: Array[String] = ["lean","standard","broad","stocky","slender"]
var assembly: ZLCharacterAssembly
var camera: Camera3D
var label: Label
var role_index: int = 1
var shape_index: int = 1
var lod_index: int = 0
var yaw: float = 0.0
var distance_m: float = 3.0
var dragging: bool = false
var arena_light: bool = false
var key: DirectionalLight3D

func _ready() -> void:
 var environment := WorldEnvironment.new()
 environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color(.09,.10,.12)
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE
 environment.environment.ambient_light_energy=.5
 add_child(environment)
 key=DirectionalLight3D.new()
 key.rotation_degrees=Vector3(-35,-30,0)
 key.light_energy=1.8
 add_child(key)
 var fill := DirectionalLight3D.new()
 fill.rotation_degrees=Vector3(-15,145,0)
 fill.light_energy=.6
 add_child(fill)
 camera=Camera3D.new()
 camera.fov=45
 add_child(camera)
 camera.current=true
 var canvas := CanvasLayer.new()
 add_child(canvas)
 label=Label.new()
 label.position=Vector2(20,20)
 label.add_theme_font_size_override("font_size",20)
 canvas.add_child(label)
 show_variant(role_index,shape_index)
 _position_camera()

func show_variant(role: int,shape: int) -> void:
 role_index=clampi(role,0,4)
 shape_index=clampi(shape,0,4)
 if is_instance_valid(assembly): assembly.free()
 assembly=ZLCharacterAssembly.new()
 add_child(assembly)
 var path: String="res://data/characters/variants/%s_%s.tres"%[ROLES[role_index],SHAPES[shape_index]]
 var variant: ZLCharacterVariant=load(path) as ZLCharacterVariant
 if not assembly.configure(variant,false): push_error(str(assembly.setup_errors))
 assembly.set_lod(lod_index)
 _label()

func _label() -> void:
 label.text="CHARACTER PIPELINE REVIEW — BODY ONLY\n%s / %s / LOD %d\n1–5 role | V body shape | L LOD | drag: orbit | wheel: zoom | N lighting\nMissing tactical gear, textures, correctives and wound seams.\nProduction gate: BLOCKED (%d items)"%[ROLES[role_index].to_upper(),SHAPES[shape_index],lod_index,assembly.variant.blockers().size()]

func _position_camera() -> void:
 camera.position=Vector3(sin(yaw)*distance_m,1.05,cos(yaw)*distance_m)
 camera.look_at(Vector3(0,.95,0))

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  var code: Key=event.physical_keycode
  if code>=KEY_1 and code<=KEY_5: show_variant(int(code-KEY_1),shape_index)
  elif code==KEY_V: show_variant(role_index,(shape_index+1)%5)
  elif code==KEY_L:
   lod_index=(lod_index+1)%4
   assembly.set_lod(lod_index)
   _label()
  elif code==KEY_N:
   arena_light=not arena_light
   key.light_color=Color(1,.18,.10) if arena_light else Color.WHITE
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT: dragging=event.pressed
  if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   distance_m=clampf(distance_m+(-.25 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .25),1.5,30)
   _position_camera()
 if event is InputEventMouseMotion and dragging:
  yaw-=event.relative.x*.007
  _position_camera()
