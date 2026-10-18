extends SceneTree
const Region = preload("res://head_neck_review.gd")
var region: Region
var camera: Camera3D
var world: Node3D
var report: Dictionary={"production_ready":false,"frame_time_valid":false,"captures":[],"states":[]}
func _initialize() -> void:call_deferred("run")
func settle() -> void:
 for i: int in 5:await process_frame
 await RenderingServer.frame_post_draw
func run() -> void:
 root.size=Vector2i(512,512)
 world=Node3D.new();root.add_child(world)
 var environment:=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color(.12,.14,.17)
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_energy=.65;world.add_child(environment)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-30,0);light.light_energy=2;world.add_child(light)
 var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(10,140,0);fill.light_energy=.7;world.add_child(fill)
 camera=Camera3D.new();camera.fov=50;world.add_child(camera);camera.current=true
 region=Region.new();world.add_child(region)
 assert(region.configure("res://manifest.json"),str(region.errors))
 region.camera=camera
 var states: Array[StringName]=[&"intact",&"damaged",&"fractured_closed",&"fractured_open",&"detached"]
 var poses: Array[Dictionary]=[{"name":"rest","bone":"Neck","axis":Vector3.RIGHT,"degrees":0.0}]
 for correction: Dictionary in region.manifest.correctives:
  var a: Array=correction.axis
  poses.append({"name":correction.shape,"bone":correction.bone,"axis":Vector3(float(a[0]),float(a[1]),float(a[2])),"degrees":float(correction.angle_degrees)})
 var views: Dictionary={"front":Vector3(0,1.73,.84),"side":Vector3(.84,1.73,.08),"back":Vector3(0,1.73,-.76)}
 DirAccess.make_dir_recursive_absolute("res://captures_godot")
 for state: StringName in states:
  assert(region.set_state(state),str(region.errors))
  var instance: Node=region.current
  assert(region.set_state(state) and region.current==instance,"Same-state calls must be idempotent")
  var triangles: int=0;var materials: Array[Material]=[]
  for mesh: MeshInstance3D in region.meshes:
   if not mesh.visible:continue
   for surface: int in mesh.mesh.get_surface_count():
    var arrays: Array=mesh.mesh.surface_get_arrays(surface)
    triangles+=(arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3
    var material: Material=mesh.get_active_material(surface)
    if not materials.has(material):materials.append(material)
  report.states.append({"state":state,"visible_triangles":triangles,"base_material_resources":materials.size(),"bones":region.skeleton.get_bone_count()})
  for pose: Dictionary in poses:
   region.skeleton.reset_bone_poses()
   region.skeleton.set_bone_pose_rotation(region.skeleton.find_bone(pose.bone),Quaternion(pose.axis,deg_to_rad(pose.degrees)))
   region.update_correctives()
   if pose.name!="rest":
    for binding: Dictionary in region.corrective_bindings:
     var mesh: MeshInstance3D=binding.mesh
     if mesh.mesh.get_blend_shape_name(binding.index)==str(pose.name):
      assert(is_equal_approx(mesh.get_blend_shape_value(binding.index),1.0),"Corrective did not reach full weight")
   for view: String in views:
    camera.position=views[view];camera.look_at(Vector3(0,1.71,.06))
    await settle()
    var path: String="captures_godot/"+String(state)+"_"+str(pose.name)+"_"+view+".png"
    assert(root.get_texture().get_image().save_png("res://"+path)==OK)
    report.captures.append(path)
  report.states[-1]["isolated_draw_calls"]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
  # Inspect every torn variant in the detached state.
  if state==&"detached":
   for variant: int in 3:
    region.set_variant(variant)
    assert(region.meshes.filter(func(m: MeshInstance3D) -> bool:return m.visible).size()==2)
   region.set_variant(0)
 for state: StringName in [&"fractured_open",&"detached"]:
  assert(region.set_state(state));region.skeleton.reset_bone_poses()
  for variant: int in [1,2]:
   region.set_variant(variant)
   for view: String in views:
    camera.position=views[view];camera.look_at(Vector3(0,1.71,.06))
    await settle()
    var path: String="captures_godot/"+String(state)+"_v"+str(variant)+"_"+view+".png"
    assert(root.get_texture().get_image().save_png("res://"+path)==OK);report.captures.append(path)
 # Interior scene remains uninstantiated throughout all presentation states.
 assert(world.find_children("HN_skull","MeshInstance3D",true,false).is_empty())
 assert(not region.set_state(&"invalid"))
 region.visible=false
 var interiors: Node3D=(load("res://HN_interiors.glb") as PackedScene).instantiate()
 world.add_child(interiors)
 for view: String in views:
  camera.position=views[view];camera.look_at(Vector3(0,1.71,.06));await settle()
  var path: String="captures_godot/interiors_"+view+".png"
  assert(root.get_texture().get_image().save_png("res://"+path)==OK);report.captures.append(path)
 interiors.free()
 # Distance cutoff must zero corrections instead of leaving frozen stale values.
 camera.position=Vector3(0,0,100);region.update_correctives()
 for binding: Dictionary in region.corrective_bindings:
  assert(is_zero_approx((binding.mesh as MeshInstance3D).get_blend_shape_value(int(binding.index))))
 report["renderer"]=RenderingServer.get_current_rendering_method()
 var file:=FileAccess.open("res://godot_validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("HEAD_NECK_GODOT_REVIEW ",JSON.stringify({"captures":report.captures.size(),"states":report.states,"frame_time_valid":false}));quit()
