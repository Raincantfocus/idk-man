shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Authored UV mask: RGB are garment color regions. No procedural pattern/noise.
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_map : filter_linear_mipmap_anisotropic;
uniform sampler2D camo_mask : filter_linear_mipmap_anisotropic;
instance uniform vec4 primary_color : source_color, instance_index(0) = vec4(0.25,0.30,0.18,1.0);
instance uniform vec4 secondary_color : source_color, instance_index(1) = vec4(0.12,0.16,0.10,1.0);
instance uniform vec4 tertiary_color : source_color, instance_index(2) = vec4(0.40,0.37,0.25,1.0);
// Authored masks only: no synthesized cloth, skin or camouflage noise.
// surface RGB: skin, camouflage, role accent. detail RGBA: crease dirt,
// contact-edge wear, reserved, metallic eligibility (zero on cloth/polymer/skin).
uniform bool variation_masks_enabled = false;
uniform sampler2D surface_mask : filter_linear_mipmap_anisotropic;
uniform sampler2D detail_mask : filter_linear_mipmap_anisotropic;
uniform sampler2DArray camo_patterns : filter_linear_mipmap_anisotropic;
uniform int camo_layer_count = 6;
instance uniform vec4 skin_tone : source_color, instance_index(3) = vec4(1.0);
instance uniform vec4 role_accent : source_color, instance_index(4) = vec4(1.0);
instance uniform float dirt_amount : instance_index(5) = 0.0;
instance uniform float wear_amount : instance_index(6) = 0.0;
instance uniform int camo_layer : instance_index(7) = 0;
uniform float metallic_allowed : hint_range(0.0,1.0) = 0.0;
void fragment() {
 vec3 source=texture(albedo_map,UV).rgb;
 vec3 mask=texture(camo_mask,UV).rgb;
 vec3 regions=vec3(0.0);
 vec4 details=vec4(0.0);
 if (variation_masks_enabled) {
  regions=clamp(texture(surface_mask,UV).rgb,vec3(0.0),vec3(1.0));
  regions/=max(1.0,regions.r+regions.g+regions.b);
  details=texture(detail_mask,UV);
  mask=texture(camo_patterns,vec3(UV,float(clamp(camo_layer,0,max(0,camo_layer_count-1))))).rgb*regions.g;
 }
 float total=max(1.0,mask.r+mask.g+mask.b);
 mask/=total;
 vec3 tint=vec3(max(0.0,1.0-mask.r-mask.g-mask.b))+mask.r*primary_color.rgb+mask.g*secondary_color.rgb+mask.b*tertiary_color.rgb;
 ALBEDO=source*tint;
 if (variation_masks_enabled) {
  ALBEDO*=mix(vec3(1.0),skin_tone.rgb,regions.r);
  ALBEDO*=mix(vec3(1.0),role_accent.rgb,regions.b);
  ALBEDO*=mix(vec3(1.0),vec3(0.24,0.20,0.15),details.r*clamp(dirt_amount,0.0,1.0));
  ALBEDO=mix(ALBEDO,ALBEDO*1.2,details.g*clamp(wear_amount,0.0,1.0));
 }
 NORMAL_MAP=texture(normal_map,UV).rgb;
 vec3 orm=texture(orm_map,UV).rgb;
 AO=orm.r;
 ROUGHNESS=clamp(orm.g,0.04,1.0);
 METALLIC=orm.b*metallic_allowed;
 if (variation_masks_enabled) {
  METALLIC*=details.a*(1.0-regions.r);
  ROUGHNESS=clamp(ROUGHNESS+details.r*dirt_amount*0.15,0.04,1.0);
 }
}
