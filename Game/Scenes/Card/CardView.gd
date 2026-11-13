extends Node
## 所有卡牌入口共享美术组件；点击与拖动仍由原有宿主负责。
const ARTWORK = preload("res://Game/Scenes/Card/CardArtwork.gd")

func card_view(ui: Control, id: String, action: Callable, hint: String = "", locked: bool = false) -> Button:
 var c = ui.Data.card(id)
 var node = Button.new()
 node.custom_minimum_size = Vector2(190, 286)
 node.set_meta("card_view", true)
 node.set_meta("card_id", id)
 node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 node.focus_mode = Control.FOCUS_NONE
 node.disabled = locked
 node.tooltip_text = "%s  /  %s 能量\n%s" % [c.name, ui.Data.cost_text(c), ui.Data.describe(c)]
 for state in ["normal", "hover", "pressed", "disabled", "focus"]:
  node.add_theme_stylebox_override(state, StyleBoxEmpty.new())
 node.pressed.connect(ui.settings.play_click)
 node.pressed.connect(action)
 var face = ARTWORK.new()
 node.add_child(face)
 face.setup(id, hint, locked)
 node.mouse_entered.connect(func():
  if not node.disabled: face.modulate = Color(1.09, 1.09, 1.06))
 node.mouse_exited.connect(func(): face.modulate = Color.WHITE)
 return node

