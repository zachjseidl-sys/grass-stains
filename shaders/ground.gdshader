shader_type spatial;
render_mode cull_disabled, diffuse_lambert;

uniform sampler2D mow_mask : filter_linear, repeat_disable;
uniform vec2 lawn_origin = vec2(5.0, -8.0);
uniform vec2 lawn_size = vec2(26.0, 42.0);
uniform vec3 tall_color : source_color = vec3(0.26, 0.50, 0.17);
uniform vec3 cut_color : source_color = vec3(0.40, 0.66, 0.26);
uniform vec3 stripe_color : source_color = vec3(0.34, 0.56, 0.21);
uniform float stripe_strength = 0.24;

uniform vec4 street_bounds = vec4(-3.5, -18.0, 3.5, 38.0);
uniform vec3 asphalt_color : source_color = vec3(0.22, 0.21, 0.20);
uniform vec3 sidewalk_color : source_color = vec3(0.62, 0.60, 0.56);
uniform vec3 curb_color : source_color = vec3(0.48, 0.46, 0.42);
uniform vec3 dirt_color : source_color = vec3(0.34, 0.30, 0.22);

varying vec2 v_world_xz;
varying vec3 v_normal;

vec2 world_to_uv(vec2 world_xz) {
	return (world_xz - lawn_origin) / lawn_size;
}

bool in_rect(vec2 p, vec4 bounds) {
	return p.x >= bounds.x && p.x <= bounds.z && p.y >= bounds.y && p.y <= bounds.w;
}

void vertex() {
	v_world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz.xz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = world_to_uv(v_world_xz);
	vec3 albedo = dirt_color;
	float rough = 0.95;

	if (in_rect(v_world_xz, street_bounds)) {
		float lane = sin(v_world_xz.y * 0.35) * 0.015;
		albedo = asphalt_color + vec3(lane);
		rough = 0.88;
	} else if (v_world_xz.x > street_bounds.z && v_world_xz.x < street_bounds.z + 2.2) {
		albedo = sidewalk_color;
		rough = 0.82;
	} else if (v_world_xz.x < street_bounds.x && v_world_xz.x > street_bounds.x - 2.2) {
		albedo = sidewalk_color * 0.96;
		rough = 0.82;
	} else if (abs(v_world_xz.x - street_bounds.z) < 0.18 || abs(v_world_xz.x - street_bounds.x) < 0.18) {
		albedo = curb_color;
	} else if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		vec4 mask = texture(mow_mask, uv);
		float cut = mask.r;
		vec2 mow_dir = mask.gb * 2.0 - 1.0;
		float stripe = dot(normalize(mow_dir + vec2(0.001)), normalize(VIEW.xz + vec2(0.001))) * 0.5 + 0.5;
		vec3 base = mix(tall_color, cut_color, cut);
		albedo = mix(base, stripe_color, stripe * stripe_strength * cut);
		rough = mix(0.92, 0.74, cut);
	}

	ALBEDO = albedo;
	ROUGHNESS = rough;
}
