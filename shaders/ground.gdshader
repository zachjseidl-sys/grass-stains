shader_type spatial;
render_mode cull_disabled, diffuse_lambert;

uniform sampler2D mow_mask : filter_linear, repeat_disable;
uniform vec2 lawn_origin = vec2(-14.0, -6.0);
uniform vec2 lawn_size = vec2(28.0, 32.0);
uniform vec3 tall_color : source_color = vec3(0.28, 0.52, 0.18);
uniform vec3 cut_color : source_color = vec3(0.42, 0.68, 0.28);
uniform vec3 stripe_color : source_color = vec3(0.36, 0.58, 0.22);
uniform float stripe_strength = 0.22;

varying vec2 v_world_xz;
varying float v_cut;

vec2 world_to_uv(vec2 world_xz) {
	return (world_xz - lawn_origin) / lawn_size;
}

void vertex() {
	v_world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 uv = world_to_uv(v_world_xz);
	float cut = 0.0;
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		vec4 mask = texture(mow_mask, uv);
		cut = mask.r;
		v_cut = cut;
		vec2 mow_dir = mask.gb * 2.0 - 1.0;
		float stripe = dot(normalize(mow_dir + vec2(0.001)), normalize(VIEW.xz + vec2(0.001))) * 0.5 + 0.5;
		vec3 base = mix(tall_color, cut_color, cut);
		vec3 striped = mix(base, stripe_color, stripe * stripe_strength * cut);
		ALBEDO = striped;
	} else {
		ALBEDO = tall_color * 0.85;
	}
	ROUGHNESS = mix(0.92, 0.78, cut);
}
