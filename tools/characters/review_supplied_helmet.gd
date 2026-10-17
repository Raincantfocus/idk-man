extends SceneTree
## Standalone private gear review; no gameplay or procedural body animation.
var world: Node3D
var camera: Camera3D
var body: Node3D
var skeleton: Skeleton3D
var attachment: BoneAttachment3D
var helmet: Node3D
var label: Label
var metrics: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func settle() -> void:
 for i: int in 6: await process_frame
 await RenderingServer.frame_post_draw
func capture(name: String) -> void:
 await settle()
 var error: Error=root.get_texture().get_image().save_png("res://"+name+".png")
 assert(error==OK)
func show_lod(index: int) -> void:
 if is_instance_valid(helmet): helmet.free()
 helmet=(load("res://helmet_lod%d.glb"%index) as PackedScene).instantiate() as Node3D
 attachment.add_child(helmet)
 # Review placement only: adjust against captured crown/ear clearance, no body scaling.
 var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://helmet_conversion.json"))
 var origin: Array=config["review_fit_world_origin_m"]
 helmet.global_transform=Transform3D(Basis.IDENTITY,Vector3(origin[0],origin[1],origin[2]))
 metrics["socket_transform"]=var_to_str(helmet.transform)
 var triangles: int=0
 var surfaces: int=0
 var materials: Array[Material]=[]
 for node: Node in helmet.find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D
  for surface: int in mesh.mesh.get_surface_count():
   var arrays: Array=mesh.mesh.surface_get_arrays(surface)
   triangles+=(arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3
   surfaces+=1
   var mat: Material=mesh.get_active_material(surface)
   if not materials.has(mat): materials.append(mat)
 if metrics.has("lod%d"%index): return
 metrics["lod%d"%index]={"triangles":triangles,"surfaces":surfaces,"materials":materials.size()}
func run() -> void:
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 root.content_scale_size=Vector2i.ZERO
 root.size=Vector2i(1200,1000)
 world=Node3D.new();root.add_child(world)
 var env:=WorldEnvironment.new();env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color(.12,.14,.17)
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.65
 world.add_child(env)
 var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-30,-30,0);key.light_energy=2;world.add_child(key)
 var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(10,140,0);fill.light_energy=.7;world.add_child(fill)
 camera=Camera3D.new();camera.fov=40;world.add_child(camera);camera.current=true
 body=(load("res://standard_lod0.glb") as PackedScene).instantiate() as Node3D;world.add_child(body)
 skeleton=body.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
 assert(skeleton.find_bone("Head")>=0)
 attachment=BoneAttachment3D.new();attachment.bone_name="Head";skeleton.add_child(attachment)
 var layer:=CanvasLayer.new();world.add_child(layer);label=Label.new();label.position=Vector2(24,20);layer.add_child(label)
 label.text="PRIVATE HELMET FIT REVIEW"
 await settle()
 camera.position=Vector3(0,1.73,1.3);camera.look_at(Vector3(0,1.68,0))
 body.visible=false
 await settle()
 metrics["baseline_draw_calls"]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
 body.visible=true
 await settle()
 metrics["body_only_draw_calls"]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
 for index: int in 4:
  show_lod(index)
  label.text="PRIVATE HELMET FIT REVIEW — LOD %d\nAuthored Makarov helmet / CC0 reference body\nNot an approved role kit or final shared atlas"%index
  await capture("helmet_front_lod%d"%index)
  metrics["lod%d"%index]["scene_draw_calls"]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
 show_lod(0)
 camera.position=Vector3(1.3,1.73,0);camera.look_at(Vector3(0,1.68,0))
 label.text="PRIVATE HELMET FIT REVIEW — SIDE\nHead socket attachment / no body scaling"
 await capture("helmet_side")
 camera.position=Vector3(0,1.1,3);camera.look_at(Vector3(0,1,0))
 label.text="PRIVATE HELMET FIT REVIEW\nReference body is not a finished soldier"
 await capture("helmet_full_body")
 # Persist the exact local socket transform as an unapproved presentation Resource.
 var part_script: Script=load("res://character_part.gd") as Script
 var part: Resource=part_script.new()
 part.set("part_id",&"makarov_helmet_review")
 part.set("source_url","user-upload:Makarov (shaded soldier)")
 part.set("license_id","user-purchased; redistribution terms unverified")
 part.set("body_shape",&"standard")
 part.set("socket_bone",&"Head")
 part.set("socket_transform",helmet.transform)
 var scenes: Array[PackedScene]=[]
 for index: int in 4: scenes.append(load("res://helmet_lod%d.glb"%index) as PackedScene)
 part.set("lod_scenes",scenes)
 part.set("reviewed",false)
 assert(ResourceSaver.save(part,"res://helmet_review_part.tres")==OK)
 metrics["body_bones"]=skeleton.get_bone_count()
 metrics["socket_bone"]=attachment.bone_name
 metrics["renderer"]=RenderingServer.get_current_rendering_method()
 metrics["performance_note"]="Software renderer: frame timings are not target hardware evidence"
 var file:=FileAccess.open("res://godot_metrics.json",FileAccess.WRITE);file.store_string(JSON.stringify(metrics,"  "));file.close()
 print("GEAR_REVIEW_METRICS ",JSON.stringify(metrics))
 quit()
