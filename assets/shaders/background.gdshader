shader_type canvas_item;

// Procedural scenic background — purple/magenta mountain atmosphere
// Inspired by Tetris Effect-style ambient backgrounds

uniform vec4 color_top : source_color = vec4(0.05, 0.02, 0.12, 1.0);      // Deep dark purple
uniform vec4 color_mid : source_color = vec4(0.12, 0.04, 0.22, 1.0);      // Rich purple
uniform vec4 color_bottom : source_color = vec4(0.08, 0.06, 0.18, 1.0);   // Dark blue-purple
uniform vec4 color_accent : source_color = vec4(0.25, 0.05, 0.35, 1.0);   // Magenta accent
uniform float time_scale : hint_range(0.0, 1.0) = 0.03;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.08;

// Simple hash-based noise
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;

	// Three-point vertical gradient
	vec4 grad;
	if (uv.y < 0.5) {
		grad = mix(color_top, color_mid, uv.y * 2.0);
	} else {
		grad = mix(color_mid, color_bottom, (uv.y - 0.5) * 2.0);
	}

	// Subtle accent glow in upper-mid region (like distant mountains catching light)
	float accent_mask = smoothstep(0.2, 0.4, uv.y) * smoothstep(0.6, 0.4, uv.y);
	float accent_noise = fbm(uv * 3.0 + vec2(t * 0.5, 0.0));
	grad = mix(grad, color_accent, accent_mask * accent_noise * 0.3);

	// Animated noise overlay for subtle atmospheric movement
	float n = fbm(uv * 5.0 + vec2(t, t * 0.7));
	grad.rgb += (n - 0.5) * noise_strength;

	// Subtle vignette
	float vignette = 1.0 - length((uv - 0.5) * vec2(1.2, 1.0)) * 0.8;
	vignette = clamp(vignette, 0.0, 1.0);
	grad.rgb *= vignette;

	COLOR = grad;
}
