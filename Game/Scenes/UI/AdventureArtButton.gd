extends "res://Game/Scenes/MainMenu/HomeMenuButton.gd"
## 对话框按钮保持固定轮廓；按下只改变内部受光与文字深度。

func update_feedback(pressed: bool = false) -> void:
 if is_instance_valid(feedback_tween): feedback_tween.kill()
 scale = Vector2.ONE
 var tint = base_tint
 mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
 if disabled:
  tint = Color(0.63, 0.60, 0.55, 0.83)
 elif pressed:
  tint = base_tint * Color(0.83, 0.80, 0.76, 1.0)
 elif hovered or has_focus():
  tint = base_tint * Color(1.10, 1.075, 1.025, 1.0)
 feedback_tween = create_tween().set_parallel(true)
 feedback_tween.tween_property(self, "self_modulate", tint, 0.10)
 if is_instance_valid(caption_label):
  var inset = -1.0 if pressed and not disabled else -3.0
  feedback_tween.tween_property(caption_label, "offset_top", inset, 0.10)
  feedback_tween.tween_property(caption_label, "offset_bottom", inset, 0.10)
