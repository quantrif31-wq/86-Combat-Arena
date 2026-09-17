shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform float clip_height = 999.0;
uniform bool invert_clip = false;
uniform float alpha_scissor = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;

varying float local_y;

void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	if (!invert_clip) {
		if (local_y > clip_height) {
			discard;
		}
	} else {
		if (local_y < clip_height) {
			discard;
		}
	}
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = tex.rgb;
	ALPHA = tex.a;
	if (alpha_scissor > 0.01) {
		ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
	}
	ROUGHNESS = roughness;
}
