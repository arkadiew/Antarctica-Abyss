shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform vec4 outline_color : source_color;
uniform float outline_width = 2.0;

void fragment() {
    vec2 pixel_size = 1.0 / VIEWPORT_SIZE;
    vec4 current_color = texture(SCREEN_TEXTURE, SCREEN_UV);

    // Проверяем соседние пиксели
    bool has_transparent_neighbor = false;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            if (x == 0 && y == 0) continue;  // Пропускаем текущий пиксель
            vec2 offset = vec2(float(x), float(y)) * pixel_size * outline_width;
            vec4 neighbor_color = texture(SCREEN_TEXTURE, SCREEN_UV + offset);
            if (neighbor_color.a == 0.0) {
                has_transparent_neighbor = true;
                break;
            }
        }
        if (has_transparent_neighbor) break;
    }

    // Если есть прозрачный сосед, применяем обводку
    if (has_transparent_neighbor) {
        ALBEDO = outline_color.rgb;
        ALPHA = 1.0;
    } else {
        ALBEDO = current_color.rgb;
        ALPHA = current_color.a;
    }
}