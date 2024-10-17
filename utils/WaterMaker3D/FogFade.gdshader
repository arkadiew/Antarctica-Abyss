shader_type fog;

uniform float density : hint_range(0, 1, 0.0001) = 1.0;
uniform vec4 albedo : source_color = vec4(1.0); // Fog color
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Emissive color of fog
uniform float height_falloff = 0.0; // Controls how fog fades with height
uniform float edge_fade = 0.1; // Controls fog's edge fading
uniform sampler2D pixel_texture: hint_default_white; // 2D texture for pixel modulation
uniform vec4 fade_plane = vec4(0.0, 1.0, 0.0, -999.0); // Defines a plane where fog will start to fade

void fog() {
    // Calculate base density affected by height falloff
    DENSITY = density * clamp(exp2(-height_falloff * (WORLD_POSITION.y - OBJECT_POSITION.y)), 0.0, 1.0);
    
    // Calculate UV coordinates based on WORLD_POSITION
    vec2 uv = WORLD_POSITION.xy * 0.1; // Scale to avoid repetition in texture sampling
    
    // Modulate density with the 2D texture (pixel-based modulation)
    DENSITY *= texture(pixel_texture, uv).r; // Use the red channel of the texture for density modulation
    
    // Apply edge fading based on SDF (signed distance function)
    DENSITY *= pow(clamp(-2.0 * SDF / min(min(SIZE.x, SIZE.y), SIZE.z), 0.0, 1.0), edge_fade);
    
    // Set the fog color and emissive values
    ALBEDO = albedo.rgb;
    EMISSION = emission.rgb;
    
    // Fade fog based on distance from the fade plane
    float fade_sharpness = 0.35; // Higher value = faster fade
    vec3 fade_plane_origin = fade_plane.xyz * fade_plane.w;
    vec3 pos_rel_to_plane = WORLD_POSITION - fade_plane_origin;
    float fade_mult = max(0.0, min(1.0, dot(pos_rel_to_plane, fade_plane.xyz) * fade_sharpness));
    
    // Apply fade multiplier and alpha transparency to the fog density
    DENSITY *= fade_mult * albedo.a;
}
