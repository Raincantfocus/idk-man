shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D normal_atlas : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D orm_atlas : filter_linear_mipmap, repeat_disable;
uniform sampler2D flow_atlas : filter_linear_mipmap, repeat_disable;
instance uniform float blood_fill : hint_range(0.0,1.0)=0.45;
instance uniform float wetness : hint_range(0.0,1.0)=0.85;
instance uniform float dried_edge : hint_range(0.0,1.0)=0.0;
instance uniform float age : hint_range(0.0,120.0)=0.0;
instance uniform float wet_front : hint_range(0.0,1.0)=0.0;
instance uniform float underside : hint_range(0.0,1.0)=0.0;
void vertex(){
 float baseline=(COLOR.a-.5)*.02;
 VERTEX.y=baseline+(VERTEX.y-baseline)*(1.0-2.0*underside);
 NORMAL.y*=1.0-2.0*underside;
 TANGENT.y*=1.0-2.0*underside;
 BINORMAL.y*=1.0-2.0*underside;
}
instance uniform bool fragment_cap=false;
void fragment(){
 vec3 tissue=texture(albedo_atlas,UV).rgb;
 if(fragment_cap){
  vec2 tile=fract(UV*4.0);
  vec3 bone=texture(albedo_atlas,vec2(tile.x/4.0,(tile.y+1.0)/4.0)).rgb;
  tissue=mix(tissue,bone,smoothstep(.25,.95,COLOR.g));
 }
 vec3 orm=texture(orm_atlas,UV).rgb;
 vec3 flow=texture(flow_atlas,UV).rgb;
 float cavity=clamp(COLOR.r,0.0,1.0);
 float dry=clamp(dried_edge+age/100.0,0.0,1.0);
 float pool=smoothstep(0.22,0.85,cavity)*blood_fill;
 // A frozen age value freezes flow during pause/Focus; TIME is not used.
 float rivulet=pow(flow.b,12.0)*smoothstep(0.1,0.8,COLOR.g)*wet_front;
 float wet=clamp(wetness*(1.0-dry*.7)+pool*.25,0.0,1.0);
 ALBEDO=mix(tissue,vec3(.055,.006,.009),clamp(pool*.8+rivulet*.4,0.0,.85));
 ALBEDO*=1.0-dry*.20;
 METALLIC=0.0;ROUGHNESS=mix(clamp(orm.g+dry*.22,.18,.85),.13,wet*.65);
 SPECULAR=.55;AO=mix(1.0,.7,cavity);
 NORMAL_MAP=texture(normal_atlas,UV).rgb;NORMAL_MAP_DEPTH=.35;
 // Low-cost skin/fat wrap approximation; no claim of volumetric scattering.
 BACKLIGHT=ALBEDO*.08*(1.0-cavity);
}
