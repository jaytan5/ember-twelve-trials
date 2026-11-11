extends Node
## Scene-local view builder. Combat state and persistence belong to host services.

func health_bar(ui: Control, hp: int, maximum: int, tint: Color, width: int = 0) -> Control:
 var holder = Control.new()
 holder.custom_minimum_size = Vector2(width, 23)
 holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var bar = ProgressBar.new()
 bar.name = "HealthFill"
 bar.step = 0.01
 bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 bar.max_value = maximum
 bar.value = hp
 bar.show_percentage = false
 bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bar.add_theme_stylebox_override("background", ui.box(Color("0a111e"), Color.TRANSPARENT, 6, 0))
 bar.add_theme_stylebox_override("fill", ui.box(Color(tint, 0.55), Color.TRANSPARENT, 6, 0))
 holder.add_child(bar)
 var caption = ui.label("%d / %d" % [hp, maximum], 14)
 caption.name = "HealthCaption"
 caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 holder.add_child(caption)
 return holder
