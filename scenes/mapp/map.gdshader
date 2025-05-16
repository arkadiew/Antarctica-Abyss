shader_type canvas_item;

// Параметры для настройки
uniform vec4 primary_color : source_color = vec4(0.0, 1.0, 0.5, 1.0); // Основной цвет (например, зеленый)
uniform vec4 secondary_color : source_color = vec4(0.2, 0.8, 1.0, 1.0); // Дополнительный цвет (например, голубой)
uniform float fade_distance : hint_range(0.0, 1.0) = 0.4; // Дистанция затухания
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5; // Скорость пульсации
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.3; // Интенсивность пульсации
uniform float grid_strength : hint_range(0.0, 1.0) = 0.2; // Сила сетки
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.5; // Интенсивность свечения
uniform float noise_scale : hint_range(0.0, 10.0) = 5.0; // Масштаб шума

// Функция генерации шума (Perlin-like noise)
float noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(127.1, 311.7))) * 43758.5453);
}

// Функция для создания сетки
float grid(vec2 uv, float scale) {
    vec2 grid_uv = fract(uv * scale);
    float grid_x = step(0.95, grid_uv.x) + step(0.95, grid_uv.y);
    return grid_x;
}

// ... (rest of the shader code remains unchanged until the fragment function)

void fragment() {
    vec2 uv = UV - vec2(0.5); // Центрируем UV
    float dist = length(uv); // Расстояние от центра

    // Мягкий радиальный градиент
    float fade = smoothstep(0.5, 0.5 - fade_distance, dist);

    // Эффект пульсации (две волны для большей динамики)
    float pulse1 = sin(TIME * pulse_speed - dist * 12.0) * pulse_intensity;
    float pulse2 = sin(TIME * pulse_speed * 0.5 - dist * 8.0) * pulse_intensity * 0.5;
    float pulse = pulse1 + pulse2;

    // Шум для текстуры
    float noise_value = noise(uv * noise_scale + TIME * 0.1) * 0.1;

    // Сетка
    float grid_value = grid(uv + vec2(TIME * 0.05), 10.0) * grid_strength * fade;

    // Интенсивность с учетом всех эффектов
    float intensity = (fade + pulse + noise_value + grid_value) * (1.0 + glow_intensity * fade);
    intensity = clamp(intensity, 0.0, 1.0);

    // Градиент между основным и дополнительным цветами
    vec4 color = mix(secondary_color, primary_color, intensity);
    color.a *= intensity;

    // Черный фон
    vec4 background_color = vec4(0.0, 0.0, 0.0, 1.0);
    // Изменяем смешивание, чтобы фон был полностью непрозрачным
    COLOR = vec4(mix(background_color.rgb, color.rgb, intensity), 1.0);

    // Добавляем легкое свечение
    COLOR.rgb += vec3(glow_intensity * fade * 0.2);
}