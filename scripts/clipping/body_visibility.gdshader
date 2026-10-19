shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
instance uniform float reveal : hint_range(0.0,1.0)=0.0;
instance uniform int reveal_regions=0;
instance uniform bool mask_view=false;
uniform vec4 diagnostic_skin : source_color=vec4(.62,.66,.68,1.0);
varying flat int region_id;
void vertex(){region_id=int(round(COLOR.g*31.0));}
void fragment(){
 bool region_revealed=(reveal_regions & (1<<region_id))!=0;
 if(!mask_view && reveal<0.5 && !region_revealed && COLOR.r>0.5){discard;}
 ALBEDO=mask_view ? mix(vec3(.05,.4,1.0),vec3(1.0,.15,.02),COLOR.r) : diagnostic_skin.rgb;
 ROUGHNESS=.65;METALLIC=0.0;
}
