shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_never, shadows_disabled;

uniform sampler2D cloud_texture : source_color, filter_linear;
uniform float core_opacity : hint_range(0.0, 1.0) = 0.95;
uniform float feather : hint_range(0.5, 8.0) = 2.0;
uniform float base_glow : hint_range(0.0, 1.0) = 0.35;
uniform float scatter : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	float density = pow(texture(cloud_texture, UV).a, feather);
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * base_glow;
	ALPHA = core_opacity * density * COLOR.a;
}

void light() {
	float facing = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float translucent = mix(facing, 1.0, scatter);
	DIFFUSE_LIGHT += translucent * ATTENUATION * LIGHT_COLOR / PI;
}
