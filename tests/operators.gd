extends SceneTree
var game
var passed := 0
var failed := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)
func ticks(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	root.add_child(game)
	game.set_process(false)
	game.start_run(true)
	game.player.set_physics_process(false)
	await ticks(2)
	for kind in ["enforcer", "rusher", "shield", "flusher"]:
		var enemy = game.spawn_enemy(kind, Vector3(0, 0.05, 8))
		enemy.set_physics_process(false)
		await process_frame
		var rig = enemy.animated_visual
		check(rig.skeleton.get_bone_count() == 15 and enemy.body.get_child_count() == 1, kind + " uses the authored skin without old box geometry")
		var thigh: int = rig.skeleton.find_bone("thigh_L")
		var initial: Transform3D = rig.skeleton.get_bone_global_pose(thigh)
		rig.update_pose(0.3, 4, false)
		rig.skeleton.force_update_all_bone_transforms()
		check(rig.current_pose == "run" and not rig.skeleton.get_bone_global_pose(thigh).is_equal_approx(initial), kind + " locomotion changes the actual skeleton")
		rig.update_pose(0.2, 0, true)
		check(rig.current_pose == "stagger", kind + " shows a hit reaction")
		rig.set_windup(1)
		rig.on_attack()
		rig.update_pose(0.02, 0, false)
		check(rig.current_pose == "attack" and rig.visor_material.emission_energy_multiplier > 3, kind + " displays attack motion and windup lighting")
		if kind == "shield":
			game.player.position = Vector3(0, 0.05, 0)
			enemy.take_damage(40, enemy.position + Vector3.UP)
			check(enemy.health == enemy.max_health, "new shield model retains frontal protection")
			game.player.position = Vector3(0, 0.05, 12)
			enemy.take_damage(40, enemy.position + Vector3.UP)
			check(enemy.health == enemy.max_health - 40, "shield remains vulnerable from the rear")
		enemy.free()
		game.clean_references()
	var source = game.spawn_enemy("enforcer", Vector3(5, 3, 25))
	source.set_physics_process(false)
	var rig = source.animated_visual
	rig.update_pose(0.35, 3, false)
	rig.skeleton.force_update_all_bone_transforms()
	var head: int = rig.skeleton.find_bone("head")
	var head_before: Transform3D = rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(head)
	game.is_test = false
	var corpse = game.spawn_corpse(source.body, source.position, source.color)
	game.is_test = true
	source.free()
	game.clean_references()
	check(rig.bindings.size() == 15 and rig.get_parent() == corpse, "all bones bind to articulated corpse regions")
	rig.skeleton.force_update_all_bone_transforms()
	check((rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(head)).is_equal_approx(head_before), "death transfer preserves the visible pose")
	await ticks(120)
	rig.skeleton.force_update_all_bone_transforms()
	var head_after: Transform3D = rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(head)
	check(head_after.origin.y < head_before.origin.y and head_after.is_finite(), "skinned corpse follows falling physics bodies")
	game.pause_game()
	var age: float = corpse.age
	await ticks(8)
	check(corpse.age == age, "pause freezes articulated skeletal corpses")
	game.resume_game()
	corpse.settle()
	await ticks(3)
	check(not rig.is_physics_processing(), "settled character stops skeletal corpse updates")
	game.start_run(true)
	await ticks(2)
	check(not is_instance_valid(rig), "restart frees the skinned corpse and bone bindings")
	game.cycle_training_type()
	game.spawn_training_dummy()
	check(game.enemies.back().kind == "rusher" and game.enemies.back().training_dummy, "lab B selection changes the T-spawned target")
	game.start_run()
	game.cycle_training_type()
	check(game.practice_dummy_index == 0, "normal trials cannot cycle practice target types")
	game.sound.stop_all()
	await create_timer(0.1, true, false, true).timeout
	game.free()
	await physics_frame
	await process_frame
	print("OPERATOR ART RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
