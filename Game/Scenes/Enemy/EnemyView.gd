extends Node
## Scene-local view builder. Combat state and persistence belong to host services.

func enemy_view(ui: Control, index: int) -> Button:
 var e: Dictionary = ui.game.s.enemies[index]
 var alive: bool = e.hp > 0
 var selected: bool = index == ui.game.s.target and alive
 var tint = ui.GOLD if e.boss else ui.GREEN
 var tile = Button.new()
 tile.name = "EnemyPanel%d" % index
 tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 tile.custom_minimum_size.y = 190
 tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 tile.focus_mode = Control.FOCUS_NONE
 tile.add_theme_stylebox_override("normal", ui.box(Color("213345") if selected else Color("121c2a"), tint if selected else Color("2a3a50"), 12, 0))
 tile.add_theme_stylebox_override("hover", ui.box(Color("24354a"), tint, 12, 0))
 tile.disabled = not alive
 tile.pressed.connect(ui.settings.play_click)
 tile.pressed.connect(func():
  if ui.busy: return
  ui.game.select_target(index)
  ui.message = "目标已锁定：" + e.name
  ui.commit())
 var inset = MarginContainer.new()
 inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left", "right", "top", "bottom"]: inset.add_theme_constant_override("margin_" + edge, 12)
 inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
 tile.add_child(inset)
 var content = ui.column(5)
 content.mouse_filter = Control.MOUSE_FILTER_IGNORE
 inset.add_child(content)
 var intent_color = ui.MUTED
 if alive and e.get("frozen", 0) > 0: intent_color = Color("8edcf2")
 elif alive and ui.game.shows_intents(): intent_color = ui.RED if ui.game.intent_for(e).type == "attack" else ui.GOLD
 var intent = ui.label(ui.game.visible_intent_text(e) if alive else "已击败", 19, intent_color)
 intent.name = "EnemyIntent" + str(index)
 intent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(intent)
 var emblem = ui.Sigil.new()
 emblem.tint = tint if alive else ui.MUTED
 emblem.boss = e.boss
 emblem.custom_minimum_size.y = 52
 emblem.size_flags_vertical = Control.SIZE_EXPAND_FILL
 emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(emblem)
 var name_label = ui.label(("◆ " if e.boss else "") + e.name + ("  ‹ 目标 ›" if selected else ""), 18, tint if selected else ui.TEXT)
 name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(name_label)
 var health = ui.health_bar(e.hp, e.max_hp, ui.RED)
 health.name = "EnemyHealth%d" % index
 content.add_child(health)
 var statuses: Array[String] = []
 if e.get("frozen", 0) > 0: statuses.append("冰冻 %d" % e.frozen)
 if e.block > 0: statuses.append("护甲 %d" % e.block)
 if e.poison > 0: statuses.append("毒 %d" % e.poison)
 if e.weak > 0: statuses.append("虚弱 -30%")
 if e.vulnerable > 0: statuses.append("易伤 +20%")
 if e.strength > 0: statuses.append("力量 +%d" % e.strength)
 var status = ui.label(" · ".join(statuses) if not statuses.is_empty() else "无状态", 14, ui.MUTED)
 status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(status)
 return tile

