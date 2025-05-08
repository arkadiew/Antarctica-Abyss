shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_linear_mipmap;

uniform float normal_threshold = 0.1;
uniform float depth_threshold = 0.1; // Increased to focus on significant depth changes
uniform float depth_artifact_correction_coef = 2.0;
uniform vec3 outline_color : source_color;
uniform float pulse_speed = 1.0; // Скорость пульсации
uniform float pulse_intensity = 0.5; // Интенсивность пульсации

const mat3 sobel_x = mat3(
	vec3(1.0, 2.0, 1.0),
	vec3(0.0, 0.0, 0.0),
	vec3(-1.0, -2.0, -1.0)
);

const mat3 sobel_y = mat3(
	vec3(1.0, 0.0, -1.0),
	vec3(2.0, 0.0, -2.0),
	vec3(1.0, 0.0, -1.0)
);

float edge_value_normal(sampler2D normal_tex, vec2 uv, vec2 pixel_size) {
	vec3 normal = texture(normal_tex, uv).rgb * 2.0 - 1.0;
	vec3 n = texture(normal_tex, uv + vec2(0.0, -pixel_size.y)).rgb * 2.0 - 1.0;
	vec3 s = texture(normal_tex, uv + vec2(0.0, pixel_size.y)).rgb * 2.0 - 1.0;
	vec3 e = texture(normal_tex, uv + vec2(pixel_size.x, 0.0)).rgb * 2.0 - 1.0;
	vec3 w = texture(normal_tex, uv + vec2(-pixel_size.x, 0.0)).rgb * 2.0 - 1.0;

	// Compute normal differences to detect silhouette edges
	float edge = 0.0;
	edge += abs(dot(normal, n) < 0.9 ? 1.0 : 0.0); // Check for sharp normal changes
	edge += abs(dot(normal, s) < 0.9 ? 1.0 : 0.0);
	edge += abs(dot(normal, e) < 0.9 ? 1.0 : 0.0);
	edge += abs(dot(normal, w) < 0.9 ? 1.0 : 0.0);
	return edge;
}

float get_depth(sampler2D depth_tex, vec2 uv, mat4 inv_projection_matrix) {
	float depth_raw = texture(depth_tex, uv).x;
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth_raw);
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

float edge_value_depth(sampler2D depth_tex, vec2 uv, vec2 pixel_size, mat4 inv_projection_matrix) {
	float depth = get_depth(depth_tex, uv, inv_projection_matrix);
	float n = get_depth(depth_tex, uv + vec2(0.0, -pixel_size.y), inv_projection_matrix);
	float s = get_depth(depth_tex, uv + vec2(0.0, pixel_size.y), inv_projection_matrix);
	float e = get_depth(depth_tex, uv + vec2(pixel_size.x, 0.0), inv_projection_matrix);
	float w = get_depth(depth_tex, uv + vec2(-pixel_size.x, 0.0), inv_projection_matrix);

	// Detect significant depth discontinuities
	float edge = 0.0;
	float depth_diff_threshold = depth_threshold * depth;
	edge += abs(depth - n) > depth_diff_threshold ? 1.0 : 0.0;
	edge += abs(depth - s) > depth_diff_threshold ? 1.0 : 0.0;
	edge += abs(depth - e) > depth_diff_threshold ? 1.0 : 0.0;
	edge += abs(depth - w) > depth_diff_threshold ? 1.0 : 0.0;
	return edge;
}

void fragment() {
	vec2 pixel_size = vec2(1.0) / VIEWPORT_SIZE;
	float has_outline = 0.0;

	// Анимация пульсации
	float pulse = sin(TIME * pulse_speed) * pulse_intensity;
	vec3 pulse_color = outline_color * (1.0 + pulse);

	// Проверка текущего пикселя на наличие силуэтного края
	float normal_edge = edge_value_normal(NORMAL_TEXTURE, SCREEN_UV, pixel_size);
	float depth_edge = edge_value_depth(DEPTH_TEXTURE, SCREEN_UV, pixel_size, INV_PROJECTION_MATRIX);

	// Силуэтный край определяется значительными изменениями глубины или нормалей
	if (depth_edge > 0.0 || normal_edge > 0.0) {
		// Проверяем, является ли это краем объекта (глубина фона или другой объект)
		float depth = get_depth(DEPTH_TEXTURE, SCREEN_UV, INV_PROJECTION_MATRIX);
		bool is_silhouette = false;
		for (int i = -1; i <= 1; i++) {
			for (int j = -1; j <= 1; j++) {
				if (i == 0 && j == 0) continue;
				vec2 offset = vec2(float(i), float(j)) * pixel_size;
				float neighbor_depth = get_depth(DEPTH_TEXTURE, SCREEN_UV + offset, INV_PROJECTION_MATRIX);
				if (abs(depth - neighbor_depth) > depth_threshold * depth) {
					is_silhouette = true;
					break;
				}
			}
			if (is_silhouette) break;
		}

		if (is_silhouette) {
			ALBEDO = pulse_color;
			has_outline = 1.0;
		}
	}

	// Установка прозрачности
	ALPHA = has_outline;
}