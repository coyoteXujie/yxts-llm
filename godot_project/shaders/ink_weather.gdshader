shader_type canvas_item;

// ─── 水墨风格天气/氛围粒子层 ───
// GPU 全屏氛围效果：雨、雪、雾、沙尘、花瓣、余烬
// 替代 CPU _draw() 循环

uniform float weather_type : hint_range(0.0, 6.0) = 0.0;
// 0=晴, 1=细雨, 2=飞雪, 3=薄雾, 4=多云, 5=沙尘, 6=落花

uniform float particle_density : hint_range(0.0, 2.0) = 1.0;
uniform vec4 effect_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float time_speed : hint_range(0.0, 3.0) = 1.0;
uniform vec2 wind_direction = vec2(0.3, 0.0);
uniform float wind_strength : hint_range(0.0, 2.0) = 0.5;

// 门派气场
uniform float sect_aura : hint_range(0.0, 1.0) = 0.0;
uniform vec4 sect_color : source_color = vec4(1.0, 0.82, 0.38, 0.28);

// 渗墨底纹（纸纹用同一套）
float hash(vec2 p) {
    p = fract(p * vec2(443.8975, 397.2973));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
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

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 color = vec4(0.0);
    float t = TIME * time_speed;
    vec2 wind = wind_direction * wind_strength;
    
    // ─── 细雨 ───
    if (abs(weather_type - 1.0) < 0.5) {
        // 底色调
        color = vec4(0.06, 0.10, 0.13, 0.13);
        
        // 雨丝（用 hash 做随机垂直线）
        float rain_density = particle_density * 0.15;
        for (int i = 0; i < 3; i++) {
            float fi = float(i) * 0.7;
            vec2 rain_uv = uv * vec2(30.0, 100.0) + vec2(t * 220.0 * wind.x, t * 350.0);
            rain_uv += fi;
            vec2 rain_id = floor(rain_uv);
            vec2 rain_fr = fract(rain_uv);
            
            float r = hash(rain_id);
            float alpha = smoothstep(1.0 - rain_density, 1.0, r) * 0.30;
            float line = smoothstep(0.0, 0.1, rain_fr.y) * (1.0 - smoothstep(0.3, 0.5, rain_fr.y));
            color.a += alpha * line;
        }
        
        // 雨雾带
        float band = noise(uv * vec2(4.0, 1.5) + vec2(0.0, t * 12.0));
        color.rgb += vec3(0.58, 0.70, 0.76) * band * 0.035;
    }
    
    // ─── 飞雪 ───
    else if (abs(weather_type - 2.0) < 0.5) {
        color = vec4(0.12, 0.18, 0.24, 0.11);
        
        float snow_density = particle_density * 0.12;
        for (int i = 0; i < 4; i++) {
            float fi = float(i) * 0.53;
            vec2 snow_uv = uv * vec2(25.0, 30.0) + vec2(t * 24.0 * wind.x, t * 40.0);
            snow_uv += fi;
            
            vec2 sid = floor(snow_uv);
            vec2 sfr = fract(snow_uv);
            
            float r = hash(sid);
            float show = smoothstep(1.0 - snow_density, 1.0, r);
            
            float radius = 0.3 + hash(sid + 1.0) * 0.5;
            float dist = length(sfr - 0.5);
            float snowflake = smoothstep(radius, 0.0, dist);
            
            float twinkle = 0.5 + 0.5 * sin(t * 1.5 + hash(sid + 2.0) * 6.28);
            color += vec4(1.0, 1.0, 1.0, 0.25) * show * snowflake * twinkle;
        }
        
        // 雪雾
        float fog = noise(uv * vec2(2.0, 1.0) + vec2(0.0, t * 9.0));
        color.rgb += vec3(0.72, 0.76, 0.78) * fog * 0.035;
    }
    
    // ─── 薄雾 ───
    else if (abs(weather_type - 3.0) < 0.5) {
        float fog_intensity = particle_density * 0.12;
        for (int i = 0; i < 4; i++) {
            float fi = float(i) * 0.73;
            vec2 fog_uv = uv * vec2(1.5, 0.8) + vec2(t * (4.0 + fi * 1.5) * wind.x, t * 1.0);
            fog_uv += fi;
            float f = noise(fog_uv);
            float layer_alpha = (0.06 + float(i) * 0.012) * fog_intensity;
            color.rgb += vec3(0.80, 0.82, 0.74) * f * layer_alpha;
            color.a += f * layer_alpha * 0.3;
        }
    }
    
    // ─── 多云 ───
    else if (abs(weather_type - 4.0) < 0.5) {
        for (int i = 0; i < 3; i++) {
            float fi = float(i) * 0.6;
            vec2 cloud_uv = uv * vec2(1.2, 0.6) + vec2(t * (6.0 + fi * 3.0) * wind.x, 0.0);
            cloud_uv += fi;
            float c = noise(cloud_uv);
            c = smoothstep(0.3, 0.7, c);
            color.rgb += vec3(0.03) * c * (0.08 + float(i) * 0.015);
            color.a += c * (0.025 + float(i) * 0.005);
        }
    }
    
    // ─── 沙尘 ───
    else if (abs(weather_type - 5.0) < 0.5) {
        color = vec4(0.32, 0.22, 0.10, 0.045);
        float sand_density = particle_density * 0.08;
        for (int i = 0; i < 3; i++) {
            float fi = float(i) * 0.63;
            vec2 sand_uv = uv * vec2(15.0, 8.0) + vec2(t * 56.0 * wind.x, t * 10.0);
            sand_uv += fi;
            vec2 sid = floor(sand_uv);
            float r = hash(sid);
            float show = smoothstep(1.0 - sand_density, 1.0, r);
            
            vec2 sfr = fract(sand_uv);
            float streak = smoothstep(0.0, 0.2, sfr.x) * (1.0 - smoothstep(0.6, 0.9, sfr.x));
            streak *= smoothstep(0.0, 0.3, sfr.y) * (1.0 - smoothstep(0.5, 0.8, sfr.y));
            
            color.rgb += vec3(0.88, 0.70, 0.42) * show * streak * 0.12;
            color.a += show * streak * 0.04;
        }
    }
    
    // ─── 落花 ───
    else if (abs(weather_type - 6.0) < 0.5) {
        float petal_density = particle_density * 0.06;
        for (int i = 0; i < 4; i++) {
            float fi = float(i) * 0.47;
            vec2 petal_uv = uv * vec2(12.0, 10.0) + vec2(t * 18.0 * wind.x, t * 22.0);
            petal_uv += fi;
            
            vec2 pid = floor(petal_uv);
            vec2 pfr = fract(petal_uv);
            
            float r = hash(pid);
            float show = smoothstep(1.0 - petal_density, 1.0, r);
            
            float sway = sin(t * 0.8 + hash(pid + 1.0) * 6.28) * 0.15;
            vec2 petal_pos = pfr - 0.5 + vec2(sway, 0.0);
            float dist = length(petal_pos);
            
            float petal = smoothstep(0.5, 0.0, dist);
            vec3 petal_color = vec3(
                0.96 - hash(pid + 3.0) * 0.15,
                0.74 - hash(pid + 4.0) * 0.15,
                0.78 - hash(pid + 5.0) * 0.15
            );
            
            color.rgb += petal_color * show * petal * 0.20;
            color.a += show * petal * 0.10;
        }
    }
    
    // ─── 门派气场 ───
    if (sect_aura > 0.0) {
        vec2 center = uv - 0.5;
        center.x += 0.02; // slightly off center for natural look
        float dist_center = length(center);
        
        // 旋转气场光环
        float angle = atan(center.y, center.x);
        float ring_speed = t * 0.22;
        for (int i = 0; i < 3; i++) {
            float fi = float(i) * 1.38;
            float ring_angle = angle + ring_speed + fi;
            float ring_radius = 0.25 + float(i) * 0.12 + sin(t * 0.7 + fi) * 0.02;
            float ring_dist = abs(dist_center - ring_radius);
            float ring = smoothstep(0.01, 0.0, ring_dist);
            color.rgb += sect_color.rgb * ring * sect_aura * 0.5;
        }
        
        // 底部气场光晕
        float glow = exp(-dist_center * 8.0);
        color.rgb += sect_color.rgb * glow * sect_aura * 0.3;
    }
    
    // 输出
    color.a = clamp(color.a, 0.0, 1.0);
    COLOR = color;
}
