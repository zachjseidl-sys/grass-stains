shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, blend_mix;

uniform sampler2D mow_mask : filter_linear, repeat_disable;
uniform sampler2D wind_noise : filter_linear, repeat_enable;
uniform vec2 lawn_origin = vec2(5.0, -8.0);
uniform vec2 lawn_size = vec2(26.0, 42.0);
uniform vec3 tall_color : source_color = vec3(0.22, 0.46, 0.14);
uniform vec3 cut_color : source_color = vec3(0.36, 0.62, 0.23);
uniform vec3 stripe_color : source_color = vec3(0.30, 0.52, 0.19);
uniform float blade_height = 0.46;
uniform float wind_strength = 0.22;
uniform float stripe_strength = 0.30;

varying vec3 v_world_pos;
varying float v_cut;
varying vec2 v_mow_dir;

vec2 world_to_uv(vec2 world_xz) {
	return (world_xz - lawn_origin) / lawn_size;
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_pos = world;
	vec2 uv = world_to_uv(world.xz);
	float cut = 0.0;
	vec2 mow_dir = vec2(0.0, 1.0);
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		vec4 mask = texture(mow_mask, uv);
		cut = mask.r;
		mow_dir = normalize(mask.gb * 2.0 - 1.0 + vec2(0.001));
	}
	v_cut = cut;
	v_mow_dir = mow_dir;

	float height_scale = mix(1.0, 0.06, cut);
	float tip = UV.y;
	float wind_a = texture(wind_noise, world.xz * 0.07 + TIME * vec2(0.025, 0.018)).r - 0.5;
	float wind_b = texture(wind_noise, world.xz * 0.11 + TIME * vec2(-0.01, 0.03)).g - 0.5;
	vec3 bent = vec3((wind_a + wind_b * 0.5) * wind_strength * tip * (1.0 - cut), 0.0, wind_a * wind_strength * 0.35 * tip * (1.0 - cut));
	VERTEX.y *= height_scale;
	VERTEX += bent;
}

void fragment() {
	float stripe = dot(normalize(v_mow_dir), normalize(VIEW.xz + vec2(0.001))) * 0.5 + 0.5;
	vec3 base = mix(tall_color, cut_color, v_cut);
	vec3 striped = mix(base, stripe_color, stripe * stripe_strength * v_cut);
	ALBEDO = striped;
	ROUGHNESS = mix(0.96, 0.80, v_cut);
	SPECULAR = 0.06;
}
