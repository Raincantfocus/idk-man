extends SceneTree
var captures: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func shot(viewer: Node, name: String) -> void:
 for i: int in 3:await process_frame
 await RenderingServer.frame_post_draw
 var path: String="res://captures/"+name+".png"
 assert(root.get_texture().get_image().save_png(path)==OK)
 captures.append({"file":path,"variant":viewer.variant,"lod":viewer.lod,"distance_m":viewer.distances[viewer.distance_index],"arena":viewer.arena,"orthographic":viewer.orthographic,"draw_calls_scene":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)})
func run() -> void:
 root.size=Vector2i(768,768)
 var viewer: Node=(load("res://review.tscn") as PackedScene).instantiate();root.add_child(viewer)
 DirAccess.make_dir_recursive_absolute("res://captures")
 for variant: int in viewer.importer.manifest.variants.size():
  viewer.variant=variant;viewer.lod=0;viewer.orthographic=false
  for arena: bool in [false,true]:
   viewer.arena=arena
   for distance_index: int in 3:
    viewer.distance_index=distance_index;viewer.refresh()
    await shot(viewer,"v%02d_%s_%.1fm" % [variant,"arena" if arena else "neutral",viewer.distances[distance_index]])
  viewer.arena=false;viewer.orthographic=true;viewer.refresh();await shot(viewer,"v%02d_side"%variant)
  viewer.orthographic=false;viewer.distance_index=0
  for lod: int in [1,2]:
   viewer.lod=lod;viewer.refresh();await shot(viewer,"v%02d_lod%d"%[variant,lod])
 var f:=FileAccess.open("res://capture_report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"hardware_frame_time_valid":false,"captures":captures},"  "));f.close()
 print("BODY_CAPTURE_COUNT ",captures.size());quit()
