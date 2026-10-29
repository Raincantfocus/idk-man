extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	# Verify capture APIs against the installed engine before invoking them.
	for spec: Array in [["Viewport", "get_texture"], ["Texture2D", "get_image"], ["Image", "save_png"], ["Node3D", "look_at"]]:
		var found := false
		for method: Dictionary in ClassDB.class_get_method_list(spec[0]):
			if method["name"] == spec[1]:
				found = true
		assert(found, "Missing API: %s.%s" % [spec[0], spec[1]])
	print("VERIFIED_CAPTURE_APIS ", Engine.get_version_info()["string"])
	var scene := load("res://scenes/maps/zero_line_hangar.tscn") as PackedScene
	var instance := scene.instantiate()
	root.add_child(instance)
	var camera := instance.get_node("ReviewCamera") as Camera3D
	var views: Array[Dictionary] = [
		{"name": "north_entry", "position": Vector3(8, 1.65, -0.5), "target": Vector3(8, 1.6, -18)},
		{"name": "north_door", "position": Vector3(10, 1.65, -8), "target": Vector3(8, 1.4, -12)},
		{"name": "south_door", "position": Vector3(10, 1.65, -38), "target": Vector3(8, 1.4, -34.425)},
		{"name": "side_alley", "position": Vector3(1.1, 1.65, -9), "target": Vector3(1.1, 1.65, -36)},
		{"name": "core_open_roof", "position": Vector3(8, 4.2, -14), "target": Vector3(8, 1.1, -27)}
	]
	for view: Dictionary in views:
		camera.position = view["position"]
		camera.look_at(view["target"])
		for frame in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://docs/killhouse-enclosure/%s.png" % view["name"])
		assert(result == OK)
		print("CAPTURED ", view["name"])
	quit()
