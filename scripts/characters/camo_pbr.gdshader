shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Authored UV mask: RGB are garment color regions. No procedural pattern/noise.
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_map : filter_linear_mipmap_anisotropic;
uniform sampler2D camo_mask : filter_linear_mipmap_anisotropic;
uniform vec4 primary_color : source_color = vec4(0.25,0.30,0.18,1.0);
uniform vec4 secondary_color : source_color = vec4(0.12,0.16,0.10,1.0);
uniform vec4 tertiary_color : source_color = vec4(0.40,0.37,0.25,1.0);
uniform float metallic_allowed : hint_range(0.0,1.0) = 0.0;
void fragment() {
 vec3 source=texture(albedo_map,UV).rgb;
 vec3 mask=texture(camo_mask,UV).rgb;
 float total=max(1.0,mask.r+mask.g+mask.b);
 mask/=total;
 vec3 tint=vec3(max(0.0,1.0-mask.r-mask.g-mask.b))+mask.r*primary_color.rgb+mask.g*secondary_color.rgb+mask.b*tertiary_color.rgb;
 ALBEDO=source*tint;
 NORMAL_MAP=texture(normal_map,UV).rgb;
 vec3 orm=texture(orm_map,UV).rgb;
 AO=orm.r;
 ROUGHNESS=clamp(orm.g,0.04,1.0);
 METALLIC=orm.b*metallic_allowed;
}
