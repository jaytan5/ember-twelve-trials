extends TextureButton
## Shared art control: real alpha hit area, keyboard focus, toggle and disabled feedback.
var base_tint = Color.WHITE
var hovered = false
var feedback_tween: Tween
var caption: Label
var caption_text = ""
var caption_font: Font
var font_ratio = 0.39
var choice = false
var selection_badge: Control
var wide_selection_badge = false
var glow_color = Color("ffca59")
var outline_material: ShaderMaterial
const OUTLINE = preload("res://Game/Scenes/MainMenu/Components/SelectionOutline.gdshader")
const BADGE = preload("res://Game/Scenes/MainMenu/Components/SelectionBadge.gd")

func _ready() -> void:
 ignore_texture_size = true
 stretch_mode = TextureButton.STRETCH_SCALE
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 focus_mode = Control.FOCUS_ALL
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 if texture_normal != null:
  var mask = BitMap.new()
  mask.create_from_image_alpha(texture_normal.get_image(), 0.2)
  texture_click_mask = mask
 outline_material = ShaderMaterial.new()
 outline_material.shader = OUTLINE
 material = outline_material
 outline_material.set_shader_parameter("glow_color",glow_color)
 outline_material.set_shader_parameter("saturation",1.0)
 if choice:
  selection_badge = Control.new()
  selection_badge.set_script(BADGE)
  selection_badge.name = "SelectionBadge"
  selection_badge.wide = wide_selection_badge
  selection_badge.title_font = caption_font
  add_child(selection_badge)
 if not caption_text.is_empty():
  caption = Label.new()
  caption.name = "Caption"
  caption.text = caption_text
  caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
  caption.add_theme_color_override("font_color", Color("fff0c1"))
  caption.add_theme_color_override("font_outline_color", Color("49240d"))
  caption.add_theme_constant_override("outline_size", 3)
  if caption_font != null: caption.add_theme_font_override("font", caption_font)
  add_child(caption)
  caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 resized.connect(update_metrics)
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
 update_metrics()
 update_feedback()

func update_metrics() -> void:
 pivot_offset = size * 0.5
 if outline_material != null: outline_material.set_shader_parameter("rect_size",size)
 if is_instance_valid(selection_badge):
  selection_badge.size = Vector2(112,32) if wide_selection_badge else Vector2(28,28)
  selection_badge.position = Vector2((size.x-112)*0.5,size.y+6) if wide_selection_badge else Vector2(size.x-19,4)
 if is_instance_valid(caption): caption.add_theme_font_size_override("font_size", maxi(16, int(size.y * font_ratio)))

func update_feedback(pressed: bool = false) -> void:
 if not is_inside_tree(): return
 if is_instance_valid(feedback_tween): feedback_tween.kill()
 var selected = choice and button_pressed
 var tint = base_tint
 var zoom = 1.0
 var saturation = 1.0
 if choice:
  zoom = 1.035 if selected else 0.98
  if not selected:
   tint *= Color(0.80,0.80,0.79,1.0)
   saturation = 0.62
  else:
   tint *= Color(1.05,1.035,1.0,1.0)
  selection_badge.visible = selected
  z_index = 2 if selected else 0
 if disabled:
  tint *= Color(0.97,0.95,0.90,1.0) if selected else Color(0.93,0.92,0.90,1.0)
  mouse_default_cursor_shape = Control.CURSOR_ARROW
 elif pressed:
  tint *= Color(0.86,0.83,0.78,1.0)
  zoom *= 0.985
 else:
  mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  if hovered or has_focus():
   tint *= Color(1.06,1.05,1.02,1.0)
   zoom *= 1.008 if choice else 1.02
 if outline_material != null:
  outline_material.set_shader_parameter("highlight", selected if choice else has_focus())
  outline_material.set_shader_parameter("hover_light", (hovered or has_focus()) and not disabled)
 feedback_tween = create_tween().set_parallel(true)
 feedback_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
 feedback_tween.tween_property(self,"self_modulate",tint,0.12)
 feedback_tween.tween_property(self,"scale",Vector2.ONE * zoom,0.12)
 feedback_tween.tween_method(func(value): outline_material.set_shader_parameter("saturation",value),float(outline_material.get_shader_parameter("saturation")),saturation,0.12)

func set_selected(value: bool) -> void:
 set_pressed_no_signal(value)
 update_feedback()
