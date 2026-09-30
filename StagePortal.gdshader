shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

float sparkle(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 pixel_uv = (floor(UV * vec2(160.0, 192.0)) + 0.5) / vec2(160.0, 192.0);
	vec2 point = (pixel_uv - vec2(0.5)) * vec2(2.6, 2.6);
	float radius = length(point);
	float angle = atan(point.y, point.x);
	float edge_wave = sin(angle * 9.0 + TIME * 1.35) * 0.022
		+ sin(angle * 17.0 - TIME * 0.9) * 0.012;
	float warped_radius = radius + edge_wave;

	float swirl = sin(radius * 20.0 - angle * 4.0 - TIME * 2.0
		+ 1.2 * sin(angle * 3.0 + TIME * 0.7));
	float ribbon = pow(max(swirl, 0.0), 3.0);
	float second_swirl = sin(radius * 32.0 + angle * 6.0 + TIME * 1.45);
	float inner_glimmer = pow(max(second_swirl, 0.0), 6.0);
	float dark_core = exp(-radius * radius * 10.0);
	vec3 depths = mix(vec3(0.035, 0.035, 0.065), vec3(0.13, 0.30, 0.14), ribbon);
	depths += vec3(0.53, 0.40, 0.14) * inner_glimmer * 0.45;
	depths = mix(depths, vec3(0.035, 0.025, 0.055), dark_core * 0.78);

	float inner_edge = exp(-pow((warped_radius - 0.88) * 27.0, 2.0));
	float outer_edge = exp(-pow((warped_radius - 1.01) * 27.0, 2.0));
	float halo = exp(-pow((warped_radius - 1.05) * 5.0, 2.0));
	float fleck = step(0.989, sparkle(floor(pixel_uv * vec2(73.0, 89.0))
		+ floor(TIME * 5.0))) * smoothstep(0.22, 0.70, radius);
	vec3 color = depths;
	color = mix(color, vec3(0.63, 0.93, 0.45), inner_edge * 0.88);
	color += vec3(1.0, 0.67, 0.24) * outer_edge * 0.72;
	color += vec3(1.0, 0.88, 0.50) * fleck * 0.58;
	color += vec3(0.34, 0.40, 0.12) * halo * 0.45;

	float aperture = 1.0 - smoothstep(0.84, 0.94, warped_radius);
	float alpha = aperture * 0.97 + inner_edge * 0.75
		+ outer_edge * 0.54 + halo * 0.22 + fleck * aperture * 0.25;
	ALBEDO = color;
	EMISSION = color * (1.15 + 0.12 * sin(TIME * 3.2));
	ALPHA = clamp(alpha, 0.0, 1.0);
}
