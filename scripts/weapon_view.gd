extends Node3D
## Original multipart meshes with keyed reload poses on a four-bone arm rig.
const SCENES := [preload("res://assets/first_person/carbine.glb"), preload("res://assets/first_person/shotgun.glb"), preload("res://assets/first_person/sidearm.glb")]
const ARMS = preload("res://assets/first_person/operator_arms.glb")
const CasingScript = preload("res://scripts/shell_casing.gd")
const MAX_CASINGS := 12
const HIP := [Vector3(0.24, -0.25, -0.39), Vector3(0.25, -0.26, -0.38), Vector3(0.19, -0.23, -0.38)]
var player
var models: Array[Node3D] = []
var magazines: Array[Node3D] = []
var actions: Array[Node3D] = []
var triggers: Array[Node3D] = []
var muzzles: Array[Node3D] = []
var ejections: Array[Node3D] = []
var grips: Array[Node3D] = []
var sights: Array[Node3D] = []
var skeleton: Skeleton3D
var rest: Dictionary = {}
var index := 0
var action_time := 0.0
var equip_time := 0.0
var muzzle_flash := MeshInstance3D.new()
var material_refs: Array[Material] = []
var brass := StandardMaterial3D.new()

func setup(owner_player) -> void:
	player = owner_player
	for scene in SCENES:
		var model: Node3D = scene.instantiate()
		add_child(model)
		models.append(model)
		magazines.append(model.find_child("Magazine", true, false))
		actions.append(model.find_child("Action", true, false))
		triggers.append(model.find_child("Trigger", true, false))
		muzzles.append(model.find_child("MuzzleSocket", true, false))
		ejections.append(model.find_child("EjectionSocket", true, false))
		grips.append(model.find_child("SupportGrip", true, false))
		sights.append(model.find_child("SightLine", true, false))
	var arms: Node3D = ARMS.instantiate()
	add_child(arms)
	skeleton = arms.find_children("*", "Skeleton3D", true, false)[0]
	for bone in ["forearm_L", "hand_L", "forearm_R", "hand_R"]:
		var id := skeleton.find_bone(bone)
		rest[bone] = {"id": id, "pose": skeleton.get_bone_global_rest(id)}
	for mesh in find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Imported weapon, glove and sleeve materials remain authoritative.
	var flash_mesh := QuadMesh.new()
	flash_mesh.size = Vector2(0.17, 0.17)
	muzzle_flash.mesh = flash_mesh
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded, blend_add, cull_disabled, depth_draw_never; void fragment(){ vec2 p=UV*2.0-1.0; float r=length(p); float a=atan(p.y,p.x); float star=0.30+0.22*pow(abs(cos(a*3.0)),8.0); float glow=1.0-smoothstep(star*0.3,star,r); ALBEDO=vec3(1.0,0.64,0.20)*2.0; ALPHA=glow; }"
	var flash_mat := ShaderMaterial.new()
	flash_mat.shader = shader
	muzzle_flash.material_override = flash_mat
	muzzle_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(muzzle_flash)
	brass.albedo_color = Color("b79142")
	brass.metallic = 0.8
	brass.roughness = 0.32
	select_weapon(0, false)

func select_weapon(which: int, animate: bool = true) -> void:
	index = which
	action_time = 0
	equip_time = 0.20 if animate else 0.0
	for i in models.size():
		models[i].visible = i == index
		actions[i].position = Vector3.ZERO
		magazines[i].position = Vector3.ZERO
		triggers[i].position = Vector3.ZERO
	muzzle_flash.visible = false

func muzzle_position() -> Vector3:
	return muzzles[index].global_position

func ads_position() -> Vector3:
	return Vector3(0, -sights[index].position.y, HIP[index].z + 0.04)

func keyed(t: float, times: Array, values: Array) -> Vector3:
	for i in range(times.size() - 1):
		if t <= times[i + 1]:
			var f := smoothstep(float(times[i]), float(times[i + 1]), t)
			return (values[i] as Vector3).lerp(values[i + 1], f)
	return values.back()

