extends SceneTree
var captures: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func shot(viewer: Node, name: String) -> void:
 for i: int in 4:await process_frame
 await RenderingServer.frame_post_draw
 var path: String="res://captures/"+name+".png"
 assert(root.get_texture().get_image().save_png(path)==OK)
 captures.append({"file":path,"variant":viewer.variant,"lod":viewer.lod,"distance_m":viewer.distances[viewer.distance_index],"arena":viewer.arena,"orthographic":viewer.orthographic,"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)})
func run() -> void:
 root.size=Vector2i(768,768)
 var viewer: Node=(load("res://review.tscn") as PackedScene).instantiate();root.add_child(viewer)
 DirAccess.make_dir_recursive_absolute("res://captures")
 for variant: int in 12:
  viewer.variant=variant
  for arena: bool in [false,true]:
   viewer.arena=arena;viewer.orthographic=false
   for distance_index: int in 3:
    viewer.distance_index=distance_index;viewer.refresh()
    await shot(viewer,"v%02d_%s_%.1fm" % [variant,"arena" if arena else "neutral",viewer.distances[distance_index]])
  viewer.arena=false;viewer.orthographic=true;viewer.refresh();await shot(viewer,"v%02d_ortho_side"%variant)
  viewer.orthographic=false;viewer.distance_index=0;viewer.status.text="MATCHING HEAD UNDERSIDE | %s | 0.5 m" % str(viewer.importer.manifest.variants[variant].id)
  viewer.cap.visible=false;viewer.exterior.visible=false
  var head: RigidBody3D=viewer.importer.instantiate_head(variant,viewer.settings,Vector3.ZERO,Vector3.ZERO)
  head.freeze=true;viewer.add_child(head)
  viewer.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
  viewer.camera.position=Vector3(0,-.72,.69).normalized()*.5;viewer.camera.look_at(Vector3.ZERO)
  await shot(viewer,"v%02d_matching_underside"%variant)
  head.free();viewer.exterior.visible=true
 viewer.variant=3;viewer.orthographic=false;viewer.distance_index=0
 for lod: int in [1,2]:
  viewer.lod=lod;viewer.refresh();await shot(viewer,"rifle_lod%d"%lod)
 viewer.lod=0;viewer.variant=3;viewer.refresh();viewer.set_process(false)
 viewer.effect.configure(viewer.cap,viewer.settings,124,2,viewer.budget,900)
 for frame: int in 40:
  viewer.effect.advance(1.0/60.0);await physics_frame
 for node: Node in viewer.exterior.find_children("*","MeshInstance3D",true,false):
  (node as MeshInstance3D).set_instance_shader_parameter("wet_front",.7)
 await shot(viewer,"arterial_pulse_full")
 viewer.effect.reset()
 var fragments: Array=viewer.heads.spawn_head_pop(901,Transform3D(Basis.IDENTITY,Vector3(0,.1,0)),Vector3(.5,.6,0),741)
 viewer.cap.visible=false;viewer.exterior.visible=false
 viewer.camera.position=Vector3(0,.7,1.3);viewer.camera.look_at(Vector3(0,.05,0))
 for frame: int in 12:await physics_frame
 viewer.status.text="SOURCE-DERIVED HEAD BREAKUP | four fragments | anatomy review pending"
 await shot(viewer,"shotgun_head_pop")
 viewer.budget.release_owner(901)
 viewer.floor_surface.visible=true;assert(viewer.pool_below(Vector3(0,.1,0),902));viewer.pools.advance(4.0)
 viewer.camera.position=Vector3(0,.28,.4);viewer.camera.look_at(Vector3(0,-.07,0));viewer.status.text="GROWING BLOOD POOL | counts against shared 96-decal budget | Compatibility surface fallback"
 await shot(viewer,"blood_pool_four_seconds")
 viewer.budget.release_owner(902)
 viewer.floor_surface.visible=false;viewer.exterior.visible=true;viewer.variant=3;viewer.lod=0;viewer.distance_index=0;viewer.arena=false;viewer.orthographic=false
 for mode: int in 3:
  viewer.gore_mode=mode;viewer.budget.set_gore_mode(mode);viewer.refresh()
  await shot(viewer,"gore_mode_%d"%mode)
 viewer.gore_mode=2;viewer.budget.set_gore_mode(2)
 for variant: int in [0,3,6,9]:
  viewer.variant=variant;viewer.refresh();viewer.camera.position=Vector3(0,.5,0);viewer.camera.look_at(Vector3.ZERO,Vector3.FORWARD)
  viewer.status.text="OVERHEAD LUMEN CHECK | "+str(viewer.importer.manifest.variants[variant].id)
  await shot(viewer,"v%02d_overhead"%variant)
 var result: Dictionary={"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"frame_time_valid":false,"captures":captures}
 var f:=FileAccess.open("res://capture_report.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 print("NECK_CAP_CAPTURE_COUNT ",captures.size());quit()
