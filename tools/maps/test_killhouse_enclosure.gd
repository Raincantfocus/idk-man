extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	for spec: Array in [["PhysicsDirectSpaceState3D", "intersect_ray"], ["PhysicsRayQueryParameters3D", "create"], ["World3D", "get_direct_space_state"]]:
		var found := false
		for method: Dictionary in ClassDB.class_get_method_list(spec[0]):
			if method["name"] == spec[1]:
				found = true
		assert(found, "Missing API %s.%s" % [spec[0], spec[1]])
	var packed := load("res://scenes/maps/zero_line_hangar.tscn") as PackedScene
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/hangar_staging_layout.json"))
	var space := scene.get_world_3d().direct_space_state
	var checks := 0
	for section: Dictionary in cfg["killhouse_enclosure"]["segments"]:
		var c: Array = section["center"]
		var center := Vector3(c[0], c[1], c[2])
		var direction := Vector3.RIGHT if section["name"] in ["West", "East"] else Vector3.BACK
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(center - direction * 0.4, center + direction * 0.4))
		assert(not hit.is_empty(), "Missing wall collision: " + str(section["name"]))
		checks += 1
	for entry: Dictionary in cfg["egress"]:
		var c: Array = entry["position"]
		for y in [0.1, 1.1, 2.1]:
			for x in [-0.55, 0.0, 0.55]:
				var origin := Vector3(c[0] + x, y, c[2] - 0.5)
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + Vector3(0, 0, 1)))
				assert(hit.is_empty(), "Door collision obstructed: " + str(entry["id"]))
				checks += 1
	print("ENCLOSURE_PHYSICS_PASS ", checks, " rays; engine=", Engine.get_version_info()["string"], "; physics=", ProjectSettings.get_setting("physics/3d/physics_engine"))
	quit()
