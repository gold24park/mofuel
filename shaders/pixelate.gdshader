shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform float pixelate_size : hint_range(1, 128) = 20.0;
uniform float reference_height : hint_range(480, 4320) = 1280.0;
uniform float color_levels : hint_range(1, 32) = 8.0;

void fragment() {
    // Pixelation (resolution-independent)
    vec2 screen_uv = SCREEN_UV;
    float block_size = pixelate_size / reference_height;
    vec2 block_uv = block_size * vec2(SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y, 1.0);
    vec2 snapped_uv = floor(screen_uv / block_uv) * block_uv;

    // Get the pixelated color
    vec4 color = texture(SCREEN_TEXTURE, snapped_uv);

    // Color Quantization
    color.rgb = floor(color.rgb * color_levels) / color_levels;

    COLOR = color;
}
