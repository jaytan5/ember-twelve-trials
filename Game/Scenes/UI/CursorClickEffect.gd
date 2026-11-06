extends Node2D
## 点击位置的短促金色光圈，不参与 GUI 命中或拦截输入。
const LIFETIME = 0.32
var elapsed = 0.0

func _process(delta: float) -> void:
 elapsed += delta
 if elapsed >= LIFETIME:
  queue_free()
 else:
  queue_redraw()

func _draw() -> void:
 var progress = clampf(elapsed / LIFETIME, 0.0, 1.0)
 var spread = 1.0 - pow(1.0 - progress, 2.0)
 var opacity = pow(1.0 - progress, 1.5)
 var radius = lerpf(4.0, 17.0, spread)
 draw_arc(Vector2(0, 1), radius, 0, TAU, 40, Color(0.18, 0.09, 0.04, opacity * 0.22), 3.0, true)
 draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(1.0, 0.78, 0.32, opacity * 0.85), 1.6, true)
 draw_circle(Vector2.ZERO, lerpf(3.0, 0.5, spread), Color(1.0, 0.95, 0.74, opacity * 0.65))
 for index in range(4):
  var direction = Vector2.from_angle(PI * 0.25 + index * PI * 0.5)
  var distance = lerpf(7.0, 21.0, spread)
  draw_line(direction * distance, direction * (distance + lerpf(4.0, 1.0, progress)), Color(1.0, 0.88, 0.55, opacity), 1.5, true)
