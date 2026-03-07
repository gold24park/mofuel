shader_type canvas_item;

uniform float skew : hint_range(-0.5, 0.5) = 0.12;
uniform vec4 tint : source_color = vec4(0.8, 0.2, 0.2, 0.95);

void fragment() {
	float shifted_x = UV.x + skew * (UV.y - 0.5);
	if (shifted_x < 0.0 || shifted_x > 1.0) {
		COLOR = vec4(0.0);
	} else {
		float tex_a = texture(TEXTURE, vec2(shifted_x, UV.y)).a;
		COLOR = vec4(tint.rgb, tex_a * tint.a);
	}
}
