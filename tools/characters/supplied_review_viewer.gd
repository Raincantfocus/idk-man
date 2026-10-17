extends Node3D
## Standalone candidate inspector. No gameplay controller or animation generator.
@export var candidates: Array[ZLCharacterVariant]=[]
var assembly: ZLCharacterAssembly
var camera: Camera3D
var label: Label
var index: int=0
var distance_m: float=3.3
var side: bool=false
func _ready() -> void:
 assert(not candidates.is_empty(),"Assign private candidate Resources")
 get_tree().root.size=Vector2i(1200,900)
 var env:=WorldEnvironment.new();env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.12,.14,.17)
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.6;add_child(env)
 var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-30,-30,0);key.light_energy=1.6;add_child(key)
 camera=Camera3D.new();add_child(camera);camera.current=true
 assembly=ZLCharacterAssembly.new();add_child(assembly)
 var layer:=CanvasLayer.new();add_child(layer)
 label=Label.new();label.position=Vector2(20,20);layer.add_child(label)
 var controls:=HBoxContainer.new();controls.position=Vector2(20,105);layer.add_child(controls)
 var next:=Button.new();next.text="Next shape";controls.add_child(next);next.pressed.connect(next_shape)
 var angle:=Button.new();angle.text="Front / side";controls.add_child(angle);angle.pressed.connect(change_angle)
 var zoom:=Button.new();zoom.text="Close / gameplay 20 m";controls.add_child(zoom);zoom.pressed.connect(change_distance)
 show_candidate()
func next_shape() -> void:
 index=(index+1)%candidates.size();show_candidate()
func change_angle() -> void:
 side=not side;update_camera()
func change_distance() -> void:
 distance_m=20.0 if distance_m<10 else 3.3;update_camera()
func show_candidate() -> void:
 assert(assembly.configure(candidates[index],false),str(assembly.setup_errors))
 update_camera()
func update_camera() -> void:
 camera.position=Vector3(distance_m,1,0) if side else Vector3(0,1,distance_m)
 camera.look_at(Vector3(0,.95,0))
 camera.fov=86 if distance_m>=20 else 40
 assembly.update_distance(distance_m)
 label.text="PHASE 1 ART CANDIDATE — NOT PRODUCTION APPROVED\n%s / LOD %d / %0.1f m\nOne outfit in five shapes. Missing role kits, correctives, wound seams and final appearance library."%[candidates[index].body_shape,assembly.visible_lod,distance_m]
