extends SceneTree
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
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.is_test = true
	game.arena_factory = preload("res://tests/fixtures/arena_v08.gd")
	root.add_child(game)
	game.set_process(false)
	game.start_run(true)
	game.player.set_physics_process(false)
	var enemy = game.spawn_enemy("enforcer", Vector3(5, 3, 25))
	enemy.set_physics_process(false)
	game.is_test = false
	var corpse = game.spawn_corpse(enemy.body, enemy.position, enemy.color)
	game.is_test = true
	enemy.free()
	check(corpse.region_at(Vector3(0,1.6,0)) == "head", "head hit maps to head")
	check(corpse.region_at(Vector3(-.3,1.1,0)) == "left_arm", "left arm hit localization")
	check(corpse.region_at(Vector3(.1,.4,0)) == "right_leg", "leg hit localization")
	game.gore_enabled = false
	corpse.damage_region("head", 100)
	check(corpse.severed.is_empty() and corpse.joints.size() == 5, "gore off prevents severing")
	game.gore_enabled = true
	corpse.damage_region("left_arm", 20)
	check(not corpse.severed.has("left_arm"), "partial limb damage retains joint")
	corpse.bodies.left_arm.take_damage(20, Vector3.ZERO)
	check(corpse.severed.has("left_arm") and corpse.joints.size() == 4, "corpse hits break the actual arm joint")
	check(corpse.bodies.left_arm.has_node("CutSurface") and corpse.bodies.torso.has_node("CutSurface"), "both separated ends have cut surfaces")
	check(not corpse.sever("left_arm") and corpse.joints.size() == 4, "repeat severing is idempotent")
	var offset: Vector3 = corpse.bodies.left_arm.global_position - corpse.bodies.torso.global_position
	for i in 30: await physics_frame
	check((corpse.bodies.left_arm.global_position - corpse.bodies.torso.global_position).distance_to(offset) > .2, "severed arm moves independently")
	var visual = corpse.find_child("OperatorVisual", true, false)
	var bone: int = visual.skeleton.find_bone("hand_L")
	visual.skeleton.force_update_all_bone_transforms()
	var actual: Transform3D = visual.skeleton.global_transform * visual.skeleton.get_bone_global_pose(bone)
	var expected: Transform3D = corpse.bodies.left_arm.global_transform * visual.bindings[bone].offset
	check(actual.origin.distance_to(expected.origin) < .2, "visible hand follows severed arm")
	corpse.settle()
	check(corpse.sever("head") and not corpse.bodies.head.freeze and corpse.active, "settled corpse can release a newly severed part")
	game.pause_game()
	var pos: Vector3 = corpse.bodies.head.global_position
	for i in 5: await physics_frame
	check(corpse.bodies.head.global_position == pos, "pause freezes detached parts")
	game.resume_game()
	corpse.damage_region("torso", 1000)
	check(not corpse.severed.has("torso"), "torso stays intact")
	var query := PhysicsRayQueryParameters3D.create(corpse.bodies.right_arm.global_position + Vector3(0,0,-2), corpse.bodies.right_arm.global_position, 16)
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.collider.has_method("take_damage"), "actual raycast resolves damageable corpse body")
	game.start_run(true)
	await process_frame
	check(not is_instance_valid(corpse), "restart cleans up all detached parts and surfaces")
	var target = game.spawn_enemy("elite", Vector3(5,0.1,25))
	target.set_physics_process(false)
	game.is_test = false
	target.take_damage(10000, target.global_position + Vector3(0,1.7,0), true, true)
	game.is_test = true
	check(game.corpses.back().severed.has("head"), "lethal head hit dismembers human elite")
	var kills: int = game.kills
	game.corpses.back().damage_region("left_leg", 100)
	check(game.kills == kills, "corpse dismemberment cannot issue another kill reward")
	game.gore_enabled = false
	var clean_target = game.spawn_enemy("rusher", Vector3(7,0.1,25))
	game.is_test = false
	clean_target.take_damage(10000, clean_target.global_position + Vector3(0,1.7,0), true, true)
	game.is_test = true
	check(game.corpses.back().severed.is_empty(), "gore off leaves lethal-hit corpses intact")
	game.sound.stop_all()
	game.free()
	await process_frame
	print("DISMEMBERMENT RESULT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
