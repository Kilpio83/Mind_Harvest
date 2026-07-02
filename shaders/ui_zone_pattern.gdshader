shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.043, 0.039, 0.031, 1.0);
uniform vec4 pattern_color : source_color = vec4(0.769, 0.569, 0.165, 0.05);
// 0 = dots, 1 = horizontal lines, 2 = grid
uniform int pattern = 0;
uniform float spacing : hint_range(4.0, 48.0) = 8.0;
uniform float thickness : hint_range(0.2, 3.0) = 0.9;

void fragment() {
	vec2 coord = FRAGCOORD.xy;
	float alpha = 0.0;

	if (pattern == 0) {
		vec2 cell = mod(coord, vec2(spacing));
		float d = length(cell - vec2(spacing * 0.5));
		alpha = 1.0 - smoothstep(thickness - 0.4, thickness + 0.4, d);
	} else if (pattern == 1) {
		float y = mod(coord.y, spacing);
		alpha = 1.0 - smoothstep(0.0, thickness, y);
		alpha = max(alpha, 1.0 - smoothstep(spacing - thickness, spacing, y));
	} else {
		float y = mod(coord.y, spacing);
		float x = mod(coord.x, spacing);
		float hl = 1.0 - smoothstep(0.0, thickness, y);
		hl = max(hl, 1.0 - smoothstep(spacing - thickness, spacing, y));
		float vl = 1.0 - smoothstep(0.0, thickness, x);
		vl = max(vl, 1.0 - smoothstep(spacing - thickness, spacing, x));
		alpha = max(hl, vl);
	}

	vec3 col = mix(bg_color.rgb, pattern_color.rgb, alpha * pattern_color.a);
	COLOR = vec4(col, bg_color.a);
}
