shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ring_color : source_color = vec4(0.2, 0.9, 0.3, 0.8);
uniform float ring_width : hint_range(0.005, 0.1) = 0.03;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	float radius = progress * 0.5;
	float ring = smoothstep(radius - ring_width, radius, dist)
	            - smoothstep(radius, radius + ring_width, dist);
	float fade = 1.0 - progress;
	COLOR = ring_color * vec4(1.0, 1.0, 1.0, ring * fade);
}
