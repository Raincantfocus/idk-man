shader_type spatial;
render_mode cull_back, depth_draw_opaque;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_disable;
uniform sampler2D orm_map : filter_linear_mipmap, repeat_disable;
uniform sampler2D height_map : filter_linear_mipmap, repeat_disable;
uniform float parallax_depth = 0.075;
uniform int parallax_steps = 12;
void fragment() {
 vec3 view_tangent=vec3(dot(VIEW,TANGENT),dot(VIEW,BINORMAL),dot(VIEW,NORMAL));
 // Fade grazing-angle displacement rather than letting the UV leave the patch.
 float facing=abs(view_tangent.z);
 vec2 stride=view_tangent.xy/max(facing,0.25)*parallax_depth*smoothstep(0.12,0.4,facing)/float(parallax_steps);
 vec2 coord=UV;
 float layer=0.0;
 for(int i=0;i<24;i++) {
  if(i>=parallax_steps || layer>=1.0-texture(height_map,coord).r) { break; }
  coord-=stride;
  layer+=1.0/float(parallax_steps);
 }
 vec4 color=texture(albedo_map,coord);
 if(any(lessThan(coord,vec2(0.0))) || any(greaterThan(coord,vec2(1.0))) || color.a<0.35) { discard; }
 vec3 orm=texture(orm_map,coord).rgb;
 ALBEDO=color.rgb;
 ROUGHNESS=orm.g;
 METALLIC=orm.b;
 AO=orm.r;
 NORMAL_MAP=texture(normal_map,coord).rgb;
 NORMAL_MAP_DEPTH=1.0;
}
