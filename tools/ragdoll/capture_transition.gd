extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://transition_captures")
 var scene: Node=load("res://ragdoll_review.tscn").instantiate();root.add_child(scene)
 var args: PackedStringArray=OS.get_cmdline_user_args()
 var clip: String=args[0] if not args.is_empty() else "death"
 scene.select("rifle");scene.select("Clip: "+clip)
 var tick: int=0
 for target: int in ([12,90,600] if clip.ends_with("death_from_right") else [30,150,600]):
  while tick<target:await physics_frame;tick+=1
  paused=true;await process_frame;await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("res://transition_captures/%s_frame_%d.png"%[clip,target])==OK)
  print("CAPTURE_STATE ",target," ",scene.actor.State.keys()[scene.actor.state]," ",scene.actor.physical.Hips.global_position)
  paused=false
 scene.free();quit()
