extends Node3D
## Six regional bodies with breakable attachments and capped corpse lifetime.

const REGIONS := {
	"torso": {"center": Vector3(0, 1.08, 0), "size": Vector3(0.60, 0.66, 0.36), "mass": 25.0},
	"head": {"center": Vector3(0, 1.62, 0), "size": Vector3(0.34, 0.34, 0.32), "mass": 5.0},
	"left_arm": {"center": Vector3(-0.43, 1.08, 0), "size": Vector3(0.20, 0.55, 0.23), "mass": 4.0},
	"right_arm": {"center": Vector3(0.43, 1.08, 0), "size": Vector3(0.20, 0.55, 0.23), "mass": 4.0},
	"left_leg": {"center": Vector3(-0.18, 0.37, 0), "size": Vector3(0.23, 0.69, 0.26), "mass": 8.5},
	"right_leg": {"center": Vector3(0.18, 0.37, 0), "size": Vector3(0.23, 0.69, 0.26), "mass": 8.5}
}
const ANCHORS := {"head": Vector3(0, 1.44, 0), "left_arm": Vector3(-0.33, 1.31, 0), "right_arm": Vector3(0.33, 1.31, 0), "left_leg": Vector3(-0.18, 0.74, 0), "right_leg": Vector3(0.18, 0.74, 0)}
var game
var region_joints: Dictionary = {}
var cut_offsets: Dictionary = {}
var severed: Dictionary = {}
var damage: Dictionary = {}
var wound_material: StandardMaterial3D
var bodies: Dictionary = {}
var joints: Array[PinJoint3D] = []
var active: bool = true
var age: float = 0

func setup(source: Node3D, launch_velocity: Vector3) -> void:
	add_to_group("corpse")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var pose := source.global_transform
	var body_scale := pose.basis.get_scale().abs()
	for region in REGIONS:
		var definition: Dictionary = REGIONS[region]
		var part := preload("res://scripts/corpse_part.gd").new()
		part.corpse = self
		part.region = region
		part.name = region
		part.mass = definition.mass
		part.collision_layer = 16
		part.collision_mask = 1
		part.continuous_cd = true
		part.linear_damp = 0.35
		part.angular_damp = 1.5
		var physics_material := PhysicsMaterial.new()
		physics_material.friction = 0.8
		physics_material.bounce = 0
		part.physics_material_override = physics_material
		add_child(part)
		part.global_transform = Transform3D(pose.basis.orthonormalized(), pose * definition.center)
		part.force_update_transform()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = definition.size * body_scale
		collider.shape = shape
		part.add_child(collider)
		bodies[region] = part
	# Transfer the existing visual pose, including the visor, boots, and held gear.
	# Keep the first skeletal elite's frozen pose attached to the torso proxy.
	# Full per-bone physical animation remains a later character-art milestone.
	for visual in source.get_children():
		if visual.has_method("attach_to_ragdoll"):
			visual.attach_to_ragdoll(self, bodies)
			continue
		if visual.has_method("freeze_pose"):
			visual.freeze_pose()
			visual.reparent(bodies.torso, true)
		if not visual is MeshInstance3D:
			continue
		var region := "torso"
		if visual.position.y > 1.43:
			region = "head"
		elif visual.position.y < 0.72:
			region = "left_leg" if visual.position.x < 0 else "right_leg"
		elif absf(visual.position.x) > 0.32:
			region = "left_arm" if visual.position.x < 0 else "right_arm"
		visual.reparent(bodies[region], true)
	for region in ANCHORS:
		var joint := PinJoint3D.new()
		add_child(joint)
		joint.global_position = pose * ANCHORS[region]
		joint.force_update_transform()
		joint.node_a = joint.get_path_to(bodies.torso)
		joint.node_b = joint.get_path_to(bodies[region])
		joint.exclude_nodes_from_collision = true
		joint.set_param(PinJoint3D.PARAM_BIAS, 0.25)
		joint.set_param(PinJoint3D.PARAM_DAMPING, 1.0)
		joints.append(joint)
		region_joints[region] = joint
		cut_offsets[region] = [bodies.torso.to_local(joint.global_position), bodies[region].to_local(joint.global_position)]
	# The entire articulated body collides with the world, never the moving player.
	for part in bodies.values():
		for other in bodies.values():
			if other != part:
				part.add_collision_exception_with(other)
		part.apply_central_impulse(launch_velocity.limit_length(3) * part.mass * (1.0 if part == bodies.torso else 0.4))

func _physics_process(delta: float) -> void:
	if not active:
		return
	age += delta
	for part in bodies.values():
		part.linear_velocity = part.linear_velocity.limit_length(9)
		part.angular_velocity = part.angular_velocity.limit_length(8)
	if age >= 6.0:
		settle()

func settle() -> void:
	if not active:
		return
	active = false
	for part in bodies.values():
		part.linear_velocity = Vector3.ZERO
		part.angular_velocity = Vector3.ZERO
		part.freeze = true
	set_physics_process(false)

func region_at(point: Vector3) -> String:
	if point.y > 1.43: return "head"
	if point.y < 0.75: return "left_leg" if point.x < 0 else "right_leg"
	if absf(point.x) > 0.23: return "left_arm" if point.x < 0 else "right_arm"
	return "torso"

func damage_region(region: String, amount: float) -> void:
	if game == null or not game.gore_enabled or region == "torso" or severed.has(region): return
	damage[region] = damage.get(region, 0.0) + maxf(amount, 0)
	if damage[region] >= 35: sever(region)

func sever(region: String) -> bool:
	if game == null or not game.gore_enabled or not region_joints.has(region) or severed.has(region): return false
	var part: RigidBody3D = bodies[region]
	var joint: PinJoint3D = region_joints[region]
	var cut: Vector3 = part.to_global(cut_offsets[region][1])
	joints.erase(joint)
	region_joints.erase(region)
	joint.free()
	severed[region] = true
	# Both open ends travel with their respective body, not a world-space decal.
	var axis: Vector3 = (part.global_position - bodies.torso.global_position).normalized()
	_add_cut(bodies.torso, bodies.torso.to_global(cut_offsets[region][0]), axis, region)
	_add_cut(part, cut, -axis, region)
	if not active:
		var active_others := 0
		for other in game.corpses:
			if is_instance_valid(other) and other != self and other.active: active_others += 1
		for other in game.corpses:
			if active_others < game.MAX_ACTIVE_RAGDOLLS: break
			if is_instance_valid(other) and other != self and other.active:
				other.settle()
				active_others -= 1
		active = true
		age = 0
		set_physics_process(true)
		for visual in get_children():
			if visual.has_method("attach_to_ragdoll"): visual.set_physics_process(true)
	part.freeze = false
	part.sleeping = false
	part.apply_central_impulse((axis * 2.0 + Vector3.UP * 1.5) * part.mass)
	part.apply_torque_impulse(Vector3(0.5, 0.3, 0.8) * part.mass)
	game.impact(cut, Color("7b211c"), 8)
	return true

func _add_cut(parent: RigidBody3D, point: Vector3, axis: Vector3, region: String) -> void:
	if wound_material == null:
		wound_material = StandardMaterial3D.new()
		wound_material.albedo_color = Color("6b221e")
		wound_material.roughness = 0.8
	var cap := MeshInstance3D.new()
	cap.name = "CutSurface"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.065 if region == "head" else (0.085 if "leg" in region else 0.065)
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.018
	mesh.radial_segments = 12
	cap.mesh = mesh
	cap.material_override = wound_material
	parent.add_child(cap)
	cap.global_position = point
	cap.global_basis = Basis(Quaternion(Vector3.UP, axis))
