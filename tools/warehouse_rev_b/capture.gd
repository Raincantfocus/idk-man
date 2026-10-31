extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var packed := load("res://scenes/maps/warehouse_rev_b/warehouse_main.tscn") as PackedScene
	var arena := packed.instantiate()
	root.add_child(arena)
	var camera := arena.get_node("ReviewCamera") as Camera3D
	var views: Array[Dictionary] = [
		{"name":"overview","position":Vector3(-34,6.6,27),"target":Vector3(0,2,0)},
		{"name":"mid_approach","position":Vector3(0,1.65,23),"target":Vector3(0,2,0)},
		{"name":"west_aisles","position":Vector3(-35,1.65,-24),"target":Vector3(-38,1.4,6)},
		{"name":"east_vehicles","position":Vector3(38,1.65,25),"target":Vector3(36,1.3,-20)},
		{"name":"tower_top","position":Vector3(0,7.65,0),"target":Vector3(5,2,20)},
		{"name":"killhouse_rooms","position":Vector3(-12,2.5,-6),"target":Vector3(0,2,0)},
		{"name":"plan_cutaway","position":Vector3(0,100,0),"target":Vector3.ZERO}
	]
	var stats: Array = []
	for view: Dictionary in views:
		camera.position = view.position
		if view.name=="plan_cutaway":
			for node: Node3D in get_nodes_in_group("rev_b_roof_review"): node.visible = false
			arena.zones.Skylights.visible = false
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = 108
		camera.look_at(view.target,Vector3.FORWARD if view.name=="plan_cutaway" else Vector3.UP)
		for i in range(5):await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("res://docs/warehouse-rev-b/"+view.name+".png")
		assert(error==OK)
		stats.append({"view":view.name,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"rendered_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
		print("CAPTURED ",view.name)
	var f := FileAccess.open("res://docs/warehouse-rev-b/render_counts.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"renderer":"Compatibility / llvmpipe software; frame times invalid for target hardware","views":stats},"\t"))
	quit()
