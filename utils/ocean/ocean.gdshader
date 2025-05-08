shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// Параметры волн
uniform float wave_speed = 0.1;
uniform float wave_height = 0.0;
uniform vec2 wave_direction1 = vec2(1.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 0.1);
uniform float wave_steepness = 0.2;

// Параметры цвета и прозрачности
uniform vec3 shallow_color : source_color = vec3(0.0, 0.5, 0.6);
uniform vec3 deep_color : source_color = vec3(0.0, 0.2, 0.4);
uniform float transparency = 0.7;

// Параметры пены
uniform float foam_amount = 0.2;
uniform float foam_threshold = 0.4;
uniform sampler2D noise_texture : source_color, filter_linear_mipmap;

// Параметры каустики
uniform sampler2D caustic_texture : source_color, filter_linear_mipmap;
uniform float caustic_strength = 0.2;
uniform float caustic_speed = 0.1;

// Gerstner Wave функция
vec3 gerstner_wave(vec2 pos, vec2 direction, float steepness, float wavelength, float speed, float time) {
    float k = 2.0 * 3.14159265 / wavelength;
    float c = sqrt(9.8 / k);
    float d = dot(direction, pos);
    float f = k * (d - c * time * speed);
    float a = steepness / k;
    
    return vec3(
        direction.x * (a * cos(f)),
        a * sin(f),
        direction.y * (a * cos(f))
    );
}

void vertex() {
    // Вычисление волн Gerstner
    vec3 vertex = VERTEX;
    float time = TIME * wave_speed;
    
    // Первая волна
    vertex += gerstner_wave(VERTEX.xz, wave_direction1, wave_steepness, 8.0, wave_speed, time);
    // Вторая волна (для разнообразия)
    vertex += gerstner_wave(VERTEX.xz, wave_direction2, wave_steepness * 0.5, 4.0, wave_speed * 0.8, time);
    
    VERTEX = vertex;
}

void fragment() {
    // Нормали для освещения
    vec3 normal = normalize(NORMAL);
    
    // Цвет воды (градиент от мелководья к глубине)
    float depth = 1.0 - FRAGCOORD.z; // Примерный расчет глубины
    vec3 water_color = mix(shallow_color, deep_color, depth);
    
    // Пена (на основе текстуры шума и высоты волн)
    float noise = texture(noise_texture, UV + TIME * 0.05).r;
    float foam = smoothstep(foam_threshold, foam_threshold + 0.2, noise * foam_amount);
    water_color = mix(water_color, vec3(1.0), foam);
    
    // Каустика
    vec2 caustic_uv = UV + vec2(TIME * caustic_speed, 0.0);
    vec3 caustic = texture(caustic_texture, caustic_uv).rgb;
    water_color += caustic * caustic_strength;
    
    // Финальный цвет и свойства материала
    ALBEDO = water_color;
    METALLIC = 0.0;
    ROUGHNESS = 0.1;
    SPECULAR = 0.5;
    ALPHA = transparency; // Прозрачность
}
//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
