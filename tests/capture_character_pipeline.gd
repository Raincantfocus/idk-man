extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var scene: Node3D=load("res://scenes/characters/character_review.tscn").instantiate() as Node3D
 root.add_child(scene)
 DirAccess.make_dir_recursive_absolute("res://test-output/character-pipeline")
 for shape: int in [0,1,3]:
  scene.show_variant(1,shape)
  for i: int in 5: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test-output/character-pipeline/body_%d.png"%shape)
  print("CAPTURE shape=",shape," draw_calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)," rendered_primitives=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
 scene.lod_index=3
 scene.assembly.set_lod(3)
 scene._label()
 for i: int in 5: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://test-output/character-pipeline/body_lod3.png")
 scene.free()
 quit()
