shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.42, 0.14, 1.0);
uniform int effect_mode = 0;
uniform bool impact = false;
uniform float age = 0.0;

varying float seed;

float band(float distance_from_line, float width) {
	return 1.0 - smoothstep(width * 0.45, width, abs(distance_from_line));
}

void vertex() {
	seed = INSTANCE_CUSTOM.r;
	if (effect_mode == 1) {
		float height = 1.0 - UV.y;
		VERTEX.x += sin(age * 7.0 + seed * 32.0 + height * 6.0) * 0.12 * height;
		if (impact) {
			// Grow from the soil into a tall eruption before the ribbons dissolve.
			float growth = smoothstep(0.0, 0.13, age);
			VERTEX.y -= (1.0 - growth) * height;
		}
	} else if (effect_mode == 2) {
		float rise = impact ? age * (2.6 + seed * 2.0) : fract(age * 0.45 + seed) * 0.9;
		VERTEX.y += rise;
		VERTEX.x += sin(age * 4.0 + seed * 24.0) * 0.08;
	}
}

void fragment() {
	float lifetime = impact ? (1.0 - smoothstep(0.34, 0.9, age)) : 1.0;
	float intensity = 0.0;
	float alpha = 0.0;
	vec3 color = tint.rgb;
	if (effect_mode == 0) {
		vec2 p = (UV - vec2(0.5)) * 2.32;
		float r = length(p);
		float angle = atan(p.y, p.x);
		float pulse = 0.8 + 0.2 * sin(age * 9.0);
		float outer = band(r - 0.99, 0.025);
		float inner = band(r - 0.69, 0.014);
		// Interwoven diamond bands suggest woven bamboo and Isan textile motifs.
		float weave_a = band(abs(sin(angle * 12.0 + age * 0.48)) - (r - 0.76) * 9.0, 0.19);
		float weave_b = band(abs(sin(angle * 12.0 - age * 0.48)) - (0.92 - r) * 9.0, 0.19);
		float weave = max(weave_a, weave_b) * smoothstep(0.72, 0.77, r) * (1.0 - smoothstep(0.91, 0.96, r));
		float spokes = pow(abs(cos(angle * 4.0 - age * 0.7)), 34.0) * smoothstep(0.25, 0.31, r) * (1.0 - smoothstep(0.62, 0.66, r));
		float center = band(r - 0.24, 0.018) + band(abs(p.x) + abs(p.y) - 0.22, 0.021);
		float fill = (1.0 - smoothstep(0.92, 1.0, r)) * 0.105;
		intensity = clamp(outer + inner + weave * 0.85 + spokes * 0.65 + center * 0.8, 0.0, 1.0);
		alpha = (fill + intensity * 0.86) * pulse;
		if (impact) {
			float wave_radius = mix(0.13, 1.09, smoothstep(0.0, 0.65, age));
			float wave = band(r - wave_radius, 0.065);
			intensity = max(wave, intensity * (1.0 - smoothstep(0.0, 0.3, age)));
			alpha = max(wave * 0.94, alpha * (1.0 - smoothstep(0.0, 0.36, age)));
		}
		color = mix(tint.rgb, vec3(1.0, 0.94, 0.72), intensity * 0.48);
	} else if (effect_mode == 1) {
		float h = 1.0 - UV.y;
		float sway = sin(h * 10.0 - age * 10.0 + seed * 29.0) * 0.13 * h;
		float width = (1.0 - h) * 0.48 + 0.015;
		float flame = 1.0 - smoothstep(width * 0.35, width, abs(UV.x - 0.5 + sway));
		float root = smoothstep(0.0, 0.10, h);
		alpha = flame * root * (1.0 - h) * (impact ? 0.86 : 0.62);
		intensity = flame * (1.0 - h * 0.65);
		color = mix(tint.rgb, vec3(1.0, 0.94, 0.72), intensity * 0.65);
	} else {
		intensity = 1.0;
		alpha = impact ? 0.86 : (0.45 + 0.25 * sin(seed * 30.0 + age * 5.0));
		color = mix(tint.rgb, vec3(1.0, 0.95, 0.75), 0.7);
	}
	ALBEDO = color;
	EMISSION = color * (0.65 + intensity * 0.7);
	ALPHA = clamp(alpha * lifetime, 0.0, 1.0);
}
