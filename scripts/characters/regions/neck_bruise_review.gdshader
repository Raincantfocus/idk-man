shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
// Review-only mask overlay. Source albedo remains the previous surface pass.
void fragment() {
 float band=1.0-smoothstep(0.035,0.13,abs(UV2.y-0.5));
 ALBEDO=vec3(0.16,0.018,0.028);
 ROUGHNESS=0.53;
 METALLIC=0.0;
 ALPHA=band*0.65;
}
