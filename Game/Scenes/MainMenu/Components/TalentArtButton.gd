extends TextureButton
## Only used by the approved talent view; keeps other menu controls unchanged.
const COPY = preload("res://Game/Scenes/MainMenu/Components/TalentText.gd")
var normal_rect = Rect2()
var selected_rect = Rect2()
var normal_texture: Texture2D
var selected_texture: Texture2D
var normal_center = Vector2.ZERO
var selected_center = Vector2.ZERO
var caption: Control
var caption_text = ""
var caption_size = 34
var cream = true
var choice = false
var is_route = false
var selection_badge: TextureRect
var selection_glow: TextureRect
var badge_copy: Control
var glow_rect = Rect2()
var badge_rect = Rect2()
var badge_center = Vector2.ZERO
var hovered = false
var feedback_tween: Tween
var normal_mask: BitMap
var selected_mask: BitMap

func _ready() -> void:
 ignore_texture_size = true
 stretch_mode = TextureButton.STRETCH_SCALE
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 focus_mode = Control.FOCUS_ALL
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 normal_mask = BitMap.new()
 normal_mask.create_from_image_alpha(normal_texture.get_image(),0.2)
 selected_mask = BitMap.new()
 selected_mask.create_from_image_alpha(selected_texture.get_image(),0.2)
 caption = COPY.new()
 caption.name = "RouteName" if is_route else ("DifficultyName" if choice else "Caption")
 add_child(caption)
 if is_route:
  selection_glow.show_behind_parent = true
  add_child(selection_glow)
  add_child(selection_badge)
  badge_copy = COPY.new()
  badge_copy.name = "SelectionCopy"
  selection_badge.add_child(badge_copy)
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
 toggled.connect(func(_value): update_feedback())
 update_feedback()

func update_feedback(pressed: bool = false) -> void:
 if not is_inside_tree(): return
 var selected = choice and button_pressed
 var rect = selected_rect if selected else normal_rect
 position = rect.position
 size = rect.size
 texture_normal = selected_texture if selected else normal_texture
 texture_click_mask = selected_mask if selected else normal_mask
 pivot_offset = size*0.5
 z_index = 1 if selected else 0
 var center = selected_center if selected else normal_center
 caption.configure(caption_text,center-position,caption_size,cream if is_route or not choice else selected)
 if is_route:
  selection_glow.visible = selected
  selection_glow.position = glow_rect.position-position
  selection_glow.size = glow_rect.size
  selection_badge.visible = selected
  selection_badge.position = badge_rect.position-position
  selection_badge.size = badge_rect.size
  badge_copy.configure("已选择",badge_center-badge_rect.position,29)
 mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
 var tint = Color.WHITE
 if pressed and not disabled: tint = Color(0.91,0.88,0.83)
 elif not disabled and (hovered or has_focus()): tint = Color(1.025,1.02,1.01)
 if is_instance_valid(feedback_tween): feedback_tween.kill()
 feedback_tween = create_tween()
 feedback_tween.tween_property(self,"self_modulate",tint,0.10)
 queue_redraw()

func set_selected(value: bool) -> void:
 set_pressed_no_signal(value)
 update_feedback()
