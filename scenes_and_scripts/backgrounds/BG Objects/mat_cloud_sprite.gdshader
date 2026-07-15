shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_never, shadows_disabled;

uniform sampler2D cloud_texture : source_color, filter_nearest;
uniform vec4 cloud_tint : source_color = vec4(0.875, 0.518, 0.647, 1.0);
uniform float base_glow : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec4 tex = texture(cloud_texture, UV);
	ALBEDO = tex.rgb * COLOR.rgb * cloud_tint.rgb;
	EMISSION = ALBEDO * base_glow;
	ALPHA = tex.a * cloud_tint.a * COLOR.a;
}

void light() {
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR / PI;
}
