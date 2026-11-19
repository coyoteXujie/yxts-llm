shader_type canvas_item;

// ─── 水墨后处理 Shader v5 (Forward+ / WorldEnvironment) ───
// 宣纸纤维 + 墨迹不连续（跳白/漏墨）+ 枯笔 + 晕染光墨
// v5 新增: Bloom (水墨渗光通道) + Film grain (纸张纹理感)
// 适配 WorldEnvironment.post_process_material 模式
// ────────────────────────────────────────────────────────

uniform float intensity : hint_range(0.0, 1.0) = 0.85;
uniform float paper_strength : hint_range(0.0, 0.20) = 0.070;
uniform float ink_bleed : hint_range(0.0, 6.0) = 3.0;
uniform float warm_tone : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55;
uniform float saturation : hint_range(0.0, 2.0) = 0.75;
uniform float contrast : hint_range(0.5, 2.0) = 1.25;
uniform vec4 paper_color : source_color = vec4(0.88, 0.82, 0.72, 1.0);
uniform vec4 ink_color : source_color = vec4(0.05, 0.03, 0.01, 1.0);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;

// v4 新增参数
uniform float ink_spread : hint_range(0.0, 1.0) = 0.30;       // 边缘墨渍扩散强度
uniform float brush_stroke : hint_range(0.0, 1.0) = 0.35;      // 笔触纹理叠加强度
uniform float time : hint_range(0.0, 100.0) = 0.0;             // 动画时间

// v5 新增: Bloom (水墨渗光效果)
uniform float bloom_intensity : hint_range(0.0, 1.0) = 0.25;   // 渗光强度
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.60;   // 亮度阈值(高于此值产生渗光)
uniform float bloom_tint_warm : hint_range(0.0, 1.0) = 0.60;   // 渗光暖色倾向

// v5 新增: Film grain (纸张纹理感)
uniform float film_grain : hint_range(0.0, 0.15) = 0.035;      // 颗粒强度
uniform float grain_size : hint_range(1.0, 16.0) = 4.0;        // 颗粒尺寸

// ── 噪声 ──
float hash21(vec2 p) {
    p = fract(p * vec2(443.8975, 397.2973));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float smooth_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 3; i++) {
        v += a * smooth_noise(p);
        p = p * 2.0;
        a *= 0.5;
    }
    return v;
}

// 改进版噪声：更高频细节
float fbm4(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * smooth_noise(p);
        p = p * 2.1;
        a *= 0.5;
    }
    return v;
}

// ── 宣纸纤维纹理 ──
float paper_fiber(vec2 uv) {
    float curtain_h = smooth_noise(uv * vec2(1200.0, 80.0));
    float curtain_v = smooth_noise(uv * vec2(80.0, 1200.0));
    float curtain = smoothstep(0.3, 0.7, curtain_h * curtain_v);
    float cluster1 = smooth_noise(uv * 800.0);
    float cluster2 = smooth_noise(uv * 400.0);
    float cluster = cluster1 * 0.4 + cluster2 * 0.3;
    float mica = smooth_noise(uv * 2000.0) * 0.15;
    return mix(cluster, curtain * 0.5, 0.3) + mica;
}

// ── 墨迹不连续（核心创新） ──
float ink_jump_white(vec2 uv, float ink_density) {
    float micro = fbm(uv * 600.0 + vec2(0.183, 0.947));
    float macro = fbm(uv * 150.0);
    float skip_threshold = 0.5 + ink_density * 0.3 - micro * 0.3 - macro * 0.15;
    float skip = smoothstep(skip_threshold, skip_threshold + 0.15, 0.5 + 0.5 * fbm(uv * 300.0 + vec2(0.5, 0.5)));
    return skip * 0.08 * (0.3 + ink_density * 0.7);
}

// ── 枯笔效果 ──
float dry_brush(vec2 uv, float edge_strength) {
    float n = fbm(uv * 200.0);
    float bristle = smooth_noise(uv * vec2(500.0, 30.0));
    bristle = smoothstep(0.4, 0.7, bristle);
    float dry = bristle * (1.0 - abs(n - 0.5) * 0.3);
    return dry * 0.04 * edge_strength;
}

