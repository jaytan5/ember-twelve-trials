extends Node
## Scene-local view builder. Combat state and persistence belong to host services.

func build_menu(ui: Control) -> void:
 var lead = ui.panel(ui.PANEL, Color("3b4657"), 28)
 lead.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var lead_box = ui.column(16)
 lead.add_child(lead_box)
 lead_box.add_child(ui.label("确认你的冒险路线。" if ui.resuming else "从微火出发，挑战四座王座。", 38))
 var flex = Control.new()
 flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
 lead_box.add_child(flex)
 lead_box.add_child(ui.label("01  /  选择你的起始路线", 18, ui.GOLD))
 var routes = ui.row(18)
 for id in ["venom", "bastion", "fury"]:
  var r: Dictionary = ui.Data.ROUTES[id]
  var tint = Color(r.color)
  var tile = ui.panel(Color("192638") if id == ui.selected_route else ui.PANEL, tint if id == ui.selected_route else Color("334359"), 22)
  tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  var content = ui.column(12)
  tile.add_child(content)
  content.add_child(ui.label(r.name + ("  /  已选择" if id == ui.selected_route else ""), 27, tint))
  content.add_child(ui.label(r.tag, 16, tint))
  content.add_child(ui.paragraph(r.desc, 17))
  content.add_child(ui.label("初始生命 %d  ·  17 张卡牌" % r.hp, 15))
  var pick = ui.button("选择「%s」" % r.name, func():
   ui.selected_route = id
   ui.render(), id == ui.selected_route)
  pick.name = "Route_" + id
  pick.disabled = ui.resuming
  content.add_child(pick)
  routes.add_child(tile)
 lead_box.add_child(routes)
 var difficulty_row = ui.row(12)
 difficulty_row.add_child(ui.label("02  /  选择难度", 18, ui.GOLD))
 for id in ["easy", "normal", "hard", "legendary"]:
  var choice = ui.button(ui.Data.DIFFICULTIES[id].name + (" · 已选" if id == ui.selected_difficulty else ""), func():
   ui.selected_difficulty = id
   ui.render(), id == ui.selected_difficulty)
  choice.name = "Difficulty_" + id
  choice.disabled = ui.resuming
  choice.custom_minimum_size.x = 160
  difficulty_row.add_child(choice)
 lead_box.add_child(difficulty_row)
 var difficulty_description = ui.paragraph(ui.Data.DIFFICULTIES[ui.selected_difficulty].desc + " 本局开始后固定，继续存档沿用原难度。", 15, ui.GREEN)
 difficulty_description.name = "DifficultyDescription"
 lead_box.add_child(difficulty_description)
 ui.layout.add_child(lead)
 var actions = ui.row(14)
 var start = ui.button("确认路线 · 继续冒险  →" if ui.resuming else "确认路线 · 开始冒险  →", ui.confirm_route, true)
 start.name = "ConfirmRoute"
 start.custom_minimum_size = Vector2(340, 54)
 actions.add_child(start)
 actions.add_child(ui.button("返回主界面", ui.return_home))
 ui.spacer(actions)
 ui.layout.add_child(actions)
