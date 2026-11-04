extends Node
## The arena and lower dock share state, while their layout remains independent.

func build_battle(ui: Control) -> void:
 var s = ui.game.s
 var arena = ui.row(16)
 arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var battlefield = ui.panel()
 battlefield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var field = ui.column(12)
 battlefield.add_child(field)
 var title = ui.row()
 title.add_child(ui.label("%02d  /  %s" % [s.stage, ui.Data.STAGE_NAMES[s.stage - 1]], 24))
 ui.spacer(title)
 title.add_child(ui.label("第 %d 回合" % s.turn, 16, ui.MUTED))
 field.add_child(title)
 field.add_child(ui.label("敌方区域  ·  点击锁定目标；预告显示下一次具体行动" if ui.game.shows_intents() else "敌方区域  ·  点击锁定目标；当前难度隐藏下一步行动预告", 14, ui.MUTED))
 var enemies = ui.row(18)
 enemies.size_flags_vertical = Control.SIZE_EXPAND_FILL
 for i in range(s.enemies.size()): enemies.add_child(ui.enemy_view(i))
 field.add_child(enemies)
 arena.add_child(battlefield)
 var aside = ui.panel(ui.PANEL, Color("29374d"), 15)
 aside.custom_minimum_size.x = 260
 var side = ui.column(10)
 aside.add_child(side)
 side.add_child(ui.label("冒险记录", 19, ui.GOLD))
 var relic_names: Array[String] = []
 for id in s.relics: relic_names.append(ui.Data.RELICS[id].name)
 var relic_label = ui.paragraph("遗物  /  " + " · ".join(relic_names), 14, ui.GREEN)
 relic_label.tooltip_text = ui.relic_details()
 relic_label.mouse_filter = Control.MOUSE_FILTER_PASS
 side.add_child(relic_label)
 side.add_child(ui.button("查看遗物效果", ui.show_relics))
 var log_scroll = ScrollContainer.new()
 log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 log_scroll.custom_minimum_size.y = 75
 var logs = ui.column(7)
 logs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 for entry in s.log.slice(maxi(0, s.log.size() - 10)):
  logs.add_child(ui.paragraph(entry, 13, ui.MUTED))
 log_scroll.add_child(logs)
 side.add_child(log_scroll)
 log_scroll.set_deferred("scroll_vertical", 100000)
 arena.add_child(aside)
 ui.layout.add_child(arena)

 var dock = ui.row(16)
 dock.name = "BattleDock"
 dock.custom_minimum_size.y = 374
 dock.add_child(build_hero(ui))
 var hand_area = ui.column(8)
 hand_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var heading = ui.row()
 heading.add_child(ui.label("手牌  %d / 10" % s.hand.size(), 19))
 ui.spacer(heading)
 heading.add_child(ui.label("1–9 / 0 出牌 · ← → 选目标", 14, ui.MUTED))
 hand_area.add_child(heading)
 hand_area.add_child(ui.label("当前目标：%s  ·  回合结束保留手牌" % s.enemies[s.target].name, 14, ui.GOLD))
 var hand_scroll = ScrollContainer.new()
 hand_scroll.name = "HandScroll"
 hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 hand_scroll.custom_minimum_size.y = 286
 hand_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var hand_row = ui.row(12)
 hand_row.name = "HandCards"
 for i in range(s.hand.size()):
  hand_row.add_child(ui.card_view(s.hand[i], func(): ui.play_card(i), str((i + 1) % 10), not ui.game.can_play(i)))
 if s.hand.is_empty(): hand_row.add_child(ui.label("手牌已用尽，可以结束回合。", 20, ui.MUTED))
 hand_scroll.add_child(hand_row)
 hand_area.add_child(hand_scroll)
 dock.add_child(hand_area)

 var actions = ui.column(10)
 actions.name = "BattleActions"
 actions.custom_minimum_size.x = 154
 for entry in [["抽牌堆", "DrawPile", s.draw], ["弃牌堆", "DiscardPile", s.discard], ["本场移除", "ExhaustPile", s.exhaust]]:
  var pile_button = ui.button("%s  %d" % [entry[0], entry[2].size()], func(): ui.show_pile("抽牌堆 · 按名称排列" if entry[1] == "DrawPile" else entry[0], entry[2]))
  pile_button.name = entry[1]
  pile_button.custom_minimum_size.y = 52
  pile_button.add_theme_font_size_override("font_size", 16)
  actions.add_child(pile_button)
 var space = Control.new()
 space.size_flags_vertical = Control.SIZE_EXPAND_FILL
 actions.add_child(space)
 var end_turn = ui.button("结束回合\n[空格]", ui.end_player_turn, true)
 end_turn.name = "EndTurn"
 end_turn.custom_minimum_size.y = 84
 actions.add_child(end_turn)
 dock.add_child(actions)
 ui.layout.add_child(dock)

