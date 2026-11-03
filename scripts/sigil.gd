extends Control
## Replace this placeholder with a Sprite2D or illustration later.
var tint = Color("75cbb3")
var boss = false

func _draw() -> void:
 var center = size / 2.0
 var radius = minf(size.x, size.y) * (0.28 if boss else 0.38)
 if boss: center.y += 10
 draw_circle(center, radius, Color(tint, 0.08))
 draw_arc(center, radius, 0, TAU, 64, Color(tint, 0.38), 1.5, true)
 var points = PackedVector2Array()
 var count = 6 if boss else 4
 for i in range(count):
  var a = -PI / 2.0 + TAU * i / count
  points.append(center + Vector2(cos(a), sin(a)) * radius * 0.72)
 draw_colored_polygon(points, Color(tint, 0.15))
 points.append(points[0])
 draw_polyline(points, tint, 2.5, true)
 draw_line(center + Vector2(-radius * 0.27, -4), center + Vector2(-radius * 0.10, 2), tint, 3, true)
 draw_line(center + Vector2(radius * 0.10, 2), center + Vector2(radius * 0.27, -4), tint, 3, true)
 if boss:
  var crown = PackedVector2Array([center + Vector2(-23, -radius - 5), center + Vector2(-23, -radius - 19), center + Vector2(-11, -radius - 10), center + Vector2(0, -radius - 26), center + Vector2(11, -radius - 10), center + Vector2(23, -radius - 19), center + Vector2(23, -radius - 5)])
  draw_polyline(crown, tint, 2, true)
