shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0, 1.0) = 1.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 ps = TEXTURE_PIXEL_SIZE * outline_width;

	float a = texture(TEXTURE, UV + vec2(-ps.x, 0.0)).a;
	a += texture(TEXTURE, UV + vec2(ps.x, 0.0)).a;
	a += texture(TEXTURE, UV + vec2(0.0, -ps.y)).a;
	a += texture(TEXTURE, UV + vec2(0.0, ps.y)).a;
	a = min(a, 1.0);

	COLOR = mix(vec4(outline_color.rgb, outline_color.a * a), col, col.a);
}
