extends SceneTree
var failed := 0
var passed := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	root.add_child(game)
	game.set_process(false)
	game.start_run(true)
	game.player.set_physics_process(false)
	var elite = game.spawn_enemy("elite", Vector3(3, 0.05, 31))
	elite.set_physics_process(false)
	var rig = elite.animated_visual
	var skeleton: Skeleton3D = rig.find_children("*", "Skeleton3D", true, false)[0]
	check(skeleton.get_bone_count() == 15 and rig.kind == "elite", "elite uses the human soldier skeleton")
	check(rig.current_pose == "idle", "stationary elite selects combat idle")
	var before: Array[Transform3D] = []
	for i in skeleton.get_bone_count(): before.append(skeleton.get_bone_global_pose(i))
	rig.update_pose(0.3, 4.0, false)
	var changed := false
	for i in skeleton.get_bone_count():
		changed = changed or not before[i].is_equal_approx(skeleton.get_bone_global_pose(i))
	check(rig.current_pose == "run" and changed, "movement selects run and changes actual bone poses")
	rig.update_pose(0.1, 0, true)
	check(rig.current_pose == "stagger", "stagger selects a hit reaction")
	rig.update_pose(0.1, 0, false)
	check(rig.current_pose == "idle", "recovery returns to idle")
	var skin := false
	for mesh in rig.find_children("*", "MeshInstance3D", true, false):
		for i in mesh.mesh.get_surface_count():
			if mesh.mesh.surface_get_material(i).resource_name == "Skin": skin = true
	check(skin, "elite has exposed human skin geometry")
	game.pause_game()
	var t: float = rig.idle_clock
	for i in 8: await physics_frame
	check(rig.idle_clock == t, "pause freezes skeletal playback")
	game.resume_game()
	game.is_test = false # Exercise production corpse creation, suppressed by test mode.
	elite.take_damage(10000, elite.position + Vector3.UP, false, true)
	game.is_test = true
	await process_frame
	check(is_instance_valid(rig) and rig.frozen and rig.get_parent().is_in_group("corpse"), "death binds the human elite to the articulated corpse")
	game.start_run(true)
	await process_frame
	check(not is_instance_valid(rig), "restart frees the old character rig and corpse")
	game.sound.stop_all()
	game.free()
	await process_frame
	print("ELITE ART RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
