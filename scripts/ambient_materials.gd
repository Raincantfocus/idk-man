extends RefCounted
const SETS = {"concrete":"Concrete013", "steel":"Metal029", "cloth":"Fabric019", "plastic":"Plastic006", "leather":"Leather026", "tile_rivet_panels":"Concrete047A", "tile_painted_gun_metal":"CorrugatedSteel005", "tile_default_metal":"Metal029", "tile_simple_floor":"Concrete034", "tile_tech_panels":"CorrugatedSteel005", "tile_anti_slip":"DiamondPlate008C", "mid_cargo_box":"Plastic006"}
static func make(stem: String, scale: float=1.0) -> StandardMaterial3D:
 var material:=StandardMaterial3D.new()
 var path: String="res://assets/ambientcg/"+String(SETS[stem])+"/"
 material.resource_name=String(SETS[stem])
 material.albedo_texture=load(path+"albedo.png")
 material.albedo_color=Color(.48,.48,.48) if String(SETS[stem]).begins_with("Concrete") else Color(.7,.7,.7)
 material.normal_enabled=true;material.normal_texture=load(path+"normal.png");material.normal_scale=.3
 var orm: Texture2D=load(path+"orm.png")
 material.ao_enabled=true;material.ao_texture=orm;material.ao_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
 material.roughness_texture=orm;material.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN
 material.metallic=1;material.metallic_texture=orm;material.metallic_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_BLUE
 material.uv1_triplanar=true;material.uv1_scale=Vector3.ONE*maxf(scale,.5)
 material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
 return material
