shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform bool nvg_enabled = true;
uniform float night_vision_gain : hint_range(0.5, 6.0) = 2.8;
uniform float gamma_exp : hint_range(0.3, 2.0) = 0.72;
uniform float noise_amount : hint_range(0.0, 0.4) = 0.075;
uniform float scanline_density : hint_range(100.0, 1200.0) = 520.0;
uniform float scanline_intensity : hint_range(0.0, 0.25) = 0.045;
uniform float vignette_radius : hint_range(0.4, 1.4) = 0.92;
uniform float vignette_softness : hint_range(0.05, 0.8) = 0.38;

// Military Gen-3 Phosphor Palette
uniform vec3 phosphor_dark : source_color = vec3(0.015, 0.095, 0.035);
uniform vec3 phosphor_bright : source_color = vec3(0.28, 0.98, 0.42);
uniform vec3 phosphor_hot : source_color = vec3(0.88, 1.0, 0.92);

void fragment() {
	vec3 src = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	
	if (!nvg_enabled) {
		COLOR = vec4(src, 1.0);
	} else {
	
	// 1. Calculate luminance from source
	float lum = dot(src, vec3(0.299, 0.587, 0.114));
	
	// 2. Non-linear light amplification
	float amplified_lum = pow(clamp(lum * night_vision_gain, 0.0, 1.0), gamma_exp);
	
	// 3. Dynamic quantum scintillation micro-grain noise (time-dependent photon noise)
	float grain_time = fract(TIME * 24.0);
	vec2 noise_seed = SCREEN_UV + vec2(grain_time * 0.173, grain_time * 0.911);
	float grain = (fract(sin(dot(noise_seed, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * noise_amount;
	amplified_lum = clamp(amplified_lum + grain, 0.0, 1.0);
	
	// 4. Military phosphor color grading (Green Phosphor Gen-3)
	vec3 nvg_color;
	if (amplified_lum < 0.62) {
		nvg_color = mix(phosphor_dark, phosphor_bright, amplified_lum / 0.62);
	} else {
		nvg_color = mix(phosphor_bright, phosphor_hot, (amplified_lum - 0.62) / 0.38);
	}
	
	// 5. Subtle horizontal CRT/Optic scanlines
	float scanline = sin(SCREEN_UV.y * scanline_density) * scanline_intensity;
	nvg_color = clamp(nvg_color - scanline, vec3(0.0), vec3(1.0));
	
	// 6. Circular optical tube vignette with aspect ratio correction
	vec2 aspect_uv = (SCREEN_UV - vec2(0.5));
	aspect_uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float dist_from_center = length(aspect_uv);
	float vignette = smoothstep(vignette_radius, vignette_radius - vignette_softness, dist_from_center);
	
	// Outer ocular housing border
	nvg_color *= vignette;
	
	COLOR = vec4(nvg_color, 1.0);
	}
}
