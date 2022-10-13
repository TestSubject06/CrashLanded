shader_type canvas_item;
uniform float time_scale;
render_mode blend_add;

void fragment() {
	float strength = texture(TEXTURE, UV).r;
	
	COLOR = vec4(
		(strength*1.0),
		(strength*1.5) * time_scale,
		0,
		smoothstep(0.4, 1, pow(strength+0.1, 0.5))
	);
}