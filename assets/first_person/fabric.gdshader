shader_type spatial;
render_mode diffuse_burley;
uniform vec4 fabric_color : source_color = vec4(0.18, 0.21, 0.15, 1.0);
void fragment() {
	vec2 weave_uv = UV * vec2(180.0, 90.0);
	float detail = clamp(1.0 - max(fwidth(weave_uv.x), fwidth(weave_uv.y)), 0.0, 1.0);
	float weave = sin(weave_uv.x * 6.28318) * sin(weave_uv.y * 6.28318);
	ALBEDO = fabric_color.rgb * (0.92 + 0.08 * weave * detail);
	ROUGHNESS = 0.94;
	METALLIC = 0.0;
}
