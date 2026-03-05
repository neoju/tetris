shader_type canvas_item;

// Subtle purple/magenta color grading post-process
// Applied as an overlay on a full-screen ColorRect

uniform float intensity : hint_range(0.0, 1.0) = 0.12;
uniform vec4 tint_color : source_color = vec4(0.6, 0.3, 0.7, 1.0);  // Purple-magenta
uniform float contrast_boost : hint_range(0.9, 1.2) = 1.05;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec4 screen = texture(TEXTURE, UV);

	// Apply subtle tint by mixing toward tint color
	vec3 tinted = mix(screen.rgb, tint_color.rgb * screen.rgb, intensity);

	// Slight contrast boost (expand around midpoint)
	tinted = (tinted - 0.5) * contrast_boost + 0.5;
	tinted = clamp(tinted, 0.0, 1.0);

	// Vignette darkening at edges
	float dist = length((UV - 0.5) * vec2(1.2, 1.0));
	float vignette = 1.0 - dist * vignette_strength;
	vignette = clamp(vignette, 0.0, 1.0);
	tinted *= vignette;

	COLOR = vec4(tinted, screen.a);
}