// ── 墨色晕染（5-tap 十字采样） ──
vec3 ink_bleed_effect(vec2 uv, vec2 tex_size, vec3 color, float brightness) {
    vec2 step = 1.0 / tex_size * 2.0;
    vec2 offsets[4] = vec2[](vec2(step.x, 0.0), vec2(-step.x, 0.0),
                             vec2(0.0, step.y), vec2(0.0, -step.y));
    
    float bleed = brightness;
    float w_sum = 1.0;
    for (int i = 0; i < 4; i++) {
        vec3 s = texture(SCREEN_TEXTURE, uv + offsets[i]).rgb;
        float b = max(s.r, max(s.g, s.b));
        bleed += b * 0.6;
        w_sum += 0.6;
    }
    bleed /= w_sum;
    
    float bleed_strength = max(0.0, (bleed - brightness)) * ink_bleed;
    bleed_strength = clamp(bleed_strength, 0.0, 1.0);
    
    vec3 glow = vec3(1.0, 0.85, 0.55) * bleed * 0.8;
    vec3 result = mix(color, glow, bleed_strength * 0.35);
    result += glow * bleed_strength * 0.10;
    return result;
}

// ── 边缘墨渍扩散（v4 新增） ──
// 基于 Sobel 边缘检测，在边缘区域产生墨水晕染扩散效果
float edge_bloom(vec2 uv, vec2 tex_size, float ink_density) {
    vec2 step = 1.0 / tex_size;
    // Sobel 边缘检测
    float tl = length(texture(SCREEN_TEXTURE, uv + vec2(-step.x, -step.y)).rgb);
    float t  = length(texture(SCREEN_TEXTURE, uv + vec2(0.0, -step.y)).rgb);
    float tr = length(texture(SCREEN_TEXTURE, uv + vec2(step.x, -step.y)).rgb);
    float l  = length(texture(SCREEN_TEXTURE, uv + vec2(-step.x, 0.0)).rgb);
    float r  = length(texture(SCREEN_TEXTURE, uv + vec2(step.x, 0.0)).rgb);
    float bl = length(texture(SCREEN_TEXTURE, uv + vec2(-step.x, step.y)).rgb);
    float b  = length(texture(SCREEN_TEXTURE, uv + vec2(0.0, step.y)).rgb);
    float br = length(texture(SCREEN_TEXTURE, uv + vec2(step.x, step.y)).rgb);
    
    float gx = -tl - 2.0*l - bl + tr + 2.0*r + br;
    float gy = -tl - 2.0*t - tr + bl + 2.0*b + br;
    float edge = sqrt(gx*gx + gy*gy);
    
    // 边缘处墨水扩散
    float spread = smoothstep(0.0, 0.3, edge) * ink_spread * ink_density;
    // 使用噪声让扩散有自然的不规则感
    float noise = fbm(uv * 200.0 + time * 0.02);
    spread *= 0.7 + 0.3 * noise;
    return clamp(spread, 0.0, 0.6);
}

// ── 笔触纹理叠加（v4 新增） ──
// 模拟水墨画笔的纹理效果
float brush_texture(vec2 uv, float ink_density) {
    // 长条状笔触纹理
    float brush1 = smooth_noise(uv * vec2(80.0, 400.0) + time * 0.01);
    float brush2 = smooth_noise(uv * vec2(400.0, 60.0) - time * 0.008);
    float brush = mix(brush1, brush2, 0.5);
    // 在墨色浓处更明显
    return smoothstep(0.3, 0.8, brush) * brush_stroke * ink_density * 0.08;
}

// ── v5 Bloom (水墨渗光效果) ──
// 提取高亮区域，模糊并叠加回画面，模拟墨渍渗光
vec3 ink_bloom(vec2 uv, vec2 tex_size, vec3 color) {
    float bright = max(color.r, max(color.g, color.b));
    // 只对高于阈值的区域做渗光
    float mask = smoothstep(bloom_threshold, 1.0, bright);
    if (mask <= 0.0) return vec3(0.0);
    
    // 多级采样模拟模糊
    vec2 step = 1.0 / tex_size;
    vec3 blur = vec3(0.0);
    float w_sum = 0.0;
    
    // 3x3 高斯权重近似
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 offset = vec2(float(x), float(y)) * step * 1.5;
            vec3 s = texture(SCREEN_TEXTURE, uv + offset).rgb;
            float b = max(s.r, max(s.g, s.b));
            float w = exp(-float(x*x + y*y) * 0.3);
            // 只累积高亮部分
            float bright_mask = smoothstep(bloom_threshold, 1.0, b);
            blur += s * w * bright_mask;
            w_sum += w * bright_mask;
        }
    }
    blur = w_sum > 0.001 ? blur / w_sum : vec3(0.0);
    
    // 暖色倾向
    vec3 tint = mix(blur, blur * vec3(1.3, 1.1, 0.7), bloom_tint_warm);
    return tint * mask * bloom_intensity;
}

