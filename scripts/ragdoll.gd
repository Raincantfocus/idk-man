extends Node3D
## Six connected rigid-body proxies. Phase 1 physics, no dismemberment or gore.

const REGIONS := {
	"torso": {"center": Vector3(0, 1.08, 0), "size": Vector3(0.60, 0.66, 0.36), "mass": 25.0},
	"head": {"center": Vector3(0, 1.62, 0), "size": Vector3(0.34, 0.34, 0.32), "mass": 5.0},
	"left_arm": {"center": Vector3(-0.43, 1.08, 0), "size": Vector3(0.20, 0.55, 0.23), "mass": 4.0},
	"right_arm": {"center": Vector3(0.43, 1.08, 0), "size": Vector3(0.20, 0.55, 0.23), "mass": 4.0},
	"left_leg": {"center": Vector3(-0.18, 0.37, 0), "size": Vector3(0.23, 0.69, 0.26), "mass": 8.5},
	"right_leg": {"center": Vector3(0.18, 0.37, 0), "size": Vector3(0.23, 0.69, 0.26), "mass": 8.5}
}
const ANCHORS := {"head": Vector3(0, 1.44, 0), "left_arm": Vector3(-0.33, 1.31, 0), "right_arm": Vector3(0.33, 1.31, 0), "left_leg": Vector3(-0.18, 0.74, 0), "right_leg": Vector3(0.18, 0.74, 0)}
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
		var part := RigidBody3D.new()
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
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = definition.size * body_scale
		collider.shape = shape
		part.add_child(collider)
		bodies[region] = part
	# Transfer the existing visual pose, including the visor, boots, and held gear.
	for visual in source.get_children():
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
		joint.node_a = joint.get_path_to(bodies.torso)
		joint.node_b = joint.get_path_to(bodies[region])
		joint.exclude_nodes_from_collision = true
		joint.set_param(PinJoint3D.PARAM_BIAS, 0.25)
		joint.set_param(PinJoint3D.PARAM_DAMPING, 1.0)
		joints.append(joint)
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
