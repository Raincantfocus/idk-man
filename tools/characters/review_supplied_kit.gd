extends SceneTree
## Native static fitting/deformation diagnostic. Never used as gameplay animation.
var world: Node3D
var camera: Camera3D
var body: Node3D
var skeleton: Skeleton3D
var label: Label
var metrics: Dictionary={"production_ready":false,"renderer":"","poses":[]}
func _initialize() -> void: call_deferred("run")
func settle() -> void:
 for i: int in 6: await process_frame
 await RenderingServer.frame_post_draw
func capture(file_name: String) -> void:
 await settle()
 assert(root.get_texture().get_image().save_png("res://"+file_name+".png")==OK)
func run() -> void:
 assert(ClassDB.class_has_method("Skeleton3D","set_bone_pose_rotation"))
 assert(ClassDB.class_has_method("Skeleton3D","reset_bone_poses"))
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 root.content_scale_size=Vector2i.ZERO
 root.size=Vector2i(1000,1200)
 world=Node3D.new();root.add_child(world)
 var env:=WorldEnvironment.new();env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.12,.14,.17)
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.65;world.add_child(env)
 var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-30,-30,0);key.light_energy=2;world.add_child(key)
 var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(10,140,0);fill.light_energy=.7;world.add_child(fill)
 camera=Camera3D.new();camera.fov=40;world.add_child(camera);camera.current=true
 var assembly:=ZLCharacterAssembly.new();world.add_child(assembly)
 assert(assembly.configure(load("res://candidates/standard.tres") as ZLCharacterVariant,false),str(assembly.setup_errors))
 body=assembly
 skeleton=assembly.skeletons[0]
 var layer:=CanvasLayer.new();world.add_child(layer);label=Label.new();label.position=Vector2(20,20);layer.add_child(label)
 label.text="PRIVATE GARMENT FIT DIAGNOSTIC\nUnapproved Makarov garments / Soup head / shared rig"
 camera.position=Vector3(0,1.1,3.3);camera.look_at(Vector3(0,.95,0))
 body.visible=false
 await settle()
 metrics["baseline_draw_calls"]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
 body.visible=true
 await settle()
 metrics["assembled_draw_calls"]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
 metrics["bones"]=skeleton.get_bone_count()
 metrics["materials"]=0;metrics["triangles"]=0
 var materials: Array[Material]=[]
 for node: Node in world.find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D
  if not mesh.is_visible_in_tree():continue
  for surface: int in mesh.mesh.get_surface_count():
   var arrays: Array=mesh.mesh.surface_get_arrays(surface)
   metrics["triangles"]+=(arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3
   var material: Material=mesh.get_active_material(surface)
   if not materials.has(material):materials.append(material)
 metrics["materials"]=materials.size()
 await capture("kit_front")
 camera.position=Vector3(3.3,1.1,0);camera.look_at(Vector3(0,.95,0))
 await capture("kit_side")
 camera.position=Vector3(0,1.1,-3.3);camera.look_at(Vector3(0,.95,0))
 await capture("kit_back")
 # Deliberate static stress pose for inspecting skin transfer, not a locomotion clip.
 for name: String in ["LeftLowerArm","RightLowerArm"]:
  skeleton.set_bone_pose_rotation(skeleton.find_bone(name),Quaternion(Vector3.RIGHT,deg_to_rad(70)))
 for name: String in ["LeftLowerLeg","RightLowerLeg"]:
  skeleton.set_bone_pose_rotation(skeleton.find_bone(name),Quaternion(Vector3.RIGHT,deg_to_rad(60)))
 camera.position=Vector3(0,1.1,3.3);camera.look_at(Vector3(0,.95,0))
 label.text="STATIC SKIN STRESS DIAGNOSTIC\n70-degree forearms / 60-degree lower legs\nNo animation or production acceptance"
 await capture("kit_stress")
 skeleton.reset_bone_poses()
 metrics["poses"]=["rest front","rest side","rest back","static forearm 70deg/lower-leg 60deg diagnostic"]
 metrics["renderer"]=RenderingServer.get_current_rendering_method()
 metrics["frame_time_valid"]=false
 var file:=FileAccess.open("res://kit_godot_metrics.json",FileAccess.WRITE);file.store_string(JSON.stringify(metrics,"  "));file.close()
 print("KIT_REVIEW ",JSON.stringify(metrics))
 quit()
