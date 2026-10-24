extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://ground_captures")
 var scene: Node=load("res://ragdoll_review.tscn").instantiate();root.add_child(scene)
 scene.select("Collision test");scene.select("rifle");scene.select("front")
 for time: float in [.25,1.2]:
  while scene.actor.elapsed<time:
   await physics_frame
   assert(scene.actor.handoff_count==0,"Premature handoff before capture")
  paused=true;await process_frame;await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("res://ground_captures/front_%.2f.png"%time)==OK)
  paused=false
 scene.free();quit()
