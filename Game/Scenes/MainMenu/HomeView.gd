extends Node

func build_home(ui: Control) -> void:
 var center = CenterContainer.new()
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 ui.layout.add_child(center)
 var frame = ui.panel(ui.PANEL, Color("4c5060"), 40)
 frame.custom_minimum_size = Vector2(1250, 650)
 center.add_child(frame)
 var content = ui.row(70)
 frame.add_child(content)
 var left = ui.column(24)
 left.custom_minimum_size.x = 650
 content.add_child(left)
 left.add_child(ui.label("EMBER  /  TWELVE TRIALS", 16, ui.GOLD))
 left.add_child(ui.label("余烬十二关", 64))
 left.add_child(ui.paragraph("带上一副卡牌，走过四片土地。\n下一段冒险，从这里开始。", 24))
 var spacer = Control.new()
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 left.add_child(spacer)
 for item in [["开始新冒险", "HomeNew", ui.open_new_routes], ["继续冒险", "HomeContinue", ui.open_continue_routes], ["设置", "HomeSettings", ui.show_settings]]:
  var action = ui.button(item[0], item[2], item[1] == "HomeNew")
  action.name = item[1]
  action.custom_minimum_size = Vector2(440, 58)
  action.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
  if item[1] == "HomeContinue": action.disabled = not FileAccess.file_exists("user://run_save.json")
  left.add_child(action)
 var portrait = ui.make_portrait(true)
 portrait.custom_minimum_size = Vector2(390, 550)
 content.add_child(portrait)
