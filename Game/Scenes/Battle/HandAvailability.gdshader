shader_type canvas_item;
// Godot 4: COLOR in fragment() already equals texture(TEXTURE, UV) * modulate.
// Sampling the texture again would square every channel and darken the whole card.
uniform float saturation = 1.0;

void fragment() {
 float gray = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
 COLOR.rgb = mix(vec3(gray), COLOR.rgb, saturation);
}
