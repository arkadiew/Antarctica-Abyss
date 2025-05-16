shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 10.0) = 2.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec3 color = vec3(0.0);
    float total = 0.0;
    
    // Реализация размытия (Gaussian blur)
    for (float x = -4.0; x <= 4.0; x += 1.0) {
        for (float y = -4.0; y <= 4.0; y += 1.0) {
            vec2 offset = vec2(x, y) * blur_amount / vec2(textureSize(screen_texture, 0));
            float weight = exp(-(x * x + y * y) / (2.0 * blur_amount * blur_amount));
            color += texture(screen_texture, UV + offset).rgb * weight;
            total += weight;
        }
    }
    
    color /= total;
    
    // Применяем прозрачность
    COLOR = vec4(color, opacity);
}