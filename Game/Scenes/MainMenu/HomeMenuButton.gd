extends TextureButton
## Transparent main-menu artwork with matching mouse, keyboard and disabled states.

var base_tint = Color.WHITE
var hovered = false
var feedback_tween: Tween

func _ready() -> void:
 ignore_texture_size = true
 stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 focus_mode = Control.FOCUS_ALL
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 resized.connect(func(): pivot_offset = size * 0.5)
 mouse_entered.connect(func():
  hovered = true
  update_feedback())
 mouse_exited.connect(func():
  hovered = false
  update_feedback())
 focus_entered.connect(update_feedback)
 focus_exited.connect(update_feedback)
 button_down.connect(func(): update_feedback(true))
 button_up.connect(update_feedback)
 pivot_offset = size * 0.5
 update_feedback()

func update_feedback(pressed: bool = false) -> void:
 if is_instance_valid(feedback_tween): feedback_tween.kill()
 var tint = base_tint
 var zoom = 1.0
 if disabled:
  tint = Color(0.61, 0.56, 0.49, 0.85)
  mouse_default_cursor_shape = Control.CURSOR_ARROW
 elif pressed:
  tint = base_tint * Color(0.87, 0.84, 0.80, 1.0)
  zoom = 0.975
 elif hovered or has_focus():
  tint = base_tint * Color(1.12, 1.09, 1.04, 1.0)
  zoom = 1.025
 feedback_tween = create_tween().set_parallel(true)
 feedback_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
 feedback_tween.tween_property(self, "self_modulate", tint, 0.12)
 feedback_tween.tween_property(self, "scale", Vector2.ONE * zoom, 0.12)
