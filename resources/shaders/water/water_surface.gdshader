// Water surface shader for Sunken Atoll prototype.
// Per specs/features/water_shader.md §3.1 and specs/epics/prototype_phase.md §4.
//
// Implements:
//   - Vertex displacement via 3 stacked Gerstner waves
//   - Fresnel-weighted sky/reflection blend
//   - Depth-based shallow/deep color mix
//   - Foam mask at shallow intersections
//   - Tide offset (driven from script — uniform `tide_offset`)
//
// All artistic parameters are exposed as uniforms so per-environment-band
// presets can override them via .tres material resources.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// --- Color & blending ---
uniform vec4 deep_color : source_color = vec4(0.05, 0.20, 0.30, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.30, 0.65, 0.70, 0.85);
uniform float depth_fade_distance : hint_range(0.0, 50.0) = 8.0;

// --- Surface response ---
uniform float roughness_base : hint_range(0.0, 1.0) = 0.05;
uniform float metallic_base : hint_range(0.0, 1.0) = 0.0;
uniform float fresnel_power : hint_range(0.5, 8.0) = 4.0;

// --- Foam ---
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float foam_distance : hint_range(0.0, 5.0) = 0.6;
uniform sampler2D foam_noise : hint_default_white;
uniform float foam_noise_scale : hint_range(0.1, 10.0) = 4.0;

// --- Depth texture (Godot 4.6+ requires explicit uniform with hint) ---
// In earlier Godot 4 versions DEPTH_TEXTURE was an implicit built-in;
// 4.6 removed that and now requires an explicit uniform declaration so
// the engine can wire the screen-space depth attachment.
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

// --- Wave parameters (3 stacked Gerstner waves) ---
uniform vec2 wave_dir_a = vec2(1.0, 0.0);
uniform vec2 wave_dir_b = vec2(0.7, 0.7);
uniform vec2 wave_dir_c = vec2(-0.3, 0.95);
uniform float wave_amplitude_a : hint_range(0.0, 2.0) = 0.30;
uniform float wave_amplitude_b : hint_range(0.0, 2.0) = 0.18;
uniform float wave_amplitude_c : hint_range(0.0, 2.0) = 0.10;
uniform float wave_length_a : hint_range(0.5, 50.0) = 8.0;
uniform float wave_length_b : hint_range(0.5, 50.0) = 5.0;
uniform float wave_length_c : hint_range(0.5, 50.0) = 3.0;
uniform float wave_steepness : hint_range(0.0, 1.0) = 0.5;

// --- Time-varying inputs (driven by day_night_cycle.gd via uniforms) ---
uniform float tide_offset = 0.0;
uniform float storm_intensity : hint_range(0.0, 1.0) = 0.0;

// Per-instance varying so fragment can sample world position cheaply.
varying vec3 world_position;

vec3 gerstner(vec3 pos, vec2 dir_unnorm, float amplitude, float wave_length, float steepness, float t) {
	vec2 dir = normalize(dir_unnorm);
	float k = 6.2831853 / max(wave_length, 0.001);
	float c = sqrt(9.8 / k);
	float f = k * (dot(dir, pos.xz) - c * t);
	float a = amplitude * (1.0 + storm_intensity * 1.5);
	float qa = steepness * a;
	return vec3(qa * dir.x * cos(f), a * sin(f), qa * dir.y * cos(f));
}

void vertex() {
	vec3 base = VERTEX;
	float t = TIME;

	vec3 d = vec3(0.0);
	d += gerstner(base, wave_dir_a, wave_amplitude_a, wave_length_a, wave_steepness, t);
	d += gerstner(base, wave_dir_b, wave_amplitude_b, wave_length_b, wave_steepness, t);
	d += gerstner(base, wave_dir_c, wave_amplitude_c, wave_length_c, wave_steepness, t);

	VERTEX += d;
	VERTEX.y += tide_offset;

	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Numerical normals via finite difference of nearby gerstner samples.
	float eps = 0.5;
	vec3 px = base + vec3(eps, 0.0, 0.0);
	vec3 pz = base + vec3(0.0, 0.0, eps);
	vec3 dx = gerstner(px, wave_dir_a, wave_amplitude_a, wave_length_a, wave_steepness, t)
	        + gerstner(px, wave_dir_b, wave_amplitude_b, wave_length_b, wave_steepness, t)
	        + gerstner(px, wave_dir_c, wave_amplitude_c, wave_length_c, wave_steepness, t);
	vec3 dz = gerstner(pz, wave_dir_a, wave_amplitude_a, wave_length_a, wave_steepness, t)
	        + gerstner(pz, wave_dir_b, wave_amplitude_b, wave_length_b, wave_steepness, t)
	        + gerstner(pz, wave_dir_c, wave_amplitude_c, wave_length_c, wave_steepness, t);
	vec3 t_x = normalize(vec3(eps, dx.y - d.y, 0.0));
	vec3 t_z = normalize(vec3(0.0, dz.y - d.y, eps));
	NORMAL = normalize(cross(t_z, t_x));
}

void fragment() {
	// Depth-based shallow/deep color mix.
	float depth = FRAGCOORD.z;
	float linear_depth = depth_fade_distance;
	// Approximate underwater depth using the difference between this surface
	// and whatever opaque object is behind it. Requires depth texture access,
	// which Godot 4 exposes through DEPTH_TEXTURE.
	float scene_z = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).x;
	vec4 ndc = vec4(SCREEN_UV * 2.0 - 1.0, scene_z, 1.0);
	vec4 view = INV_PROJECTION_MATRIX * ndc;
	view.xyz /= view.w;
	float behind_depth = -view.z;
	float surface_depth = -VIEW.z;
	float water_depth = clamp(behind_depth - surface_depth, 0.0, depth_fade_distance);

	float depth_t = water_depth / depth_fade_distance;
	vec3 base_color = mix(shallow_color.rgb, deep_color.rgb, depth_t);

	// Foam where water is very shallow.
	float foam_t = 1.0 - clamp(water_depth / foam_distance, 0.0, 1.0);
	vec2 foam_uv = world_position.xz * (1.0 / foam_noise_scale) + vec2(TIME * 0.05, TIME * 0.03);
	float foam_n = texture(foam_noise, foam_uv).r;
	float foam_mask = step(0.5, foam_n) * foam_t;

	ALBEDO = mix(base_color, foam_color.rgb, foam_mask);

	// Roughness rises slightly under storm; mostly mirror-like otherwise.
	ROUGHNESS = clamp(roughness_base + storm_intensity * 0.15, 0.0, 1.0);
	METALLIC = metallic_base;

	// Fresnel-driven specular emphasis (PBR pipeline already does Schlick;
	// we just bias the rim a bit so reflections read clearly at glancing angles).
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
	SPECULAR = mix(0.5, 1.0, fresnel);

	// Slight transparency in shallow water so sea bed shows through.
	ALPHA = mix(shallow_color.a, 1.0, depth_t);
}
