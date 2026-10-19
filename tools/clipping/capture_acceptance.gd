extends SceneTree
var viewer: Node
var output: String
var body: MeshInstance3D
var driver: RefCounted
var entries: Array=[]
var draw_metrics: Array=[]
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 for i: int in 3:await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(output+"/"+name+".png")==OK)
 entries.append(name)
 draw_metrics.append({"capture":name,"viewport_draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"viewport_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
func run() -> void:
 root.size=Vector2i(1000,900)
 var args: PackedStringArray=OS.get_cmdline_user_args();output=args[2];DirAccess.make_dir_recursive_absolute(output)
 var patch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 var audit: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[1]))
 viewer=(load("res://baseline_review.tscn" if FileAccess.file_exists("res://baseline_review.tscn") else "res://review.tscn") as PackedScene).instantiate();root.add_child(viewer);viewer.set_process(false)
 var meshes: Dictionary=preload("res://scripts/clipping/apply_patch.gd").apply(viewer.model_root,patch)
 body=meshes.Body_LOD0
 driver=preload("res://scripts/clipping/corrective_driver.gd").new();driver.configure(viewer.skeleton,meshes,patch)
 var original_transform: Transform3D=viewer.camera.transform
 var targets: Dictionary={"chest":"Chest","abdomen":"Spine","shoulders":"LeftUpperArm","elbows":"LeftLowerArm","knees":"LeftLowerLeg"}
 for clip: String in ["hold","run_loop","fire","reload_cover"]:
  viewer.controller.preview_clip(StringName(clip))
  var worst: Dictionary={"max_penetration_mm":-1.0}
  for frame: Dictionary in audit.frames:
   if frame.clip==clip and frame.max_penetration_mm>worst.max_penetration_mm:worst=frame
  viewer.controller.player.seek(float(worst.time),true);viewer.skeleton.force_update_all_bone_transforms();driver.advance(4.0)
  viewer.camera.transform=original_transform
  viewer.status.text="CLIPPING REVIEW | %s frame %d | UNAPPROVED\nSame review camera | corrective candidates, not accepted" % [clip,int(worst.frame)]
  for reveal: int in [0,1]:
   body.set_instance_shader_parameter("reveal",float(reveal));await shot(clip+"_reveal_"+str(reveal))
  body.set_instance_shader_parameter("reveal",0.0)
  body.set_instance_shader_parameter("mask_view",true)
  for garment: MeshInstance3D in viewer.gear:garment.visible=false
  await shot(clip+"_coverage_mask")
  body.set_instance_shader_parameter("mask_view",false)
  for garment: MeshInstance3D in viewer.gear:garment.visible=true
  for region: String in targets:
   var row: Dictionary={}
   for candidate: Dictionary in audit.rows:
    if candidate.clip==clip and candidate.region==region:row=candidate;break
   viewer.controller.player.seek(float(row.worst_frame)/60.0,true);viewer.skeleton.force_update_all_bone_transforms();driver.advance(4.0)
   var joint: int=viewer.skeleton.find_bone(targets[region]);assert(joint>=0)
   var center: Vector3=viewer.skeleton.global_transform*viewer.skeleton.get_bone_global_pose(joint).origin
   viewer.camera.position=center+Vector3(.55,.12,.90);viewer.camera.look_at(center)
   viewer.status.text="%s | %s | region worst frame %d | UNAPPROVED" % [clip,region,int(row.worst_frame)]
   await shot(clip+"_"+region)
 var before: int=Time.get_ticks_usec()
 for i: int in 1000:driver.advance(4.0)
 var near_us: float=float(Time.get_ticks_usec()-before)/1000.0
 before=Time.get_ticks_usec()
 for i: int in 1000:driver.advance(20.0)
 var far_us: float=float(Time.get_ticks_usec()-before)/1000.0
 var triangles: int=0
 for mesh: MeshInstance3D in meshes.values():triangles+=mesh.mesh.surface_get_array_index_len(0)/3
 var report: Dictionary={"captures":entries,"draw_metrics":draw_metrics,"missing_clips":["flinch","death"],"triangles":triangles,"mesh_surfaces":meshes.size(),"corrective_cpu_us_per_update_near":near_us,"corrective_cpu_us_per_update_far":far_us,"renderer":RenderingServer.get_video_adapter_name(),"hardware_gpu_timing_valid":false,"acceptance":false}
 var file:=FileAccess.open(output+"/capture_report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("CLIPPING_CAPTURES_COMPLETE ",JSON.stringify(report));quit()
