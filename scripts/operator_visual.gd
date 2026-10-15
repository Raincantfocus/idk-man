extends Node3D
## Original 15-bone armored humanoids; animation never moves the gameplay capsule.
const MODELS := {"elite": preload("res://assets/operators/elite.glb"),"enforcer": preload("res://assets/operators/enforcer.glb"), "rusher": preload("res://assets/operators/rusher.glb"), "shield": preload("res://assets/operators/shield.glb"), "flusher": preload("res://assets/operators/flusher.glb")}
const COLORS := {"elite": Color("554b44"),"enforcer": Color("6b7566"), "rusher": Color("91664d"), "shield": Color("53717e"), "flusher": Color("93834a")}
var skeleton: Skeleton3D
var kind := "enforcer"
var phase := 0.0
var idle_clock := 0.0
var blend := 0.0
var hit_blend := 0.0
var attack_time := 0.0
var warning := 0.0
var frozen := false
var current_pose := "idle"
var rest: Array[Transform3D] = []
var global_rest: Array[Transform3D] = []
var names: Array[String] = []
var visor_material := StandardMaterial3D.new()
var bindings: Dictionary = {}
var owned_materials: Array[Material] = []

func setup(archetype: String) -> void:
	kind = archetype
	name = "OperatorVisual"
	var model: Node3D = MODELS[kind].instantiate()
	add_child(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	for i in skeleton.get_bone_count():
		rest.append(skeleton.get_bone_rest(i))
		global_rest.append(skeleton.get_bone_global_rest(i))
		names.append(skeleton.get_bone_name(i))
	visor_material.albedo_color = Color("e99857")
	visor_material.emission_enabled = true
	visor_material.emission = Color("ff7c46")
	visor_material.emission_energy_multiplier = 0.3
	var armor := StandardMaterial3D.new()
	armor.albedo_color = COLORS[kind]
	armor.albedo_texture = preload("res://assets/industrial/tile_painted_gun_metal_albedo.png")
	armor.roughness_texture = preload("res://assets/industrial/tile_painted_gun_metal_orm.png")
	armor.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	armor.metallic = 0.55
	armor.roughness = 0.63
	armor.normal_enabled = true
	armor.normal_texture = preload("res://assets/industrial/tile_default_metal_normal.png")
	armor.normal_scale = 0.08
	armor.uv1_triplanar = true
	armor.uv1_scale = Vector3.ONE * 5
	var fabric := ShaderMaterial.new()
	fabric.shader = preload("res://assets/first_person/fabric.gdshader")
	fabric.set_shader_parameter("fabric_color", Color("333c36"))
	owned_materials.assign([armor, fabric])
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for i in mesh.mesh.get_surface_count():
			var mat: Material = mesh.mesh.surface_get_material(i)
			if mat.resource_name == "Armor": mesh.set_surface_override_material(i, armor)
			elif mat.resource_name == "Cloth": mesh.set_surface_override_material(i, fabric)
			elif mat.resource_name == "Visor": mesh.set_surface_override_material(i, visor_material)
			else: mesh.set_surface_override_material(i, mat)
	set_physics_process(false)
	update_pose(0, 0, false)
	add_to_group("animated_operator")

func set_windup(value: float) -> void:
	warning = clampf(value, 0, 1)
	visor_material.emission_energy_multiplier = 0.3 + warning * 3

func on_attack() -> void:
	attack_time = 0.22

func update_pose(dt: float, speed: float, staggered: bool) -> void:
	if frozen: return
	idle_clock += dt
	phase += dt * clampf(speed * 2.4, 0, 16)
	blend = move_toward(blend, clampf(speed / 3.0, 0, 1), dt * 6)
	hit_blend = move_toward(hit_blend, 1.0 if staggered else 0.0, dt * 9)
	attack_time = maxf(0, attack_time - dt)
	current_pose = "stagger" if staggered else ("attack" if attack_time > 0 else ("run" if speed > 0.4 else "idle"))
	var poses: Array[Transform3D] = []
	var stride := sin(phase) * blend
	for i in names.size():
		var bone := names[i]
		var rot := Vector3.ZERO
		var translation := Vector3.ZERO
		var side := 1.0 if bone.ends_with("_L") else -1.0
		if bone == "pelvis": translation.y = absf(sin(phase)) * 0.018 * blend
		elif bone == "torso":
			rot = Vector3(-0.10 * blend + 0.18 * hit_blend, 0.025 * stride, 0.08 * hit_blend)
			translation.y = sin(idle_clock * 2.4) * 0.004
		elif bone == "head": rot.x = -0.12 * hit_blend
		elif bone.begins_with("thigh_"): rot.x = stride * side * 0.48
		elif bone.begins_with("shin_"): rot.x = -maxf(0, -sin(phase) * side) * blend * 0.65
		elif bone.begins_with("foot_"): rot.x = -stride * side * 0.18
		elif bone.begins_with("upper_arm_"):
			rot.x = -stride * side * (0.30 if kind == "rusher" else 0.10)
			if bone.ends_with("_R"):
				rot.x += warning * 0.35 - sin(attack_time / 0.22 * PI) * (0.65 if kind in ["rusher", "shield"] else 0.08)
		elif bone.begins_with("forearm_"): rot.x = 0.10 * hit_blend
		# Convert a model-space joint rotation into the imported bone's axes.
		var local_basis := global_rest[i].basis.inverse() * Basis.from_euler(rot) * global_rest[i].basis
		var local := rest[i] * Transform3D(local_basis, Vector3.ZERO)
		local.origin += translation
		var parent := skeleton.get_bone_parent(i)
		var pose := poses[parent] * local if parent >= 0 else local
		poses.append(pose)
		skeleton.set_bone_global_pose_override(i, pose, 1.0, true)

func attach_to_ragdoll(corpse: Node3D, bodies: Dictionary) -> void:
	frozen = true
	current_pose = "ragdoll"
	skeleton.force_update_all_bone_transforms()
	for i in names.size():
		var bone := names[i]
		var region := "torso"
		if bone == "head": region = "head"
		elif "arm_" in bone or "hand_" in bone: region = "left_arm" if bone.ends_with("_L") else "right_arm"
		elif "thigh_" in bone or "shin_" in bone or "foot_" in bone: region = "left_leg" if bone.ends_with("_L") else "right_leg"
		var part: RigidBody3D = bodies[region]
		bindings[i] = {"body": part, "offset": part.global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_pose(i)}
	reparent(corpse, true)
	process_physics_priority = 1
	set_physics_process(true)

func _physics_process(_dt: float) -> void:
	var inverse := skeleton.global_transform.affine_inverse()
	var settled := true
	for i in bindings:
		var entry: Dictionary = bindings[i]
		var part: RigidBody3D = entry.body
		skeleton.set_bone_global_pose_override(i, inverse * part.global_transform * entry.offset, 1.0, true)
		settled = settled and part.freeze
	if settled: set_physics_process(false)
