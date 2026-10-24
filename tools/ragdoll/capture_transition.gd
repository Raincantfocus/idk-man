extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://transition_captures")
 var scene: Node=load("res://ragdoll_review.tscn").instantiate();root.add_child(scene)
 scene.select("rifle");scene.select("Clip: death")
 var tick: int=0
 for target: int in [30,150,600]:
  while tick<target:await physics_frame;tick+=1
  paused=true;await process_frame;await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("res://transition_captures/frame_%d.png"%target)==OK)
  print("CAPTURE_STATE ",target," ",scene.actor.State.keys()[scene.actor.state]," ",scene.actor.physical.Hips.global_position)
  paused=false
 scene.free();quit()
