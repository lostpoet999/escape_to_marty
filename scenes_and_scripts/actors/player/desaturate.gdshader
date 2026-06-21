shader_type canvas_item;

uniform float desaturate_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 base = tex.rgb * COLOR.rgb;
	float lum = dot(base, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(base, vec3(lum), desaturate_amount), tex.a * COLOR.a);
}
