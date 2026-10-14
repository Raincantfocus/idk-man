extends Node3D
## First skeletal enemy pass. Gameplay collision and AI remain on Enemy.
const MODEL = preload("res://assets/elite/elite.glb")
var animator: AnimationPlayer
var clips: Dictionary = {}
var current_clip := ""
var frozen := false
var material_refs: Array[Material] = []

func setup() -> void:
	name = "EliteVisual"
	var model := MODEL.instantiate()
	add_child(model)
	model.scale = Vector3.ONE * 1.15
	model.rotation.y = PI
	var armor := StandardMaterial3D.new()
	armor.albedo_color = Color("788992")
	armor.albedo_texture = preload("res://assets/elite/player_robot_albedo.png")
	armor.normal_enabled = true
	armor.normal_texture = preload("res://assets/elite/player_robot_normal.png")
	var orm := preload("res://assets/elite/player_robot_orm.png")
	armor.roughness_texture = orm
	armor.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	armor.metallic_texture = orm
	armor.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	armor.metallic = 0.8
	armor.emission_enabled = true
	armor.emission_texture = preload("res://assets/elite/player_robot_emissive.png")
	armor.emission = Color.WHITE
	armor.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	armor.emission_energy_multiplier = 0.4
	armor.ao_enabled = true
	armor.ao_texture = orm
	armor.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	armor.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var emitter := StandardMaterial3D.new()
	emitter.albedo_color = Color("fa7548")
	emitter.emission_enabled = true
	emitter.emission = Color("fa7548")
	material_refs.assign([armor, emitter])
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for i in mesh.mesh.get_surface_count():
			var original: Material = mesh.mesh.surface_get_material(i)
			mesh.set_surface_override_material(i, emitter if original != null and "emitter" in original.resource_name else armor)
	animator = model.find_children("*", "AnimationPlayer", true, false)[0]
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in animator.get_animation_list():
		for prefix in ["Idlecombat", "running_gun", "flinch1"]:
			if clip.begins_with(prefix):
				clips[prefix] = clip
				animator.get_animation(clip).loop_mode = Animation.LOOP_NONE if prefix == "flinch1" else Animation.LOOP_LINEAR
	update_pose(0, 0, false)
	add_to_group("animated_elite")

func update_pose(dt: float, speed: float, staggered: bool) -> void:
	if frozen:
		return
	var desired := "flinch1" if staggered else ("running_gun" if speed > 0.4 else "Idlecombat")
	if desired != current_clip:
		current_clip = desired
		animator.play(clips[desired], 0.12)
	animator.speed_scale = clampf(speed / 4.0, 0.7, 1.8) if desired == "running_gun" else 1.0
	animator.advance(dt)

func freeze_pose() -> void:
	frozen = true

func set_windup(value: float) -> void:
	(material_refs[1] as StandardMaterial3D).emission_energy_multiplier = 1.0 + clampf(value, 0, 1) * 2.0
