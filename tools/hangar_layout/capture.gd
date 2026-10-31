extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var packed := load("res://scenes/maps/hangar_layout/hangar.tscn") as PackedScene
	var arena := packed.instantiate()
	root.add_child(arena)
	var camera := arena.get_node("ReviewCamera") as Camera3D
	var views: Array[Dictionary] = [
 {"name":"hub","position":Vector3(0,1.65,0),"target":Vector3(-6,1.5,4)},
 {"name":"west_breach","position":Vector3(-38,1.65,-9),"target":Vector3(-22,1.5,-9)},
 {"name":"north_sniper","position":Vector3(-55,7.65,-44),"target":Vector3(-30,1.5,-9)},
 {"name":"yard","position":Vector3(-65,1.65,20),"target":Vector3(-40,2,-15)},
 {"name":"overview","position":Vector3(-40,12,28),"target":Vector3(0,1,0)},
 {"name":"plan_cutaway","position":Vector3(0,180,0),"target":Vector3.ZERO}
 ]
	var stats: Array = []
	for view: Dictionary in views:
		camera.position = view.position
		if view.name=="plan_cutaway":
			for node: Node3D in get_nodes_in_group("rev_b_roof_review"): node.visible = false
			arena.zones.Roof.visible = false
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = 174
		camera.look_at(view.target,Vector3.FORWARD if view.name=="plan_cutaway" else Vector3.UP)
		for i in range(5):await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("res://docs/hangar-layout/"+view.name+".png")
		assert(error==OK)
		stats.append({"view":view.name,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"rendered_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
		print("CAPTURED ",view.name)
	var f := FileAccess.open("res://docs/hangar-layout/render_counts.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"renderer":"Compatibility / llvmpipe software; frame times invalid for target hardware","views":stats},"\t"))
	quit()
