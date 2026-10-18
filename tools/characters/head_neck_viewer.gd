extends Node3D
const Region = preload("res://head_neck_review.gd")
var assembly: Region
var camera: Camera3D
var state_index: int=0
var view_index: int=0
var pose_index: int=0
var variant_index: int=0
var status: Label
var states: Array[StringName]=[&"intact",&"damaged",&"fractured_closed",&"fractured_open",&"detached"]
func _ready() -> void:
 var environment:=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(.12,.14,.17)
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_energy=.65;add_child(environment)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-30,0);light.light_energy=2;add_child(light)
 var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(10,140,0);fill.light_energy=.7;add_child(fill)
 camera=Camera3D.new();camera.fov=50;add_child(camera);camera.current=true
 assembly=Region.new();add_child(assembly)
 assert(assembly.configure("res://manifest.json"),str(assembly.errors));assembly.camera=camera
 var layer:=CanvasLayer.new();add_child(layer)
 var column:=VBoxContainer.new();column.position=Vector2(12,12);layer.add_child(column)
 status=Label.new();column.add_child(status)
 var row:=HBoxContainer.new();column.add_child(row)
 for label: String in ["Next state","Next view","Next pose","Next torn variant"]:
  var button:=Button.new();button.text=label;row.add_child(button)
  match label:
   "Next state":button.pressed.connect(func() -> void: state_index=(state_index+1)%states.size();update_view())
   "Next view":button.pressed.connect(func() -> void: view_index=(view_index+1)%3;update_view())
   "Next pose":button.pressed.connect(func() -> void: pose_index=(pose_index+1)%(assembly.manifest.correctives.size()+1);update_view())
   "Next torn variant":button.pressed.connect(func() -> void: variant_index=(variant_index+1)%3;update_view())
 update_view()
func update_view() -> void:
 assert(assembly.set_state(states[state_index]),str(assembly.errors))
 assembly.set_variant(variant_index);assembly.skeleton.reset_bone_poses()
 var pose_name: String="rest"
 if pose_index>0:
  var pose: Dictionary=assembly.manifest.correctives[pose_index-1];pose_name=str(pose.shape)
  var a: Array=pose.axis
  assembly.skeleton.set_bone_pose_rotation(assembly.skeleton.find_bone(str(pose.bone)),Quaternion(Vector3(float(a[0]),float(a[1]),float(a[2])),deg_to_rad(float(pose.angle_degrees))))
 assembly.update_correctives()
 camera.position=[Vector3(0,1.73,.84),Vector3(.84,1.73,.08),Vector3(0,1.73,-.76)][view_index]
 camera.look_at(Vector3(0,1.71,.06))
 status.text="HEAD / NECK — UNAPPROVED REGION REVIEW\nState: %s | Pose: %s | Torn variant: %d\nOpen/detached positions are exploded inspection offsets. No gameplay integration." % [String(states[state_index]),pose_name,variant_index]
