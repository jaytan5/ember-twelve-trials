extends TextureButton
## Orthographic menu artwork, alpha-aware input and resolution-independent labels.

const CAPTION_FONT = preload("res://Game/Assets/Fonts/主菜单按钮粗体.tres")

var base_tint = Color.WHITE
var hovered = false
var feedback_tween: Tween
var caption_label: Label

func set_caption(value: String) -> void:
 if value.is_empty(): return
 caption_label = Label.new()
 caption_label.name = "ButtonCaption"
 caption_label.text = value
 caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 caption_label.add_theme_font_override("font", CAPTION_FONT)
 caption_label.add_theme_font_size_override("font_size", 43)
 caption_label.add_theme_color_override("font_color", Color("fff0d0"))
 caption_label.add_theme_color_override("font_outline_color", Color("432015"))
 caption_label.add_theme_constant_override("outline_size", 4)
 caption_label.add_theme_color_override("font_shadow_color", Color(0.18, 0.07, 0.03, 0.75))
 caption_label.add_theme_constant_override("shadow_offset_x", 0)
 caption_label.add_theme_constant_override("shadow_offset_y", 2)
 add_child(caption_label)
 caption_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 # The texture region includes extra lower shadow: align text to the enamel face.
 caption_label.offset_top = -3
 caption_label.offset_bottom = -3

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
 mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
 if disabled:
  tint = Color(0.68, 0.64, 0.58, 0.90)
 elif pressed:
  tint = base_tint * Color(0.87, 0.84, 0.80, 1.0)
  zoom = 0.985
 elif hovered or has_focus():
  tint = base_tint * Color(1.06, 1.045, 1.02, 1.0)
  zoom = 1.015
 feedback_tween = create_tween().set_parallel(true)
 feedback_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
 feedback_tween.tween_property(self, "self_modulate", tint, 0.12)
 feedback_tween.tween_property(self, "scale", Vector2.ONE * zoom, 0.12)
