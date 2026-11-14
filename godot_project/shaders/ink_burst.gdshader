shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burst_color : source_color = vec4(0.03, 0.02, 0.01, 0.6);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);
	
	// 墨爆裂圈
	float burst = 1.0 - smoothstep(0.0, 0.8, d);
	float ring = exp(-d * d * 8.0) * 0.5;
	
	// 随机墨点
	float dots = smoothstep(0.7, 0.0, d) * (1.0 + sin(uv.x * 30.0 + uv.y * 27.0) * 0.3);
	
	float alpha = (burst * 0.6 + ring + dots * 0.2) * intensity;
	COLOR = vec4(burst_color.rgb, alpha);
}
