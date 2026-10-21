extends SceneTree
## Capture the real interactive review, with its camera and controls unchanged.
func _initialize() -> void:
 call_deferred("capture")
func capture() -> void:
 var scene: Node=(load("res://death_review.tscn") as PackedScene).instantiate()
 root.add_child(scene)
 for frame: int in 30:await physics_frame
 paused=true
 await process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://death_captures")
 assert(root.get_texture().get_image().save_png("res://death_captures/interactive_review.png")==OK)
 quit()
