shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_never, shadows_disabled, unshaded;

uniform vec4 cloud_color : source_color = vec4(0.847, 0.824, 1.0, 1.0);
uniform float core_opacity : hint_range(0.0, 1.0) = 0.9;
uniform float feather : hint_range(0.5, 8.0) = 3.0;

void fragment() {
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float density = pow(facing, feather);

	ALBEDO = cloud_color.rgb;
	ALPHA = core_opacity * density;
}
