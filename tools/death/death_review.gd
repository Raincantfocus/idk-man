extends Node3D
const Actor=preload("res://scripts/death/death_actor.gd")
var settings: Dictionary
var actor: Actor
var world: Node3D
var camera: Camera3D
var label: Label
var scenario: String="open"
var tag: String="shotgun"
var direction: String="front"
var pool: RefCounted
var begin_pending: int=0
var max_depth: float=0.0
var latest_depth: Dictionary={}
func _ready() -> void:
 settings=JSON.parse_string(FileAccess.get_file_as_string("res://data/death/settings.json"))
 var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(.12,.15,.19);environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_energy=.8;add_child(environment)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-30,0);light.light_energy=1.6;add_child(light)
 camera=Camera3D.new();camera.position=Vector3(3,2.3,4.8);camera.fov=48;add_child(camera);camera.look_at(Vector3(0,.9,0));camera.current=true
 var canvas:=CanvasLayer.new();add_child(canvas);var controls:=VBoxContainer.new();controls.position=Vector2(10,10);canvas.process_mode=Node.PROCESS_MODE_ALWAYS;canvas.add_child(controls);label=Label.new();controls.add_child(label)
 for titles: Array in [["open","wall_touch","wall_20cm","crate","corridor","ledge","stairs"],["rifle","shotgun","high_caliber","front","back","left","right","Restart","Pause","Focus"]]:
  var row:=HBoxContainer.new();controls.add_child(row)
  for title: String in titles:
   var button:=Button.new();button.text=title;row.add_child(button);button.pressed.connect(func()->void:select(title))
 restart()
func select(title: String) -> void:
 if title=="Pause":get_tree().paused=not get_tree().paused;return
 if title=="Focus":Engine.time_scale=0.2 if Engine.time_scale==1.0 else 1.0;return
 if title in ["rifle","shotgun","high_caliber"]:tag=title
 elif title in ["front","back","left","right"]:direction=title
 elif title!="Restart":scenario=title
 restart()
func add_box(position: Vector3,size: Vector3,color: Color=Color(.35,.38,.42)) -> void:
 var body:=StaticBody3D.new();body.collision_layer=1;world.add_child(body);body.position=position
 var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;collider.shape=shape;body.add_child(collider)
 var mesh:=MeshInstance3D.new();var visual:=BoxMesh.new();visual.size=size;mesh.mesh=visual;var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=1;mesh.material_override=material;body.add_child(mesh)
func restart() -> void:
 if world!=null:world.free()
 world=Node3D.new();add_child(world);pool=preload("res://scripts/death/ragdoll_budget.gd").new();pool.configure(settings);max_depth=0
 if scenario=="ledge":add_box(Vector3(0,-.25,-2.4),Vector3(6,.5,5))
 else:add_box(Vector3(0,-.25,0),Vector3(20,.5,20))
 var position:=Vector3.ZERO
 match scenario:
  "wall_touch":add_box(Vector3(0,1,-.37),Vector3(5,2,.3))
  "wall_20cm":add_box(Vector3(0,1,-.57),Vector3(5,2,.3))
  "crate":add_box(Vector3(.5,.45,0),Vector3(.5,.9,.7),Color(.45,.30,.18))
  "corridor":add_box(Vector3(-.55,1,0),Vector3(.3,2,6));add_box(Vector3(.55,1,0),Vector3(.3,2,6))
  "stairs":
   position.y=.3
   for i: int in 3:add_box(Vector3(0,.15+float(i)*.15,float(i)),Vector3(5,.3+float(i)*.3,1))
 actor=Actor.new();world.add_child(actor);actor.position=position;actor.setup(settings,pool);actor.budget_camera_position=camera.global_position;begin_pending=3
func _physics_process(_delta: float) -> void:
 if actor==null:return
 if begin_pending>0:
  begin_pending-=1
  if begin_pending==0:
   var directions: Dictionary={"front":Vector3(0,0,-1),"back":Vector3(0,0,1),"left":Vector3(1,0,0),"right":Vector3(-1,0,0)}
   actor.begin_death(directions[direction],PackedStringArray([tag]))
 var points: Dictionary=actor.points();latest_depth={}
 for name: String in points:
  var depth: float=actor.query.penetration(get_world_3d().direct_space_state,name,points[name],actor.excluded).length();latest_depth[name]=depth;max_depth=maxf(max_depth,depth)
 label.text="DEATH HANDOFF REVIEW — UNAPPROVED\n%s / %s / %s | clip: %s | handoff: %s\nPeak proxy penetration %.1f mm | joint error %.1f mm | one death %d / handoff %d\nFlying animations: shotgun or explicit high_caliber only. Hardware cost unverified." % [scenario,direction,tag,String(actor.selected.id) if actor.selected!=null else "none",actor.reason,max_depth*1000,actor.joint_error()*1000,actor.lethal_events_received,actor.handoff_count]
