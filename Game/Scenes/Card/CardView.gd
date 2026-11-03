extends Node
## Scene-local view builder. Combat state and persistence belong to host services.

func card_view(ui: Control, id: String, action: Callable, hint: String = "", locked: bool = false) -> Button:
 var c = ui.Data.card(id)
 var tint = Color(ui.Data.ROUTES[c.route].color) if ui.Data.ROUTES.has(c.route) else ui.GOLD
 var node = Button.new()
 node.custom_minimum_size = Vector2(190, 260)
 node.set_meta("card_view", true)
 node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 node.focus_mode = Control.FOCUS_NONE
 node.disabled = locked
 node.tooltip_text = "%s  /  %s 能量\n%s" % [c.name, ui.Data.cost_text(c), ui.Data.describe(c)]
 node.add_theme_stylebox_override("normal", ui.box(Color("1a2b3b"), Color(tint, 0.6), 12, 0))
 node.add_theme_stylebox_override("hover", ui.box(Color("2a3d50"), tint, 12, 0))
 node.add_theme_stylebox_override("disabled", ui.box(Color("141d2a"), Color("354050"), 12, 0))
 node.pressed.connect(ui.settings.play_click)
 node.pressed.connect(action)
 var inset = MarginContainer.new()
 inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left", "right", "top", "bottom"]: inset.add_theme_constant_override("margin_" + edge, 14)
 inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
 node.add_child(inset)
 var body = ui.column(7)
 body.mouse_filter = Control.MOUSE_FILTER_IGNORE
 body.modulate = Color(1, 1, 1, 0.45) if locked else Color.WHITE
 inset.add_child(body)
 var heading = ui.row()
 heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
 heading.add_child(ui.label(ui.Data.cost_text(c), 30, tint))
 ui.spacer(heading)
 heading.add_child(ui.label(c.kind + ("  " + hint if hint != "" else ""), 13, ui.MUTED))
 body.add_child(heading)
 body.add_child(ui.label(c.name, 22, tint))
 var sep = HSeparator.new()
 sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
 body.add_child(sep)
 var description = ui.paragraph(ui.Data.describe(c), 14, ui.TEXT)
 description.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_child(description)
 body.add_child(ui.label("单体 · 当前目标" if c.get("target", false) else "自身 / 全体效果", 12, ui.MUTED))
 return node

