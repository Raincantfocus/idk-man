extends SceneTree
var passed: int = 0
var failed: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)
func node_at(point: Vector3) -> Node3D:
	var node := Node3D.new()
	root.add_child(node)
	node.position = point
	return node
func catalogue(count: int) -> ZLCosmeticCatalogue:
	var result := ZLCosmeticCatalogue.new()
	for i: int in count:
		var look := ZLCosmeticLook.new()
		look.look_id = StringName("fixture_"+str(i))
		look.role = &"enforcer"
		look.base_body_id = StringName("body_"+str(i%4))
		look.camo_id = StringName("camo_"+str(i%6))
		look.headgear_id = StringName("helmet_"+str(i/12))
		look.head_id = &"fixture_head"
		look.glove_id = &"fixture_gloves"
		look.boot_id = &"fixture_boots"
		look.sleeve_id = &"fixture_sleeves"
		look.kit_id = &"fixture_kit"
		look.part_ids = PackedStringArray(["fixture_part"])
		result.looks.append(look)
	return result
func run() -> void:
	check(ClassDB.class_has_method(&"GeometryInstance3D",&"set_instance_shader_parameter"),"4.6 instance parameter API exists")
	var catalog: ZLCosmeticCatalogue = catalogue(36)
	var selector := ZLCosmeticSelector.new()
	check(not selector.configure(catalog),"unfitted art fails production selection")
	check(selector.configure(catalog,true),"review fixture configures explicitly")
	var gameplay := RandomNumberGenerator.new()
	gameplay.seed = 17042
	var state: int = gameplay.state
	seed(7331)
	var next_global: int = randi()
	seed(7331)
	var owners: Array[Node3D] = []
	var keys: Array[String] = []
	var unique: Dictionary[String,bool] = {}
	for i: int in 20:
		var owner: Node3D = node_at(Vector3(i%4,0,i/4))
		owners.append(owner)
		var look: ZLCosmeticLook = selector.reserve(owner,&"enforcer")
		if look != null:
			keys.append(look.combination_key())
			unique[look.combination_key()] = true
	check(keys.size()==20 and unique.size()==20,"twenty clustered selections have distinct keys")
	check(gameplay.state==state and randi()==next_global,"gameplay and global RNG remain untouched")
	check(selector.reserve(owners[0],&"enforcer")==null,"duplicate owner rejected")
	var saved: Dictionary = selector.look_for(owners[0]).to_data()
	var edited: ZLCosmeticLook = selector.look_for(owners[0])
	edited.camo_id = &"edited"
	edited.part_ids[0] = "edited"
	check(selector.look_for(owners[0]).to_data()==saved,"caller cannot edit saved appearance")
	var corpse: Node3D = node_at(Vector3.ZERO)
	check(selector.transfer_to_corpse(owners[0],corpse).to_data()==saved,"corpse receives exact appearance")
	check(selector.look_for(owners[0])==null and selector.active_count()==20,"transfer does not add reservations")
	check(selector.transfer_to_corpse(owners[0],corpse)==null,"duplicate transfer rejected")
	check(ResourceSaver.save(selector.look_for(corpse),"user://look-test.tres")==OK,"Resource saves")
	var restored: ZLCosmeticLook = load("user://look-test.tres") as ZLCosmeticLook
	check(restored.to_data()==saved,"Resource restores exact appearance")
	check(JSON.parse_string(JSON.stringify(saved)).look_id==String(restored.look_id),"JSON retains identity")
	corpse.free()
	check(selector.active_count()==19,"corpse eviction retires reservation")
	for owner: Node3D in owners: owner.free()
	check(selector.active_count()==0,"despawn leaves no reservations")
	check(selector.configure(catalog,true),"reseed resets run")
	var replay: Array[String] = []
	for i: int in 20: replay.append(selector.reserve(node_at(Vector3(i%4,0,i/4)),&"enforcer").combination_key())
	check(replay==keys,"seeded replay matches exactly")
	var pair := ZLCosmeticSelector.new()
	pair.configure(catalogue(2),true)
	var a: Node3D = node_at(Vector3.ZERO)
	var b: Node3D = node_at(Vector3(30,0,0))
	var c: Node3D = node_at(Vector3(8,0,0))
	var first: ZLCosmeticLook = pair.reserve(a,&"enforcer")
	check(first.combination_key()!=pair.reserve(b,&"enforcer").combination_key(),"back-to-back exclusion applies at any distance")
	check(pair.reserve(c,&"enforcer")==null,"exact eight metre boundary excludes and exhausts")
	a.position.x = -0.01
	check(pair.reserve(c,&"enforcer").combination_key()==first.combination_key(),"moving owners update exclusion distance")
	pair.release(c)
	check(pair.look_for(c)==null,"pool reuse releases appearance")
	check(pair.reserve(c,&"flusher")==null,"unknown role cannot substitute another")
	var invalid: ZLCosmeticCatalogue = catalogue(2)
	invalid.looks[0].role = &"rusher"
	check(not pair.configure(invalid,true),"rusher cannot wear helmet")
	invalid.looks[0].role = &"enforcer"
	invalid.looks[0].build.w = 0.051
	check(not pair.configure(invalid,true),"height limited to five percent")
	check(pair.reserve(c,&"enforcer")==null,"failed reconfiguration disables allocation")
	for child: Node in root.get_children(): child.free()
	print("COSMETIC SELECTION RESULT: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
