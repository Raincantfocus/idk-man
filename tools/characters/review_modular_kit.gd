extends SceneTree
## Run inside the private modular-carrier project. Static engineering review only.
var world: Node3D
var material: ORMMaterial3D
var records: Array
var report: Dictionary={"production_ready":false,"frame_time_valid":false,"parts":[]}
func _initialize() -> void: call_deferred("run")
func settle() -> void:
 for i: int in 8: await process_frame
 await RenderingServer.frame_post_draw
func run() -> void:
 for method: String in ["get_bone_rest","get_bone_name","get_bone_count"]:
  assert(ClassDB.class_has_method("Skeleton3D",method))
 assert(ClassDB.class_has_method("Node","reparent"))
 assert(ClassDB.class_has_method("RenderingServer","get_rendering_info"))
 root.size=Vector2i(900,1100)
 world=Node3D.new();root.add_child(world)
 var environment:=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color(.12,.14,.17)
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_energy=.7;world.add_child(environment)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-30,0);world.add_child(light)
 var camera:=Camera3D.new();camera.fov=40;world.add_child(camera)
 camera.position=Vector3(0,1.1,3.3);camera.look_at(Vector3(0,.95,0));camera.current=true
 var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://parts/modular_parts_report.json"))
 records=source.parts
 var atlas: String=str(records[0].shared_atlas_group)
 material=ORMMaterial3D.new()
 material.albedo_texture=load("res://"+atlas+"_albedo.png")
 material.orm_texture=load("res://"+atlas+"_orm.png")
 material.normal_enabled=true;material.normal_texture=load("res://"+atlas+"_normal.png")
 material.ao_enabled=true
 var complete: Node3D=(load("res://parts/complete_kit.glb") as PackedScene).instantiate()
 world.add_child(complete)
 var complete_meshes: Array[Node]=complete.find_children("*","MeshInstance3D",true,false)
 assert(complete_meshes.size()==1)
 (complete_meshes[0] as MeshInstance3D).material_override=material
 complete.visible=false
 await settle()
 report["baseline_draw_calls"]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
 complete.visible=true
 await settle()
 report["complete_draw_calls"]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
 assert(root.get_texture().get_image().save_png("res://modular_complete.png")==OK)
 complete.visible=false
 var assembly:=Node3D.new();world.add_child(assembly)
 var skeleton: Skeleton3D
 var total: int=0
 for entry: Dictionary in records:
  if entry.part=="complete_kit":continue
  var donor: Node3D=(load("res://parts/"+str(entry.path)) as PackedScene).instantiate()
  assembly.add_child(donor)
  var rigs: Array[Node]=donor.find_children("*","Skeleton3D",true,false)
  assert(rigs.size()==1)
  var rig: Skeleton3D=rigs[0] as Skeleton3D
  assert(rig.get_bone_count()==72)
  if skeleton==null:
   skeleton=rig
   skeleton.reparent(assembly,true)
  else:
   for bone: int in 72:
    assert(rig.get_bone_name(bone)==skeleton.get_bone_name(bone))
    assert(rig.get_bone_rest(bone).is_equal_approx(skeleton.get_bone_rest(bone)))
  var meshes: Array[Node]=donor.find_children("*","MeshInstance3D",true,false)
  # First donor's meshes may have moved with the skeleton.
  if meshes.is_empty():meshes=skeleton.find_children("*","MeshInstance3D",true,false)
  assert(meshes.size()==1)
  var mesh: MeshInstance3D=meshes[0] as MeshInstance3D
  mesh.reparent(assembly,true);mesh.skeleton=mesh.get_path_to(skeleton)
  mesh.material_override=material
  assert(mesh.skin!=null and mesh.mesh.get_surface_count()==1)
  var arrays: Array=mesh.mesh.surface_get_arrays(0)
  var triangles: int=(arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3
  assert(triangles==int(entry.triangles))
  assert(not (arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array).is_empty())
  total+=triangles
  report.parts.append({"name":entry.part,"triangles":triangles,"surfaces":1})
  donor.free()
 assert(assembly.find_children("*","Skeleton3D",true,false).size()==1)
 assert(total==int(source.source_triangles))
 await settle()
 report["separate_draw_calls"]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
 report["kits"]=[]
 for entry: Dictionary in source.get("kits",[]):
  var kit: Node3D=(load("res://parts/"+str(entry.path)) as PackedScene).instantiate()
  var meshes: Array[Node]=kit.find_children("*","MeshInstance3D",true,false)
  assert(meshes.size()==1)
  var mesh: MeshInstance3D=meshes[0] as MeshInstance3D
  assert(mesh.mesh.get_surface_count()==1 and mesh.skin!=null)
  var arrays: Array=mesh.mesh.surface_get_arrays(0)
  assert((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3==int(entry.triangles))
  report.kits.append({"name":entry.part,"triangles":entry.triangles,"surfaces":1})
  kit.free()
 report["triangles"]=total;report["bones"]=72;report["materials"]=1
 report["renderer"]=RenderingServer.get_current_rendering_method()
 assert(root.get_texture().get_image().save_png("res://modular_separate.png")==OK)
 var file:=FileAccess.open("res://modular_godot_report.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "));file.close()
 print("MODULAR_REVIEW ",JSON.stringify(report));quit()
