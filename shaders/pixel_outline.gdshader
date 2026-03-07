shader_type spatial;
render_mode unshaded;

// PS1-style pixel outline — depth-only, hard edges, Mobile renderer compatible

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_nearest;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform vec3 outline_color : source_color = vec3(0.0);
uniform float outline_strength : hint_range(0.0, 1.0, 0.01) = 0.85;
uniform float depth_threshold : hint_range(0.0, 2.0, 0.01) = 0.25;

varying mat4 model_view_matrix;


float getDepth(vec2 screen_uv, mat4 inv_projection_matrix) {
	float raw_depth = texture(DEPTH_TEXTURE, screen_uv)[0];
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, raw_depth);
	vec4 view_space = inv_projection_matrix * vec4(ndc, 1.0);
	view_space.xyz /= view_space.w;
	return -view_space.z;
}

void vertex() {
	model_view_matrix = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 e = vec2(1.0 / VIEWPORT_SIZE.xy);

	float depth = getDepth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float du = getDepth(SCREEN_UV + vec2(0., -1.) * e, INV_PROJECTION_MATRIX);
	float dr = getDepth(SCREEN_UV + vec2(1., 0.) * e, INV_PROJECTION_MATRIX);
	float dd = getDepth(SCREEN_UV + vec2(0., 1.) * e, INV_PROJECTION_MATRIX);
	float dl = getDepth(SCREEN_UV + vec2(-1., 0.) * e, INV_PROJECTION_MATRIX);

	// Hard 1px edge — PS1 스타일 (smoothstep 없이 step으로 딱딱하게)
	float depth_diff = 0.0;
	depth_diff += step(depth_threshold, abs(du - depth));
	depth_diff += step(depth_threshold, abs(dr - depth));
	depth_diff += step(depth_threshold, abs(dd - depth));
	depth_diff += step(depth_threshold, abs(dl - depth));
	float edge = min(depth_diff, 1.0);

	vec3 original_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	vec3 final_color = mix(original_color, outline_color, edge * outline_strength);

	ALBEDO = final_color;
	ALPHA = edge * outline_strength;
}
