shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D detail_texture : source_color, filter_nearest;
uniform bool has_detail = false;
uniform float snap_resolution : hint_range(16.0, 512.0) = 240.0;
uniform float affine_strength : hint_range(0.0, 1.0) = 0.8;

varying float affine_w;

void vertex() {
	vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);

	// Vertex snapping — PS1의 고정소수점 좌표계 모사
	float grid = snap_resolution * 0.5;
	clip_pos.xy = floor(clip_pos.xy / clip_pos.w * grid + 0.5) / grid * clip_pos.w;
	POSITION = clip_pos;

	// Affine texture mapping — PS1의 perspective-incorrect 보간 모사
	float w = mix(1.0, clip_pos.w, affine_strength);
	UV *= w;
	affine_w = w;
}

void fragment() {
	vec2 uv = UV / affine_w;
	vec3 col = albedo_color.rgb;

	if (has_detail) {
		vec4 detail = texture(detail_texture, uv);
		col = mix(col, detail.rgb, detail.a);
	}

	ALBEDO = col;
}
