shader_type canvas_item;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float green_dominance = max(original.g - original.r, original.g - original.b);
	float grass_region = smoothstep(0.48, 0.56, UV.x) * smoothstep(0.38, 0.48, UV.y);
	float grass_mask = smoothstep(0.035, 0.14, green_dominance) * grass_region;

	float cyan_dominance = min(original.g, original.b) - original.r;
	float water_region = smoothstep(0.46, 0.53, UV.x) * (1.0 - smoothstep(0.82, 0.9, UV.x)) * smoothstep(0.4, 0.5, UV.y);
	float water_mask = smoothstep(0.025, 0.13, cyan_dominance) * water_region;

	vec2 animated_uv = UV;
	float grass_sway = sin(UV.x * 34.0 + UV.y * 17.0 + TIME * 1.15);
	animated_uv.x += round(grass_sway * 1.4) * TEXTURE_PIXEL_SIZE.x * grass_mask;
	vec2 water_wave = vec2(sin(UV.y * 95.0 + TIME * 4.5), cos(UV.x * 120.0 - TIME * 3.8));
	animated_uv += round(water_wave * 0.65) * TEXTURE_PIXEL_SIZE * water_mask;

	vec4 animated = texture(TEXTURE, animated_uv);
	float shimmer = sin(UV.x * 210.0 + UV.y * 260.0 - TIME * 6.0) * 0.5 + 0.5;
	animated.rgb += water_mask * shimmer * 0.035;

	float particles = 0.0;
	for (int i = 0; i < 20; i++) {
		float seed = fract(sin(float(i) * 127.1 + 311.7) * 43758.5453);
		float speed = 0.025 + fract(seed * 91.7) * 0.035;
		float particle_y = fract(seed - TIME * speed);
		float particle_x = 0.49 + fract(seed * 53.1) * 0.48;
		particle_x += sin(TIME * 0.65 + seed * 6.28318) * 0.012;
		vec2 particle_delta = UV - vec2(particle_x, particle_y);
		float pixel_distance = length(particle_delta / SCREEN_PIXEL_SIZE);
		float particle = 1.0 - smoothstep(0.7, 1.6, pixel_distance);
		particles = max(particles, particle);
	}
	float nature_mask = max(grass_mask, water_mask);
	animated.rgb = mix(animated.rgb, vec3(0.85, 0.91, 0.58), particles * nature_mask * 0.7);

	float dust_motes = 0.0;
	for (int i = 0; i < 36; i++) {
		float seed = fract(sin(float(i) * 91.7 + 157.3) * 24634.6345);
		float speed = 0.018 + fract(seed * 47.3) * 0.028;
		float particle_x = 0.015 + fract(seed * 19.1 + TIME * speed) * 0.45;
		float particle_y = 0.22 + fract(seed * 71.9 + sin(TIME * 0.32 + seed * 8.0) * 0.035) * 0.74;
		vec2 particle_delta = UV - vec2(particle_x, particle_y);
		vec2 pixel_delta = particle_delta / SCREEN_PIXEL_SIZE;
		pixel_delta.x *= 0.55;
		float pixel_distance = length(pixel_delta);
		float radius = 0.7 + seed * 1.3;
		float mote = 1.0 - smoothstep(radius, radius + 1.2, pixel_distance);
		dust_motes = max(dust_motes, mote);
	}
	float dry_field_region = (1.0 - smoothstep(0.43, 0.49, UV.x)) * smoothstep(0.18, 0.27, UV.y);
	animated.rgb = mix(animated.rgb, vec3(0.92, 0.73, 0.48), dust_motes * dry_field_region * 0.42);
	COLOR = animated * COLOR;
}