func build_hero(ui: Control) -> Control:
 var s = ui.game.s
 var player = ui.panel(Color("182738"), Color("3e5770"), 14)
 player.name = "HeroPanel"
 player.custom_minimum_size.x = 264
 var info = ui.column(8)
 player.add_child(info)
 var heading = ui.row(12)
 var portrait = ui.make_portrait()
 portrait.name = "HeroPortrait"
 portrait.custom_minimum_size = Vector2(70, 78)
 heading.add_child(portrait)
 var identity = ui.column(5)
 identity.add_child(ui.label("余烬行者", 20))
 identity.add_child(ui.label(ui.Data.ROUTES[s.route].name + " · " + ui.game.difficulty_info().name, 15, ui.GREEN))
 heading.add_child(identity)
 info.add_child(heading)
 var health = ui.health_bar(s.hp, s.max_hp, ui.GREEN, 230)
 health.name = "HeroHealth"
 info.add_child(health)
 var energy_text = "能量 %d / %d" % [s.energy, s.energy_max]
 if s.block > 0: energy_text += "    护甲 %d" % s.block
 info.add_child(ui.label(energy_text, 20, ui.GOLD))
 var status = "\n".join(active_status_lines(s))
 var status_scroll = ScrollContainer.new()
 status_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 status_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 status_scroll.custom_minimum_size.y = 76
 var status_label = ui.paragraph(status, 14, ui.MUTED)
 status_label.name = "HeroStatuses"
 status_label.visible = not status.is_empty()
 status_label.tooltip_text = "临时反伤在下回合开始清零。"
 if has_leech(s): status_label.tooltip_text = "汲取仅治疗上一轮敌方攻击造成的未恢复伤势；卸力、急救、全才可直接治疗。" + status_label.tooltip_text
 status_label.mouse_filter = Control.MOUSE_FILTER_PASS
 status_scroll.add_child(status_label)
 info.add_child(status_scroll)
 var potion = ui.button("药水 ×%d  ·  恢复 20 生命" % s.potions, ui.use_battle_potion)
 potion.add_theme_font_size_override("font_size", 14)
 potion.disabled = s.potions <= 0 or s.hp >= s.max_hp
 info.add_child(potion)
 return player

func has_leech(s: Dictionary) -> bool:
 return "leech" in s.get("deck", []) or "leech+" in s.get("deck", [])

func active_status_lines(s: Dictionary) -> Array[String]:
 var lines: Array[String] = []
 if s.strength != 0: lines.append("力量 %d" % s.strength)
 if s.thorns > 0: lines.append("反伤 %d" % s.thorns)
 if s.temp_thorns > 0: lines.append("临时反伤 %d" % s.temp_thorns)
 if s.barrier > 0: lines.append("金钟罩 %d" % s.barrier)
 if s.recoverable_hp > 0 and has_leech(s): lines.append("汲取可恢复：%d 生命" % s.recoverable_hp)
 if s.lifesteal > 0: lines.append("吸血 %d%%" % s.lifesteal)
 if s.next_lifesteal > 0: lines.append("下回合吸血 %d%%" % s.next_lifesteal)
 if s.low_hp_crit > 0: lines.append("暴力执法 %d%%%s" % [s.low_hp_crit, "（生效中）" if s.hp * 4 < s.max_hp else "（需生命低于25%）"])
 if s.temporary_strength > 0: lines.append("本回合临时力量 +%d" % s.temporary_strength)
 if s.next_strength > 0: lines.append("下回合力量 +%d（仅一回合）" % s.next_strength)
 if s.retain_cap > 0: lines.append("留甲上限 %d" % s.retain_cap)
 if s.coating > 0: lines.append("淬毒 %d" % s.coating)
 if s.next_block > 0: lines.append("下回合护甲 +%d" % s.next_block)
 if s.next_draw > 0: lines.append("下回合抽牌 +%d" % s.next_draw)
 if s.next_energy > 0: lines.append("下回合能量 +%d" % s.next_energy)
 return lines
