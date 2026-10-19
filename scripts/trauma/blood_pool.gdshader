shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
uniform sampler2D pigment : source_color;
instance uniform float pool_age=0.0;
void fragment(){vec4 p=texture(pigment,UV);ALBEDO=p.rgb*(1.0-.4*clamp(pool_age/60.0,0.0,1.0));ALPHA=p.a;ROUGHNESS=mix(.12,.65,clamp(pool_age/60.0,0.0,1.0));METALLIC=0.0;}
