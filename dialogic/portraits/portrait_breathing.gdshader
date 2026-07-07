shader_type canvas_item;

// Driven by GDScript each frame via set_shader_parameter("breath", value)
uniform float breath : hint_range(-1.0, 1.0) = 0.0;

// UV-space boundaries of the chest region (0 = top, 1 = bottom of sprite)
// Tune per character if anatomy differs
uniform float chest_top    : hint_range(0.0, 1.0) = 0.35;
uniform float chest_bottom : hint_range(0.0, 1.0) = 0.65;

// Maximum UV displacement at the centre of the chest
// 0.003 ≈ 2px on a 700px tall sprite — increase for taller portraits
uniform float max_offset : hint_range(0.0, 0.03) = 0.003;

void fragment() {
	float y = UV.y;
	float weight = 0.0;

	if (y > chest_top && y < chest_bottom) {
		// Bell curve: 0 at boundaries, 1 at centre — smooth join with head and waist
		float t = (y - chest_top) / (chest_bottom - chest_top);
		weight = sin(t * PI);
	}

	// Negative displacement = sample from above = chest appears to rise during inhale
	vec2 uv = vec2(UV.x, UV.y - breath * max_offset * weight);
	COLOR = texture(TEXTURE, uv);
}
