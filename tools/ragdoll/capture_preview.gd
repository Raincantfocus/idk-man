extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://preview_captures")
 var scene: Node=load("res://ragdoll_review.tscn").instantiate();root.add_child(scene)
 scene.select("Animation preview")
 scene.select("Clip: death_from_right")
 for i: int in 5:await physics_frame
 for time: float in [.1,.8,1.4]:
  scene.preview_time=time;scene._physics_process(0.0);paused=true
  await process_frame;await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("res://preview_captures/death_right_%.1f.png"%time)==OK)
  paused=false
 scene.free();quit()
