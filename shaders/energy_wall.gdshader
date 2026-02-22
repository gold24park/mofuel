shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec3 wall_color : source_color = vec3(0.2, 0.3, 0.9);
uniform float base_alpha : hint_range(0.0, 1.0) = 0.15;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;
uniform float pulse_amount : hint_range(0.0, 0.5) = 0.08;
uniform float edge_glow : hint_range(0.0, 2.0) = 0.5;

void fragment() {
	// Gentle pulse
	float pulse = sin(TIME * pulse_speed) * pulse_amount;
	float alpha = base_alpha + pulse;

	// Edge brightening based on view angle (Fresnel-like for top-down)
	// UV.y goes along wall height — edges at 0 and 1
	float edge = 1.0 - abs(UV.y * 2.0 - 1.0);
	edge = pow(edge, 2.0);
	float glow = edge * edge_glow;

	// Subtle scan line
	float scan = 0.5 + 0.5 * sin(UV.y * 30.0 + TIME * 2.0);
	scan = mix(0.8, 1.0, scan);

	ALBEDO = wall_color * (1.0 + glow) * scan;
	ALPHA = alpha * scan;
}
