shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform float pixelate_size : hint_range(1, 128) = 20.0;
uniform float reference_height : hint_range(480, 4320) = 1280.0;
uniform float color_levels : hint_range(1, 32) = 8.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.5;

// 4x4 Bayer matrix — bit-interleave(x^y, y) 공식
float bayer4(vec2 pos) {
	ivec2 p = ivec2(mod(floor(pos), 4.0));
	int xo = p.x ^ p.y;
	int val = (xo & 1) * 8 + (p.y & 1) * 4 + ((xo >> 1) & 1) * 2 + ((p.y >> 1) & 1);
	return float(val) / 16.0;
}

void fragment() {
	// Pixelation (resolution-independent)
	float block_size = pixelate_size / reference_height;
	vec2 block_uv = block_size * vec2(SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y, 1.0);
	vec2 snapped_uv = floor(SCREEN_UV / block_uv) * block_uv;

	vec4 color = texture(SCREEN_TEXTURE, snapped_uv);

	// Bayer dithering + color quantization (PS1의 15-bit 컬러 + 디더링)
	vec2 pixel_coord = floor(SCREEN_UV / block_uv);
	float threshold = bayer4(pixel_coord);
	float offset = (threshold - 0.5) * dither_strength / color_levels;
	color.rgb = floor((color.rgb + offset) * color_levels) / color_levels;

	COLOR = color;
}
