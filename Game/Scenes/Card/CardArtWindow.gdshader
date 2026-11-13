shader_type canvas_item;
// Godot 4: COLOR in fragment() already equals texture(TEXTURE, UV) * modulate.
// Multiplying by texture(TEXTURE, UV) again squares every channel and darkens the art.
uniform float saturation = 1.0;

void fragment() {
 vec2 dimensions = vec2(796.0, 454.0);
 vec2 q = abs((UV - 0.5) * dimensions) - (dimensions * 0.5 - 58.0);
 float distance_to_edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - 58.0;
 float gray = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
 COLOR.rgb = mix(vec3(gray), COLOR.rgb, saturation);
 COLOR.a *= 1.0 - smoothstep(-1.0, 1.0, distance_to_edge);
}
