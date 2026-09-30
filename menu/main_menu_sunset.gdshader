shader_type canvas_item;

float soft_box(vec2 uv, vec2 lower, vec2 upper, float feather) {
	return smoothstep(lower.x - feather, lower.x + feather, uv.x)
		* (1.0 - smoothstep(upper.x - feather, upper.x + feather, uv.x))
		* smoothstep(lower.y - feather, lower.y + feather, uv.y)
		* (1.0 - smoothstep(upper.y - feather, upper.y + feather, uv.y));
}

float glow(vec2 uv, vec2 center, vec2 radius) {
	vec2 offset = (uv - center) / radius;
	return exp(-dot(offset, offset) * 2.0);
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float green = smoothstep(0.0, 0.09, original.g - original.r * 0.72);
	float canopy = soft_box(UV, vec2(0.0, 0.0), vec2(0.32, 0.22), 0.035);
	float palms = soft_box(UV, vec2(0.17, 0.15), vec2(0.43, 0.38), 0.035);
	float banana = soft_box(UV, vec2(0.19, 0.40), vec2(0.35, 0.65), 0.025);
	float right_tree = soft_box(UV, vec2(0.81, 0.35), vec2(0.99, 0.63), 0.025);
	float middle_shrubs = soft_box(UV, vec2(0.26, 0.42), vec2(0.78, 0.76), 0.03);
	float grass = soft_box(UV, vec2(0.0, 0.64), vec2(1.0, 1.0), 0.04);
	float leaves = green * max(max(canopy, palms), max(banana, max(right_tree, middle_shrubs)));
	float grass_blades = green * grass;

	float breeze = sin(TIME * 1.35 + UV.y * 29.0 + UV.x * 15.0)
		+ 0.35 * sin(TIME * 0.82 + UV.x * 42.0);
	float small_breeze = sin(TIME * 1.9 + UV.x * 30.0 + UV.y * 16.0);
	vec2 shift = vec2(
		round(breeze * leaves * 1.65 + small_breeze * grass_blades * 0.85),
		round(small_breeze * leaves * 0.55)
	) * TEXTURE_PIXEL_SIZE;
	vec4 scene = texture(TEXTURE, clamp(UV + shift, vec2(0.0), vec2(1.0)));

	float sky = soft_box(UV, vec2(0.29, 0.02), vec2(1.0, 0.38), 0.05);
	float warm_clouds = sky * smoothstep(0.04, 0.20, scene.r - scene.g);
	scene.rgb += vec3(0.020, 0.006, 0.0) * warm_clouds
		* (0.5 + 0.5 * sin(TIME * 0.45 + UV.x * 13.0));

	float window_lights = glow(UV, vec2(0.106, 0.448), vec2(0.022, 0.045))
		+ glow(UV, vec2(0.478, 0.554), vec2(0.020, 0.035))
		+ glow(UV, vec2(0.585, 0.602), vec2(0.018, 0.032))
		+ glow(UV, vec2(0.960, 0.594), vec2(0.024, 0.040));
	float shrine_lights = glow(UV, vec2(0.774, 0.555), vec2(0.016, 0.027))
		+ glow(UV, vec2(0.797, 0.554), vec2(0.027, 0.039))
		+ glow(UV, vec2(0.814, 0.555), vec2(0.015, 0.027));
	float flicker = 0.80 + 0.12 * sin(TIME * 9.5) + 0.08 * sin(TIME * 17.3);
	scene.rgb += vec3(0.38, 0.16, 0.03) * window_lights * flicker * 0.34;
	scene.rgb += vec3(0.46, 0.19, 0.035) * shrine_lights
		* (0.78 + 0.16 * sin(TIME * 12.0) + 0.06 * sin(TIME * 23.0)) * 0.42;
	float sun_haze = glow(UV, vec2(0.864, 0.305), vec2(0.15, 0.17));
	scene.rgb += vec3(0.025, 0.009, 0.0) * sun_haze
		* (0.7 + 0.3 * sin(TIME * 0.7));

	for (int i = 0; i < 12; i++) {
		float seed = float(i);
		float x = fract(sin(seed * 127.1 + 31.7) * 43758.5453);
		float y = 0.55 + fract(sin(seed * 83.7 + 71.4) * 24634.6345) * 0.37;
		vec2 position = vec2(x, y);
		position.x += sin(TIME * 0.55 + seed * 4.9) * 0.008;
		position.y += sin(TIME * 0.38 + seed * 3.1) * 0.006;
		float pixel_distance = length((UV - position) / SCREEN_PIXEL_SIZE);
		float blink = pow(max(sin(TIME * 1.8 + seed * 2.7), 0.0), 5.0);
		float spark = (1.0 - smoothstep(0.4, 2.0, pixel_distance)) * blink;
		float halo = (1.0 - smoothstep(1.0, 6.0, pixel_distance)) * blink;
		scene.rgb += vec3(1.0, 0.73, 0.25) * (spark * 0.44 + halo * 0.07);
	}
	for (int i = 0; i < 7; i++) {
		float seed = float(i);
		vec2 position = vec2(
			0.772 + fract(sin(seed * 64.7 + 13.1) * 15342.17) * 0.053,
			0.555 - fract(TIME * (0.10 + seed * 0.008) + seed * 0.37) * 0.065
		);
		position.x += sin(TIME * 2.0 + seed * 3.9) * 0.003;
		float pixel_distance = length((UV - position) / SCREEN_PIXEL_SIZE);
		float ember = 1.0 - smoothstep(0.2, 2.0, pixel_distance);
		scene.rgb += vec3(1.0, 0.48, 0.08) * ember * 0.36;
	}

	COLOR = scene;
}
