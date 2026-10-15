extends RefCounted
## Original 2K tileable PBR maps, shared textures with per-instance tint.
static func make(stem: String, tint: Color = Color.WHITE, scale: float = 3.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var root := "res://assets/surfaces/" + stem
	mat.resource_name = stem + "_pbr"
	mat.albedo_color = tint
	mat.albedo_texture = load(root + "_albedo.png")
	mat.normal_enabled = true
	mat.normal_texture = load(root + "_normal.png")
	mat.normal_scale = 0.35
	var orm: Texture2D = load(root + "_orm.png")
	mat.ao_enabled = true
	mat.ao_texture = orm
	mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.roughness_texture = orm
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	mat.metallic_texture = orm
	mat.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	mat.metallic = 1
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * scale
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat
