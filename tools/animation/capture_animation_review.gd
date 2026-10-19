extends SceneTree
var captures: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func shot(viewer: Node, name: String) -> void:
 for i: int in 3:await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://captures/"+name+".png")==OK)
 captures.append({"file":name+".png","draw_calls_scene":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives_scene":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)})
func run() -> void:
 root.size=Vector2i(1000,900)
 var viewer: Node=(load("res://review.tscn") as PackedScene).instantiate();root.add_child(viewer);viewer.set_process(false)
 DirAccess.make_dir_recursive_absolute("res://captures")
 for clip: StringName in [&"hold",&"run_start",&"run_loop",&"run_stop",&"fire",&"reload_cover",&"turn_left",&"turn_right",&"side_shoot"]:
  viewer.controller.preview_clip(clip)
  var animation: Animation=viewer.controller.player.get_animation(clip)
  for fraction: float in [.1,.5,.85]:
   viewer.controller.player.seek(animation.length*fraction,true);viewer.skeleton.force_update_all_bone_transforms()
   viewer.status.text="SUPPLIED MOCAP RETARGET | %s | %.2f s\nNative Godot capture | no foot/weapon IK; corrective review pending" % [clip,animation.length*fraction]
   await shot(viewer,"%s_%02d"%[clip,int(fraction*100)])
 viewer.controller.use_locomotion()
 for i: int in 30:viewer.controller.advance(1.0/60.0,5)
 viewer.controller.on_attack()
 for i: int in 30:viewer.controller.advance(1.0/60.0,5)
 viewer.status.text="ANIMATION TREE | run + upper-body shooting"
 await shot(viewer,"run_fire_layer")
 viewer.controller.preview_clip(&"run_loop")
 for frame: int in 39:
  viewer.controller.player.seek(frame/60.0,true);viewer.skeleton.force_update_all_bone_transforms();viewer.status.text="AUTHORED RUN LOOP | frame %02d | 60 Hz source"%frame
  await shot(viewer,"run_frame_%03d"%frame)
 var geometry: Array[Dictionary]=[]
 for node: Node in viewer.model_root.find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D;var triangles: int=0
  for surface: int in mesh.mesh.get_surface_count():
   var arrays: Array=mesh.mesh.surface_get_arrays(surface);var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
   triangles+=indices.size()/3 if not indices.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()/3
  geometry.append({"name":String(mesh.name),"triangles":triangles,"surfaces":mesh.mesh.get_surface_count()})
 var f:=FileAccess.open("res://capture_report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"hardware_frame_time_valid":false,"captures":captures,"geometry":geometry},"  "));f.close()
 print("ANIMATION_CAPTURES ",captures.size());quit()