func pose_arm(side: String, offset: Vector3, rotation: Vector3 = Vector3.ZERO) -> void:
	var fore: Dictionary = rest["forearm_" + side]
	var hand: Dictionary = rest["hand_" + side]
	var f: Transform3D = fore.pose
	var h: Transform3D = hand.pose
	var original := h.origin - f.origin
	var target := h.origin + offset - f.origin
	var swing := Basis(Quaternion(original.normalized(), target.normalized()))
	f.basis = swing * f.basis
	f.basis.y *= target.length() / maxf(original.length(), 0.001)
	h.origin += offset
	h.basis = Basis.from_euler(rotation) * h.basis
	skeleton.set_bone_global_pose_override(fore.id, f, 1.0, true)
	skeleton.set_bone_global_pose_override(hand.id, h, 1.0, true)

func update_pose(dt: float) -> void:
	action_time = maxf(0, action_time - dt)
	equip_time = maxf(0, equip_time - dt)
	var action_duration: float = 0.16 if index == 1 else 0.09
	var cycle := sin(clampf(action_time / action_duration, 0, 1) * PI)
	actions[index].position.z = cycle * (0.065 if index == 2 else 0.045)
	if index == 2 and player.ammo[index] == 0:
		actions[index].position.z = 0.045
	triggers[index].position.z = cycle * 0.005
	magazines[index].position = Vector3.ZERO
	magazines[index].visible = player.magazine_seated[index]
	var support := grips[index].position - Vector3(-0.035, -0.102, -0.38)
	var left_rotation := Vector3(0.8, 0, 0.3) if index == 2 else Vector3.ZERO
	if player.reload_time > 0:
		var progress: float = 1.0 - player.reload_time / player.reload_total
		var down := Vector3(-0.06, -0.34, 0.08)
		var mag_offset := keyed(progress, [0.0, 0.18, 0.28, 0.43, 0.57, 0.78, 1.0], [Vector3.ZERO, Vector3.ZERO, Vector3(0,-0.05,0), down, down, Vector3.ZERO, Vector3.ZERO])
		magazines[index].position = mag_offset
		magazines[index].visible = (progress < 0.43 and player.reload_had_magazine) or progress >= 0.57
		var grasp := Vector3(-0.025, -0.24, 0.01 if index == 2 else -0.13) - Vector3(-0.035, -0.102, -0.38)
		support = keyed(progress, [0.0, 0.18, 0.43, 0.57, 0.78, 0.92, 1.0], [support, grasp, grasp+down, grasp+down, grasp, support, support])
		left_rotation *= 1.0 - sin(progress * PI)
		if progress > 0.78:
			actions[index].position.z = (1.0 - smoothstep(0.78, 0.92, progress)) * 0.045 if index == 2 else sin((progress - 0.78) / 0.22 * PI) * 0.035
	if index == 1:
		magazines[1].visible = player.reload_time > 0
		magazines[1].position = Vector3.ZERO
		if player.reload_time > 0:
			var shell_progress: float = 1.0 - player.reload_time / player.reload_total
			var reach := Vector3(-0.025, -0.12, -0.12) - Vector3(-0.035, -0.102, -0.38)
			var travel := Vector3(0, -0.18, 0.08) * sin(shell_progress * PI)
			support = reach + travel
			magazines[1].position = travel
	pose_arm("L", support, left_rotation)
	pose_arm("R", Vector3(-0.015, 0.01, -0.025) if index == 2 else Vector3.ZERO)
	muzzle_flash.position = muzzles[index].position
	muzzle_flash.visible = player.muzzle_timer > 0
	muzzle_flash.rotation.z += dt * 34
	player.flash.position = muzzles[index].position

func on_fire() -> void:
	action_time = 0.16 if index == 1 else 0.09
	# Shells use their own deterministic cosmetic direction, never combat RNG.
	var casings := get_tree().get_nodes_in_group("shell_casing")
	if casings.size() >= MAX_CASINGS:
		casings[0].free()
	var casing = CasingScript.new()
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.006 if index != 1 else 0.009
	cylinder.bottom_radius = cylinder.top_radius
	cylinder.height = 0.025 if index != 1 else 0.045
	cylinder.radial_segments = 8
	mesh.mesh = cylinder
	mesh.material_override = brass
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	casing.add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = cylinder.top_radius
	shape.height = cylinder.height
	collider.shape = shape
	casing.add_child(collider)
	player.game.add_child(casing)
	casing.global_transform = ejections[index].global_transform
	casing.linear_velocity = player.camera.global_basis * Vector3(2.6, 1.4, 0.3) + player.velocity * 0.25
	casing.angular_velocity = Vector3(8, 13, 5)
