shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
instance uniform float wet_front : hint_range(0.0,1.0)=0.0;
instance uniform float age : hint_range(0.0,120.0)=0.0;
instance uniform vec3 wound_origin=vec3(0.0);
varying vec3 world_point;
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;VERTEX+=NORMAL*.00012;}
void fragment(){
 float down=wound_origin.y-world_point.y;
 float front=wet_front*.12;
 float below=smoothstep(-.002,.002,down)*(1.0-smoothstep(front-.01,front,down));
 float streak=pow(.5+.5*sin(world_point.x*430.0+sin(down*30.0)),6.0);
 float source=exp(-pow((abs(world_point.x-wound_origin.x)-.023)/.022,2.0));
 ALBEDO=mix(vec3(.065,.009,.012),vec3(.035,.015,.012),clamp(age/90.0,0.0,1.0));
 ALPHA=below*source*(.25+.55*streak);ROUGHNESS=mix(.14,.62,clamp(age/90.0,0.0,1.0));METALLIC=0.0;
}
