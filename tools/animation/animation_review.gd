extends Node3D
const Controller=preload("res://scripts/animation/character_animation.gd")
var controller: Controller
var skeleton: Skeleton3D
var camera: Camera3D
var speed: float=0.0
var paused: bool=false
var focus: bool=false
var clock: float=0.0
var status: Label
var selected: String="Locomotion"
var gear: Array[MeshInstance3D]=[]
var model_root: Node3D
func _ready() -> void:
 var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(.11,.13,.16);environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_energy=.65;add_child(environment)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-25,0);light.light_energy=1.3;add_child(light)
 var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,130,0);fill.light_energy=.65;add_child(fill)
 camera=Camera3D.new();camera.position=Vector3(2.0,1.3,3.6);camera.fov=40;add_child(camera);camera.look_at(Vector3(0,.95,0));camera.current=true
 model_root=(load("res://models/body.glb") as PackedScene).instantiate() as Node3D;add_child(model_root)
 skeleton=model_root.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
 for file: String in ["fatigues","carrier"]:
  var donor: Node3D=(load("res://models/"+file+".glb") as PackedScene).instantiate() as Node3D;add_child(donor)
  var material:=ORMMaterial3D.new();material.albedo_texture=load("res://models/"+file+"_albedo.png");material.orm_texture=load("res://models/"+file+"_orm.png");material.normal_enabled=true;material.normal_texture=load("res://models/"+file+"_normal.png");material.ao_enabled=true
  var rig: Skeleton3D=donor.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
  assert(rig.get_bone_count()==skeleton.get_bone_count())
  for i: int in skeleton.get_bone_count():
   assert(rig.get_bone_name(i)==skeleton.get_bone_name(i));assert(rig.get_bone_rest(i).is_equal_approx(skeleton.get_bone_rest(i)),"Retargeted gear rest mismatch")
  for node: Node in donor.find_children("*","MeshInstance3D",true,false):
   var mesh: MeshInstance3D=node as MeshInstance3D;mesh.reparent(model_root,true);mesh.skeleton=mesh.get_path_to(skeleton);mesh.material_override=material;gear.append(mesh)
  donor.free()
 var floor_mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(6,6);floor_mesh.mesh=plane
 var floor_material:=StandardMaterial3D.new();floor_material.albedo_color=Color(.20,.21,.22);floor_material.roughness=1;floor_mesh.material_override=floor_material;add_child(floor_mesh)
 controller=Controller.new();add_child(controller)
 controller.configure(skeleton,load("res://data/animation/actorcore_library.res") as AnimationLibrary,load("res://data/animation/animation_profile.tres"))
 var canvas:=CanvasLayer.new();add_child(canvas);var box:=VBoxContainer.new();box.position=Vector2(10,10);canvas.add_child(box)
 status=Label.new();box.add_child(status)
 for titles: Array in [["Hold","Run","Fire layer","Reload layer","Pause","Focus","Rotate","Gear"],["run_start","run_stop","fire","reload_cover","turn_left","turn_right","side_shoot"]]:
  var row:=HBoxContainer.new();box.add_child(row)
  for title: String in titles:
   var button:=Button.new();button.text=title;row.add_child(button);button.pressed.connect(func() -> void:select(title))
func select(title: String) -> void:
 match title:
  "Hold":controller.use_locomotion();speed=0;selected="Static extracted hold"
  "Run":controller.use_locomotion();speed=5;selected="Authored run loop"
  "Fire layer":controller.on_attack();selected="Upper-body fire layer"
  "Reload layer":controller.on_reload();selected="Upper-body reload layer"
  "Pause":paused=not paused
  "Focus":focus=not focus
  "Rotate":model_root.rotation.y+=PI*.5
  "Gear":
   for mesh: MeshInstance3D in gear:mesh.visible=not mesh.visible
  _:controller.preview_clip(StringName(title));selected=title
func _process(delta: float) -> void:
 var world_delta: float=0.0 if paused else delta*(.2 if focus else 1.0)
 clock+=world_delta;controller.advance(world_delta,speed)
 status.text="ANIMATION INTEGRATION REVIEW | "+selected+"\n72-bone human + skinned clothing | world time %.2f | paused %s | Focus %s\nUnapproved: foot contact, weapon contact, correctives, full clip coverage" % [clock,str(paused),str(focus)]
