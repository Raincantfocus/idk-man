extends RefCounted
## Shared PBR materials and curated, licensed static mesh instances.
const ROOT := "res://assets/industrial/"
const MODEL_NAMES := ["cargo_case_a", "cargo_case_b", "gas_cylinder", "industrial_drum", "safety_barrier"]
var models: Dictionary = {}
var materials: Dictionary = {}

func setup() -> void:
	for name in MODEL_NAMES:
		models[name] = load(ROOT + name + ".glb")

func pbr(stem: String, world_scale: float = 0.0) -> StandardMaterial3D:
	var key := stem + str(world_scale)
	if materials.has(key):
		return materials[key]
	if preload("ambient_materials.gd").SETS.has(stem):
		var replacement: StandardMaterial3D=preload("ambient_materials.gd").make(stem,world_scale)
		materials[key]=replacement
		return replacement
	var mat := StandardMaterial3D.new()
	mat.resource_name = stem
	mat.albedo_texture = load(ROOT + stem + "_albedo.png")
	mat.normal_enabled = true
	mat.normal_texture = load(ROOT + stem + "_normal.png")
	var orm: Texture2D = load(ROOT + stem + "_orm.png")
	mat.roughness_texture = orm
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	mat.metallic_texture = orm
	mat.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	mat.metallic = 0.7
	mat.ao_enabled = true
	mat.ao_texture = orm
	mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if world_scale > 0:
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
		mat.uv1_scale = Vector3.ONE * world_scale
	materials[key] = mat
	return mat

func add_model(parent: Node3D, model_name: String, foot: Vector3, size: Vector3) -> Node3D:
	var instance: Node3D = models[model_name].instantiate()
	parent.add_child(instance)
	var meshes: Array[Node] = instance.find_children("*", "MeshInstance3D", true, false)
	if instance is MeshInstance3D:
		meshes.append(instance)
	# Every curated GLB contains exactly one untransformed mesh with several surfaces.
	assert(meshes.size() == 1)
	var mesh: MeshInstance3D = meshes[0]
	var bounds := mesh.mesh.get_aabb()
	instance.scale = size / bounds.size
	instance.position = foot - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * instance.scale
	for surface in mesh.mesh.get_surface_count():
		var original := mesh.mesh.surface_get_material(surface)
		var mat: StandardMaterial3D = pbr("tile_default_metal" if model_name in ["gas_cylinder", "industrial_drum"] else "mid_cargo_box")
		if original != null and "emitter" in original.resource_name:
			mat = StandardMaterial3D.new()
			mat.albedo_color = Color("efb968")
			mat.emission_enabled = true
			mat.emission = mat.albedo_color
		elif original != null and "glass" in original.resource_name:
			mat = StandardMaterial3D.new()
			mat.albedo_color = Color("28363c")
			mat.metallic = 0.5
			mat.roughness = 0.3
		mesh.set_surface_override_material(surface, mat)
	instance.add_to_group("authored_prop")
	return instance
