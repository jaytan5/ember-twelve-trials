extends Control
## Lightweight chapter scenery drawn directly in the UI.
var chapter: int = 0
var tint = Color("75cbb3")

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)

func _draw() -> void:
 var w = size.x
 var h = size.y
 draw_circle(Vector2(w * 0.78, h * 0.25), 23, Color(tint, 0.18))
 for layer in range(3):
  var points = PackedVector2Array([Vector2(0, h), Vector2(0, h * (0.5 + layer * 0.12))])
  for i in range(9):
   points.append(Vector2(w * i / 8.0, h * (0.4 + layer * 0.15) - sin(i * 1.7 + chapter + layer) * 15))
  points.append(Vector2(w, h))
  draw_colored_polygon(points, Color(tint, 0.07 + layer * 0.05))
 if chapter == 0:
  for i in range(5):
   var x = 30 + i * (w - 60) / 5
   draw_colored_polygon(PackedVector2Array([Vector2(x, h - 15), Vector2(x + 19, 18 + i % 2 * 15), Vector2(x + 38, h - 15)]), Color(tint, 0.35))
 elif chapter in [1, 3]:
  for i in range(4):
   var x = 40 + i * (w - 80) / 4
   draw_rect(Rect2(x, 28 + i % 2 * 18, 25, h - 28), Color(tint, 0.35))
   draw_rect(Rect2(x - 3, 23 + i % 2 * 18, 31, 9), Color(tint, 0.5))
 else:
  draw_polyline(PackedVector2Array([Vector2(w * 0.1, h * 0.8), Vector2(w * 0.42, h * 0.25), Vector2(w * 0.72, h * 0.8)]), Color(tint, 0.5), 3, true)
