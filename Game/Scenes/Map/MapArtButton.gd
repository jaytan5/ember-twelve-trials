extends TextureButton
## 轮廓始终固定；反馈只改变内部受光，透明边缘不拦截点击。
var hovered = false

func _ready() -> void:
 ignore_texture_size = true
 stretch_mode = TextureButton.STRETCH_SCALE
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 var mask = BitMap.new()
 mask.create_from_image_alpha(texture_normal.get_image(),0.2)
 texture_click_mask = mask
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
 update_feedback()

func update_feedback(pressed: bool = false) -> void:
 mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
 var tint = Color.WHITE
 if disabled: tint = Color(.70,.67,.63,.92)
 elif pressed: tint = Color(.86,.83,.78)
 elif hovered or has_focus(): tint = Color(1.07,1.045,1.015)
 self_modulate = tint
