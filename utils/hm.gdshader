shader_type spatial;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Желтый цвет
uniform float outline_thickness : hint_range(0.0, 0.1) = 0.02;

void fragment() {
    // Получаем нормаль текущего пикселя
    vec3 normal = normalize(NORMAL);
    
    // Получаем нормали соседних пикселей
    vec3 normal_right = normalize(dFdx(NORMAL));
    vec3 normal_down = normalize(dFdy(NORMAL));
    
    // Вычисляем разницу между нормалями
    float edge = max(length(normal_right), length(normal_down));
    
    // Применяем обводку только на краях
    if (edge > outline_thickness) {
        ALBEDO = outline_color.rgb;
    } else {
        ALBEDO = vec3(0.0);
    }
}