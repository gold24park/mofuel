shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform float pixelate_size : hint_range(1, 128) = 8.0;
uniform float color_levels : hint_range(1, 32) = 8.0;

void fragment() {
    // Pixelation
    vec2 screen_uv = SCREEN_UV;
    vec2 pixel_uv_size = SCREEN_PIXEL_SIZE;
    vec2 snapped_uv = floor(screen_uv / (pixel_uv_size * pixelate_size)) * (pixel_uv_size * pixelate_size);

    // Get the pixelated color
    vec4 color = texture(SCREEN_TEXTURE, snapped_uv);

    // Color Quantization
    color.rgb = floor(color.rgb * color_levels) / color_levels;

    COLOR = color;
}