// ── v5 Film Grain (纸张纹理颗粒) ──
float ink_film_grain(vec2 uv, float t) {
    // 基于 hash 的颗粒噪声
    vec2 grain_uv = uv * (1.0 / grain_size) * vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 i = floor(grain_uv);
    vec2 f = fract(grain_uv);
    f = f * f * (3.0 - 2.0 * f);
    
    float g = hash21(i + vec2(0.0, 0.0));
    float g2 = hash21(i + vec2(1.0, 0.0));
    float g3 = hash21(i + vec2(0.0, 1.0));
    float g4 = hash21(i + vec2(1.0, 1.0));
    
    float grain = mix(mix(g, g2, f.x), mix(g3, g4, f.x), f.y);
    // 增加一点动画闪烁
    float flicker = sin(t * 12.0 + dot(i, vec2(43.0, 17.0))) * 0.15;
    return (grain - 0.5) * (1.0 + flicker);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 tex_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec4 screen = texture(SCREEN_TEXTURE, uv);
    vec3 color = screen.rgb;
    
    float brightness = max(color.r, max(color.g, color.b));
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    float ink_density = 1.0 - gray;
    
    // 1. 墨色晕染
    color = ink_bleed_effect(uv, tex_size, color, brightness);
    
    // 2. ★ v4 边缘墨渍扩散（边缘渗化）
    float edge_ink = edge_bloom(uv, tex_size, ink_density);
    color = mix(color, ink_color.rgb, edge_ink * 0.35);
    // 边缘处稍微变亮（渗光）
    color += edge_ink * vec3(0.08, 0.04, 0.02);
    
    // 3. 暖色调
    color.r = mix(color.r, color.r * 1.06 + 0.03, warm_tone);
    color.g = mix(color.g, color.g * 1.02 + 0.02, warm_tone);
    color.b = mix(color.b, color.b * 0.88 + 0.01, warm_tone);
    
    // 4. 降饱和度
    color = mix(vec3(gray), color, saturation);
    
    // 5. 对比度
    color = (color - 0.5) * contrast + 0.5;
    color = clamp(color, 0.0, 1.0);
    
    // 6. ★ v4 笔触纹理叠加
    float brush = brush_texture(uv, ink_density);
    color = mix(color, color * 0.92, brush);
    
    // 7. 纸张纤维纹理
    float paper = paper_fiber(uv);
    float paper_mix = paper_strength * 0.5;
    color = mix(color, paper_color.rgb, paper_mix);
    color += (paper - 0.5) * paper_strength * 0.3;
    
    // 8. 墨迹不连续 — 跳白/漏墨
    float skip = ink_jump_white(uv, ink_density);
    color = mix(color, paper_color.rgb, skip * 0.5);
    color += skip * 0.03;
    
    // 9. 枯笔飞白（边缘散墨）
    float edge = 0.0;
    vec2 step_px = 1.0 / tex_size;
    float ex = abs(texture(SCREEN_TEXTURE, uv + vec2(step_px.x, 0.0)).r - texture(SCREEN_TEXTURE, uv - vec2(step_px.x, 0.0)).r);
    float ey = abs(texture(SCREEN_TEXTURE, uv + vec2(0.0, step_px.y)).r - texture(SCREEN_TEXTURE, uv - vec2(0.0, step_px.y)).r);
    edge = max(ex, ey) * 3.0;
    edge = min(edge, 1.0) * ink_density;
    float dry = dry_brush(uv, edge);
    color = mix(color, paper_color.rgb * 0.6, dry);
    
    // 10. ★ v4 增强暗角（渗墨暗角 + 更自然的边缘过渡）
    vec2 cen = uv - 0.5;
    float vx = 1.0 - abs(cen.x) * 0.65;
    float vy = 1.0 - abs(cen.y) * 0.85;
    float vignette = vx * vy;
    // 使用噪声做不均匀的暗角（模拟纸张边缘自然发黄）
    float v_noise = fbm4(uv * 8.0) * 0.12;
    vignette = pow(vignette, 1.0 + (vignette_strength + v_noise) * 0.9);
    // 暗角区域叠加暖色纸调
    vec3 dark_tint = mix(paper_color.rgb * 0.5, vec3(0.02, 0.015, 0.01), vignette_strength);
    color = mix(color, dark_tint, (1.0 - vignette) * 0.30);
    color *= vignette;
    
    // 11. ★ v5 Bloom (水墨渗光): 在暗角之后叠加，形成高亮区自然渗光
    vec3 bloom = ink_bloom(uv, tex_size, color);
    color += bloom;
    
    // 12. ★ v5 Film Grain (纸张纹理颗粒): 叠加在最终色彩上
    float grain = ink_film_grain(uv, time);
    color += grain * film_grain;
    
    // 13. 焦墨保护
    color = mix(color, mix(ink_color.rgb, color, 0.7), ink_density * 0.06);
    
    color = clamp(color, 0.0, 1.0);
    
    COLOR = mix(screen, vec4(color, screen.a), intensity);
}
