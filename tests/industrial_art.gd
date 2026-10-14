extends SceneTree
var failed := 0
var passed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func run() -> void:
	var arena = load("res://scripts/arena.gd").new()
	root.add_child(arena)
	arena.build()
	var props := get_nodes_in_group("authored_prop")
	check(props.size() >= 30, "authored industrial models replace cover throughout the arena")
	var aligned := true
	var textured := true
	for prop in props:
		var parent: Node3D = prop.get_parent()
		var shape: CollisionShape3D = parent.get_child(1)
		var envelope := AABB(-shape.shape.size / 2, shape.shape.size).grow(0.01)
		var meshes := prop.find_children("*", "MeshInstance3D", true, false)
		if prop is MeshInstance3D:
			meshes.append(prop)
		for mesh in meshes:
			var local_pose: Transform3D = parent.global_transform.affine_inverse() * mesh.global_transform
			aligned = aligned and envelope.encloses(local_pose * mesh.get_aabb())
			var mat: StandardMaterial3D = mesh.get_surface_override_material(0)
			textured = textured and mat.albedo_texture != null and mat.normal_texture != null and mat.roughness_texture != null
	check(aligned, "model geometry fits the gameplay collision envelopes")
	check(textured, "authored models carry albedo, normal, and roughness textures")
	var tiled: StandardMaterial3D = arena.art.pbr("tile_simple_floor", 0.25)
	check(tiled.uv1_world_triplanar and tiled.uv1_scale == Vector3.ONE * 0.25, "structural materials keep consistent world-scale tiling")
	check(arena.art.pbr("mid_cargo_box") == arena.art.pbr("mid_cargo_box"), "prop instances share their atlas material")
	arena.free()
	await process_frame
	print("ART RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
