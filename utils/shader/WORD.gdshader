shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Цвет свечения
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.0; // Интенсивность свечения
uniform float glow_radius : hint_range(0.0, 10.0) = 2.0; // Радиус свечения
uniform float glow_pulse_speed : hint_range(0.0, 5.0) = 1.0; // Скорость пульсации (0 — без пульсации)

void fragment() {
    // Получаем исходный цвет текста
    vec4 text_color = texture(TEXTURE, UV);
    
    // Вычисляем свечение
    float glow = 0.0;
    vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0)); // Размер пикселя в UV-координатах
    
    // Пульсация свечения (опционально)
    float pulse = sin(TIME * glow_pulse_speed) * 0.5 + 0.5; // Значение от 0 до 1
    float dynamic_glow = glow_intensity * (1.0 + pulse * 0.5);
    
    // Проходим по соседним пикселям для создания размытия (эффект свечения)
    for (float x = -glow_radius; x <= glow_radius; x += 1.0) {
        for (float y = -glow_radius; y <= glow_radius; y += 1.0) {
            vec2 offset = vec2(x, y) * pixel_size;
            float dist = length(vec2(x, y)) / glow_radius;
            if (dist <= 1.0) {
                float sample_alpha = texture(TEXTURE, UV + offset).a;
                glow += sample_alpha * (1.0 - dist) * dynamic_glow;
            }
        }
    }
    
    // Ограничиваем свечение, чтобы оно не было слишком ярким
    glow = clamp(glow, 0.0, 1.0);
    
    // Комбинируем свечение с исходным цветом текста
    vec4 final_color = text_color + glow * glow_color;
    final_color.a = text_color.a + glow; // Учитываем альфа-канал
    
    COLOR = final_color;
}