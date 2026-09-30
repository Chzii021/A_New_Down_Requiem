shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 center = vec2(0.5);
	vec2 offset = SCREEN_UV - center;
	float radius = length(offset);
	float angle = atan(offset.y, offset.x);
	float pull = progress * progress;
	float twist = pull * 7.0 * (1.0 - smoothstep(0.05, 0.8, radius));
	float cs = cos(twist);
	float sn = sin(twist);
	vec2 spun = vec2(cs * offset.x - sn * offset.y, sn * offset.x + cs * offset.y);
	vec2 source_uv = clamp(center + spun / (1.0 + pull * 2.2), vec2(0.0), vec2(1.0));
	vec3 scene = texture(screen_texture, source_uv).rgb;

	float ring_radius = mix(0.63, 0.13, progress);
	float ring = exp(-pow((radius - ring_radius) * 19.0, 2.0));
	float rays = pow(max(sin(angle * 12.0 + TIME * 2.7 - progress * 13.0), 0.0), 8.0);
	vec3 portal_color = mix(vec3(0.19, 0.42, 0.34), vec3(0.91, 0.66, 0.30), rays);
	vec3 color = mix(scene, portal_color, clamp(ring * (0.57 + rays * 0.25) * progress, 0.0, 1.0));
	color *= 1.0 - progress * 0.19;
	color = mix(color, vec3(0.013, 0.019, 0.028), smoothstep(0.68, 1.0, progress));
	COLOR = vec4(color, 1.0);
}
