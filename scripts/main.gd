extends Control
const Data = preload("res://scripts/data.gd")
const Run = preload("res://scripts/run_state.gd")
const Sigil = preload("res://scripts/sigil.gd")
const DeckManager = preload("res://scripts/deck_manager.gd")
const BG = Color("0c1220")
const PANEL = Color("141f30")
const PANEL_LIGHT = Color("1c2b40")
const TEXT = Color("eef1f6")
const MUTED = Color("94a6bd")
const GOLD = Color("e7b777")
const GREEN = Color("75cbb3")
const RED = Color("f08e85")
var game = Run.new()
var deck_manager = DeckManager.new()
var layout: VBoxContainer
var modal: Control
var on_menu = true
var selected_route = "venom"
var selected_difficulty = "easy"
var message = ""
var busy = false

func _ready() -> void:
 var font = SystemFont.new()
 font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
 var skin = Theme.new()
 skin.default_font = font
 skin.default_font_size = 17
 skin.set_color("font_color", "Label", TEXT)
 skin.set_color("font_color", "Button", TEXT)
 skin.set_color("font_hover_color", "Button", TEXT)
 skin.set_color("font_disabled_color", "Button", Color("66768b"))
 skin.set_stylebox("normal", "Button", box(PANEL_LIGHT, Color("34455e"), 10, 10))
 skin.set_stylebox("hover", "Button", box(Color("283b54"), GOLD, 10, 10))
 skin.set_stylebox("pressed", "Button", box(Color("35475e"), GOLD, 10, 10))
 skin.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), GOLD, 10, 2))
 skin.set_stylebox("disabled", "Button", box(Color("141d2b"), Color("253047"), 10, 10))
 theme = skin
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 render()

func box(fill: Color, border: Color = Color.TRANSPARENT, radius: int = 14, padding: int = 18) -> StyleBoxFlat:
 var style = StyleBoxFlat.new()
 style.bg_color = fill
 style.border_color = border
 style.set_border_width_all(1)
 style.set_corner_radius_all(radius)
 style.content_margin_left = padding
 style.content_margin_right = padding
 style.content_margin_top = padding
 style.content_margin_bottom = padding
 return style

func label(text_value: String, size_value: int = 17, color: Color = TEXT) -> Label:
 var node = Label.new()
 node.text = text_value
 node.add_theme_font_size_override("font_size", size_value)
 node.add_theme_color_override("font_color", color)
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return node

func paragraph(text_value: String, size_value: int = 17, color: Color = MUTED) -> Label:
 var node = label(text_value, size_value, color)
 node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return node

func column(gap: int = 12) -> VBoxContainer:
 var node = VBoxContainer.new()
 node.add_theme_constant_override("separation", gap)
 return node

func row(gap: int = 12) -> HBoxContainer:
 var node = HBoxContainer.new()
 node.add_theme_constant_override("separation", gap)
 return node

func panel(fill: Color = PANEL, border: Color = Color("29374d"), padding: int = 20) -> PanelContainer:
 var node = PanelContainer.new()
 node.add_theme_stylebox_override("panel", box(fill, border, 14, padding))
 return node

func button(text_value: String, action: Callable, accent: bool = false) -> Button:
 var node = Button.new()
 node.text = text_value
 node.custom_minimum_size.y = 42
 node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 node.focus_mode = Control.FOCUS_NONE
 if accent:
  node.add_theme_stylebox_override("normal", box(Color("72573a"), GOLD, 10, 10))
  node.add_theme_stylebox_override("hover", box(Color("926d44"), Color("ffdb9c"), 10, 10))
 node.pressed.connect(action)
 return node

func spacer(parent: Control) -> void:
 var space = Control.new()
 space.mouse_filter = Control.MOUSE_FILTER_IGNORE
 space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 parent.add_child(space)

func render() -> void:
 modal = null
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var background = ColorRect.new()
 background.color = BG
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(background)
 var margins = MarginContainer.new()
 margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 margins.add_theme_constant_override("margin_left", 28)
 margins.add_theme_constant_override("margin_right", 28)
 margins.add_theme_constant_override("margin_top", 20)
 margins.add_theme_constant_override("margin_bottom", 18)
 add_child(margins)
 layout = column(10)
 margins.add_child(layout)
 build_header()
 if on_menu:
  build_menu()
 else:
  build_map()
  match game.s.phase:
   "battle": build_battle()
   "reward": build_reward()
   "relic": build_relic_reward()
   "camp": build_camp()
   "victory", "defeat": build_ending()
 var footer = row()
 footer.add_child(label(message if not message.is_empty() else "原型 Demo  /  无需美术资产  /  进度自动保存到本机", 13, MUTED))
 spacer(footer)
 footer.add_child(label("EMBER  /  TWELVE", 13, GOLD))
 layout.add_child(footer)

func build_header() -> void:
 var header = row(18)
 var branding = column(0)
 branding.add_child(label("余烬十二关", 29))
 branding.add_child(label("一副卡牌，一条通往王座的路。", 13, MUTED))
 header.add_child(branding)
 spacer(header)
 if not on_menu:
  var s = game.s
  header.add_child(label("%s · %s  /  生命 %d/%d  /  金币 %d" % [Data.ROUTES[s.route].name, game.difficulty_info().name, s.hp, s.max_hp, s.gold], 17, GOLD))
  header.add_child(button("卡组 %d/30" % s.deck.size(), show_deck_manager))
 header.add_child(button("图鉴", func(): show_catalog()))
 header.add_child(button("玩法", show_help))
 if not on_menu:
  header.add_child(button("保存并返回", func():
   persist()
   on_menu = true
   render()))
 layout.add_child(header)

func build_menu() -> void:
 var lead = panel(PANEL, Color("3b4657"), 28)
 lead.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var lead_box = column(16)
 lead.add_child(lead_box)
 lead_box.add_child(label("DECKBUILDING  /  ROGUELITE PROTOTYPE", 14, GOLD))
 lead_box.add_child(label("从微火出发，挑战四座王座。", 38))
 lead_box.add_child(paragraph("选择一条战斗路线。以默认卡组开始，在 12 场战斗中选牌、锻造、补给，让你的打法逐渐成形。", 19))
 var features = row(30)
 for txt in ["12 场战斗", "4 位 Boss", "3 条成长路线", "3 档难度 · 回合制"]:
  features.add_child(label(txt, 17, GREEN))
 lead_box.add_child(features)
 var flex = Control.new()
 flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
 lead_box.add_child(flex)
 lead_box.add_child(label("01  /  选择你的起始路线", 18, GOLD))
 var routes = row(18)
 for id in ["venom", "bastion", "fury"]:
  var r: Dictionary = Data.ROUTES[id]
  var tint = Color(r.color)
  var tile = panel(Color("192638") if id == selected_route else PANEL, tint if id == selected_route else Color("334359"), 22)
  tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  var content = column(12)
  tile.add_child(content)
  content.add_child(label(r.name + ("  /  已选择" if id == selected_route else ""), 27, tint))
  content.add_child(label(r.tag, 16, tint))
  content.add_child(paragraph(r.desc, 17))
  content.add_child(label("初始生命 %d  ·  11 张卡牌" % r.hp, 15))
  var pick = button("选择「%s」" % r.name, func():
   selected_route = id
   render(), id == selected_route)
  content.add_child(pick)
  routes.add_child(tile)
 lead_box.add_child(routes)
 var difficulty_row = row(12)
 difficulty_row.add_child(label("02  /  选择难度", 18, GOLD))
 for id in ["easy", "normal", "hard"]:
  var choice = button(Data.DIFFICULTIES[id].name + (" · 已选" if id == selected_difficulty else ""), func():
   selected_difficulty = id
   render(), id == selected_difficulty)
  choice.name = "Difficulty_" + id
  choice.custom_minimum_size.x = 160
  choice.tooltip_text = Data.DIFFICULTIES[id].desc
  difficulty_row.add_child(choice)
 lead_box.add_child(difficulty_row)
 var difficulty_description = paragraph(Data.DIFFICULTIES[selected_difficulty].desc + " 本局开始后固定，继续存档沿用原难度。", 15, GREEN)
 difficulty_description.name = "DifficultyDescription"
 lead_box.add_child(difficulty_description)
 lead_box.add_child(paragraph("路线决定起始卡组和奖励池。每场胜利后可选一张新牌；每个 Boss 掉落升级卡与遗物。失败后从第一关重新出发。", 15))
 layout.add_child(lead)
 var actions = row(14)
 var start = button("开始新冒险  →", func():
  if FileAccess.file_exists("user://run_save.json"):
   confirm_new_run()
  else: start_new(), true)
 start.custom_minimum_size = Vector2(260, 54)
 actions.add_child(start)
 var continue_button = button("继续上次冒险", func():
  if game.load_run():
   on_menu = false
   message = "已读取本地存档。"
   render()
  else:
   message = "存档无法读取。可以开始新冒险。"
   render())
 continue_button.disabled = not FileAccess.file_exists("user://run_save.json")
 actions.add_child(continue_button)
 spacer(actions)
 actions.add_child(label("建议先试：铁壁  /  容错更高", 15, MUTED))
 layout.add_child(actions)

func start_new() -> void:
 game.new_run(selected_route, 0, selected_difficulty)
 on_menu = false
 message = "点击上方敌人选择目标，再点击手牌出牌。"
 commit()

func confirm_new_run() -> void:
 var content = open_modal("开始新的冒险？", Vector2(550, 270))
 content.add_child(paragraph("新的冒险会替换本地的上一局存档。", 18))
 content.add_child(button("确认开始「%s」· %s难度" % [Data.ROUTES[selected_route].name, Data.DIFFICULTIES[selected_difficulty].name], start_new, true))

func build_map() -> void:
 var stages = row(6)
 for i in range(1, 13):
  var is_boss = i % 3 == 0
  var text_value = "%02d%s" % [i, " 王" if is_boss else ""]
  if i < game.s.stage: text_value += " · 已过"
  var step = button(text_value, func(): show_stage(i), i == game.s.stage)
  step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  step.add_theme_font_size_override("font_size", 14)
  step.tooltip_text = "%s%s" % [Data.STAGE_NAMES[i - 1], " · Boss" if is_boss else ""]
  if is_boss: step.add_theme_color_override("font_color", GOLD)
  stages.add_child(step)
 layout.add_child(stages)

func build_battle() -> void:
 var s = game.s
 var arena = row(16)
 arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var battlefield = panel()
 battlefield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var field = column(12)
 battlefield.add_child(field)
 var title = row()
 title.add_child(label("%02d  /  %s" % [s.stage, Data.STAGE_NAMES[s.stage - 1]], 24))
 spacer(title)
 title.add_child(label("第 %d 回合" % s.turn, 16, MUTED))
 field.add_child(title)
 field.add_child(label("敌方区域  ·  点击锁定目标；预告显示下一次具体行动" if game.shows_intents() else "敌方区域  ·  点击锁定目标；当前难度隐藏下一步行动预告", 14, MUTED))
 var enemies = row(18)
 enemies.size_flags_vertical = Control.SIZE_EXPAND_FILL
 for i in range(s.enemies.size()):
  enemies.add_child(enemy_view(i))
 field.add_child(enemies)
 arena.add_child(battlefield)
 var aside = panel(PANEL, Color("29374d"), 15)
 aside.custom_minimum_size.x = 270
 var side = column(10)
 aside.add_child(side)
 side.add_child(label("冒险记录", 19, GOLD))
 var relic_names: Array[String] = []
 for id in s.relics: relic_names.append(Data.RELICS[id].name)
 var relic_label = paragraph("遗物  /  " + " · ".join(relic_names), 14, GREEN)
 relic_label.tooltip_text = relic_details()
 relic_label.mouse_filter = Control.MOUSE_FILTER_PASS
 side.add_child(relic_label)
 side.add_child(button("查看遗物效果", show_relics))
 var log_scroll = ScrollContainer.new()
 log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 log_scroll.custom_minimum_size.y = 130
 var logs = column(7)
 logs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 for entry in s.log.slice(maxi(0, s.log.size() - 10)):
  logs.add_child(paragraph(entry, 13, MUTED))
 log_scroll.add_child(logs)
 side.add_child(log_scroll)
 log_scroll.set_deferred("scroll_vertical", 100000)
 arena.add_child(aside)
 layout.add_child(arena)
 var player = panel(Color("182738"), Color("3e5770"), 14)
 var player_row = row(18)
 player.add_child(player_row)
 var player_info = column(3)
 player_info.custom_minimum_size.x = 235
 player_info.add_child(label("你  /  " + Data.ROUTES[s.route].name, 20))
 player_info.add_child(health_bar(s.hp, s.max_hp, GREEN, 225))
 player_row.add_child(player_info)
 player_row.add_child(label("护甲  %d" % s.block, 23, Color("85b5f5")))
 player_row.add_child(label("能量  %d / %d" % [s.energy, s.energy_max], 25, GOLD))
 var status = "力量%d · 反伤%d（临时%d）" % [s.strength, game.total_thorns(), s.temp_thorns]
 var route_status = "可治疗伤势%d" % s.recoverable_hp
 if s.route == "fury": route_status += " · 狂怒%d / 嗜战%d" % [s.fury, s.fury_engine]
 elif s.route == "bastion": route_status += " · 留甲上限%d" % s.retain_cap
 elif s.coating > 0: route_status += " · 淬毒%d" % s.coating
 status += "\n" + route_status
 if s.next_block > 0 or s.next_draw > 0 or s.next_energy > 0:
  status += "\n下回合：甲%d / 抽%d / 能量+%d" % [s.next_block, s.next_draw, s.next_energy]
 var status_label = label(status, 14, MUTED)
 status_label.tooltip_text = "伤势仅含上一轮敌方攻击造成、尚未恢复的生命损失；卡牌治疗共用此额度。\n临时反伤在下个玩家回合开始清零。固守留甲上限取最高值，随后再获得遗物护甲。"
 player_row.add_child(status_label)
 spacer(player_row)
 var potion = button("药水 ×%d\n恢复 20 生命" % s.potions, func():
  if game.use_potion(): commit())
 potion.add_theme_font_size_override("font_size", 14)
 potion.disabled = s.potions <= 0 or s.hp >= s.max_hp
 player_row.add_child(potion)
 player_row.add_child(button("结束回合  [空格]", end_player_turn, true))
 layout.add_child(player)
 var hand_header = row()
 hand_header.add_child(label("你的手牌  /  点击立即打出", 17))
 spacer(hand_header)
 hand_header.add_child(label("数字 1–9 出牌  ·  ← → 切换目标  ·  手牌上限 10", 14, MUTED))
 layout.add_child(hand_header)
 var hand_scroll = ScrollContainer.new()
 hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 hand_scroll.custom_minimum_size.y = 252
 var hand_row = row(12)
 for i in range(s.hand.size()):
  var card_button = card_view(s.hand[i], func(): play_card(i), str(i + 1) if i < 9 else "", not game.can_play(i))
  hand_row.add_child(card_button)
 if s.hand.is_empty(): hand_row.add_child(label("手牌已用尽，可以结束回合。", 20, MUTED))
 hand_scroll.add_child(hand_row)
 layout.add_child(hand_scroll)
 var piles = row(12)
 piles.add_child(button("抽牌堆 %d" % s.draw.size(), func(): show_pile("抽牌堆 · 按名称排列，不透露抽牌顺序", s.draw)))
 piles.add_child(button("弃牌堆 %d" % s.discard.size(), func(): show_pile("弃牌堆", s.discard)))
 piles.add_child(button("已激活 %d" % s.exhaust.size(), func(): show_pile("已激活能力 · 下场战斗恢复", s.exhaust)))
 spacer(piles)
 piles.add_child(label("当前目标：%s" % s.enemies[s.target].name, 17, GOLD))
 layout.add_child(piles)

func enemy_view(index: int) -> Button:
 var e: Dictionary = game.s.enemies[index]
 var alive: bool = e.hp > 0
 var selected: bool = index == game.s.target and alive
 var tint = GOLD if e.boss else GREEN
 var tile = Button.new()
 tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 tile.custom_minimum_size.y = 210
 tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 tile.focus_mode = Control.FOCUS_NONE
 tile.add_theme_stylebox_override("normal", box(Color("213345") if selected else Color("121c2a"), tint if selected else Color("2a3a50"), 12, 0))
 tile.add_theme_stylebox_override("hover", box(Color("24354a"), tint, 12, 0))
 tile.disabled = not alive
 tile.pressed.connect(func():
  game.select_target(index)
  message = "目标已锁定：" + e.name
  commit())
 var inset = MarginContainer.new()
 inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left", "right", "top", "bottom"]: inset.add_theme_constant_override("margin_" + edge, 12)
 inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
 tile.add_child(inset)
 var content = column(5)
 content.mouse_filter = Control.MOUSE_FILTER_IGNORE
 inset.add_child(content)
 var intent_color = MUTED
 if alive and game.shows_intents(): intent_color = RED if game.intent_for(e).type == "attack" else GOLD
 var intent = label(game.visible_intent_text(e) if alive else "已击败", 19, intent_color)
 intent.name = "EnemyIntent" + str(index)
 intent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(intent)
 var emblem = Sigil.new()
 emblem.tint = tint if alive else MUTED
 emblem.boss = e.boss
 emblem.custom_minimum_size.y = 72
 emblem.size_flags_vertical = Control.SIZE_EXPAND_FILL
 emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(emblem)
 var name_label = label(("◆ " if e.boss else "") + e.name + ("  ‹ 目标 ›" if selected else ""), 18, tint if selected else TEXT)
 name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(name_label)
 content.add_child(health_bar(e.hp, e.max_hp, RED))
 var statuses: Array[String] = []
 if e.block > 0: statuses.append("护甲 %d" % e.block)
 if e.poison > 0: statuses.append("毒 %d" % e.poison)
 if e.weak > 0: statuses.append("虚弱 %d" % e.weak)
 if e.vulnerable > 0: statuses.append("易伤 %d" % e.vulnerable)
 if e.strength > 0: statuses.append("力量 +%d" % e.strength)
 var status = label(" · ".join(statuses) if not statuses.is_empty() else "无状态", 14, MUTED)
 status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(status)
 return tile

func health_bar(hp: int, maximum: int, tint: Color, width: int = 0) -> Control:
 var holder = Control.new()
 holder.custom_minimum_size = Vector2(width, 23)
 holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var bar = ProgressBar.new()
 bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 bar.max_value = maximum
 bar.value = hp
 bar.show_percentage = false
 bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bar.add_theme_stylebox_override("background", box(Color("0a111e"), Color.TRANSPARENT, 6, 0))
 bar.add_theme_stylebox_override("fill", box(Color(tint, 0.55), Color.TRANSPARENT, 6, 0))
 holder.add_child(bar)
 var caption = label("%d / %d" % [hp, maximum], 14)
 caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 holder.add_child(caption)
 return holder

func card_view(id: String, action: Callable, hint: String = "", locked: bool = false) -> Button:
 var c = Data.card(id)
 var tint = Color(Data.ROUTES[c.route].color) if Data.ROUTES.has(c.route) else GOLD
 var node = Button.new()
 node.custom_minimum_size = Vector2(190, 232)
 node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 node.focus_mode = Control.FOCUS_NONE
 node.disabled = locked
 node.tooltip_text = "%s  /  %d 能量\n%s" % [c.name, c.cost, Data.describe(c)]
 node.add_theme_stylebox_override("normal", box(Color("1a2b3b"), Color(tint, 0.6), 12, 0))
 node.add_theme_stylebox_override("hover", box(Color("2a3d50"), tint, 12, 0))
 node.add_theme_stylebox_override("disabled", box(Color("141d2a"), Color("354050"), 12, 0))
 node.pressed.connect(action)
 var inset = MarginContainer.new()
 inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left", "right", "top", "bottom"]: inset.add_theme_constant_override("margin_" + edge, 14)
 inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
 node.add_child(inset)
 var body = column(7)
 body.mouse_filter = Control.MOUSE_FILTER_IGNORE
 body.modulate = Color(1, 1, 1, 0.45) if locked else Color.WHITE
 inset.add_child(body)
 var heading = row()
 heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
 heading.add_child(label(str(c.cost), 30, tint))
 spacer(heading)
 heading.add_child(label(c.kind + ("  " + hint if hint != "" else ""), 13, MUTED))
 body.add_child(heading)
 body.add_child(label(c.name, 22, tint))
 var sep = HSeparator.new()
 sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
 body.add_child(sep)
 var description = paragraph(Data.describe(c), 14, TEXT)
 description.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_child(description)
 body.add_child(label("单体 · 当前目标" if c.get("target", false) else "自身 / 全体效果", 12, MUTED))
 return node

func page_heading(kicker: String, heading: String, desc: String) -> void:
 layout.add_child(label(kicker, 15, GOLD))
 layout.add_child(label(heading, 32))
 layout.add_child(paragraph(desc, 18))

func build_reward() -> void:
 var s = game.s
 var boss: bool = int(s.stage) % 3 == 0
 page_heading("VICTORY  /  第 %d 关完成" % s.stage, "Boss 已倒下。收下战利品。" if boss else "战斗胜利，让卡组更进一步。", "获得 %d 金币%s。选择一张加入卡组，也可以跳过以保持精简。" % [s.last_gold, "，并恢复 15 生命" if boss else ""])
 var center = CenterContainer.new()
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var cards = row(24)
 for i in range(s.reward_cards.size()):
  var view = card_view(s.reward_cards[i], func(): take_reward_card(i), "选择")
  view.custom_minimum_size = Vector2(260, 310)
  cards.add_child(view)
 center.add_child(cards)
 layout.add_child(center)
 layout.add_child(button("跳过选牌  →", func():
  game.take_card(-1)
  message = "保持卡组精简。"
  commit()))

func build_relic_reward() -> void:
 page_heading("BOSS REWARD  /  遗物三选一", "带走一份持续整局的力量。", "遗物效果自动生效，不占手牌，也不消耗能量。")
 var center = CenterContainer.new()
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var choices = row(20)
 for i in range(game.s.relic_choices.size()):
  var relic: Dictionary = Data.RELICS[game.s.relic_choices[i]]
  var tile = panel(PANEL, Color("826749"), 25)
  tile.custom_minimum_size = Vector2(330, 260)
  var body = column(20)
  tile.add_child(body)
  body.add_child(label("✦  BOSS 遗物", 16, GOLD))
  body.add_child(label(relic.name, 27))
  var desc = paragraph(relic.desc, 18)
  desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
  body.add_child(desc)
  body.add_child(button("获得遗物", func():
   game.take_relic(i)
   message = "获得遗物：" + relic.name
   commit(), true))
  choices.add_child(tile)
 center.add_child(choices)
 layout.add_child(center)

func build_camp() -> void:
 var s = game.s
 page_heading("CAMP  /  战后补给", "在下一场战斗前，整顿行装。", "营火可以免费休息或升级一张牌，二选一；商店独立开放，按需花费金币。")
 var content = row(18)
 content.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var fire = panel(PANEL, Color("6c5542"), 22)
 fire.custom_minimum_size.x = 325
 var camp = column(15)
 fire.add_child(camp)
 camp.add_child(label("营火", 27, GOLD))
 camp.add_child(paragraph("每关一次免费机会\n休息 / 锻造 · 二选一", 18))
 camp.add_child(health_bar(s.hp, s.max_hp, GREEN))
 var rest_button = button("休息 · 恢复 %d 生命" % int(ceil(s.max_hp * 0.25)), func():
  game.rest()
  message = "营火休整完成。"
  commit(), true)
 rest_button.disabled = s.camp_used or s.hp >= s.max_hp
 camp.add_child(rest_button)
 var forge = button("锻造 · 升级一张卡", func(): show_deck("upgrade"))
 forge.disabled = s.camp_used or not has_upgradeable()
 camp.add_child(forge)
 camp.add_child(paragraph("本关营火已使用。" if s.camp_used else "升级永久生效。卡名带 + 的牌已经升级，不能再次升级。", 15))
 var relic_btn = button("查看当前遗物", show_relics)
 camp.add_child(relic_btn)
 camp.add_child(button("调整卡组 · %d/30" % s.deck.size(), show_deck_manager))
 content.add_child(fire)
 var shop = panel()
 shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var shop_box = column(14)
 shop.add_child(shop_box)
 var title = row()
 title.add_child(label("旅商补给", 27))
 spacer(title)
 title.add_child(label("金币  %d" % s.gold, 23, GOLD))
 shop_box.add_child(title)
 var stock = row(12)
 for i in range(s.shop_cards.size()):
  var item = column(8)
  item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  var sold: bool = i in s.shop_sold
  var card_button = card_view(s.shop_cards[i], func(): buy_shop_card(i), "45 金币", sold or s.gold < 45)
  card_button.custom_minimum_size.x = 190
  item.add_child(card_button)
  item.add_child(label("已购买" if sold else "点击购买 · 45 金币", 14, MUTED if sold else GOLD))
  stock.add_child(item)
 shop_box.add_child(stock)
 var services = row(10)
 var heal = button("治疗 +24\n30 金币", func():
  if game.buy_heal():
   message = "商店治疗完成。"
   commit())
 heal.disabled = s.gold < 30 or s.shop_healed or s.hp >= s.max_hp
 services.add_child(heal)
 var potion = button("药水 +1（%d/3）\n25 金币" % s.potions, func():
  if game.buy_potion():
   message = "补充了一瓶治疗药水。"
   commit())
 potion.disabled = s.gold < 25 or s.potions >= 3
 services.add_child(potion)
 var remove = button("永久删牌\n40 金币", func(): show_deck("remove"))
 remove.disabled = s.gold < 40 or s.shop_removed or s.deck.size() <= 5
 services.add_child(remove)
 shop_box.add_child(services)
 shop_box.add_child(paragraph("治疗和删牌每关各限一次；药水最多携带 3 瓶。药水战斗中使用，不消耗能量。", 14))
 content.add_child(shop)
 layout.add_child(content)
 layout.add_child(button("前往第 %d 关 · %s  →" % [s.stage + 1, Data.STAGE_NAMES[s.stage]], func():
  if not s.camp_used and (s.hp < s.max_hp or has_upgradeable()):
   var dialog = open_modal("营火机会还未使用", Vector2(600, 290))
   dialog.add_child(paragraph("你仍可以免费休息或升级一张牌。也可以直接出发。", 18))
   dialog.add_child(button("直接进入下一关", advance, true))
  else: advance(), true))

func has_upgradeable() -> bool:
 for id in game.s.deck:
  if not id.ends_with("+"): return true
 return false

func advance() -> void:
 game.next_stage()
 message = "敌人的意图已显示。规划好能量与防御再出牌。" if game.shows_intents() else "当前难度不显示行动预告，请根据战斗记录与敌人状态制定策略。"
 commit()

func buy_shop_card(index: int) -> void:
 if game.buy_card(index):
  finish_card_acquisition("购买成功")

func take_reward_card(index: int) -> void:
 game.take_card(index)
 finish_card_acquisition("获得新卡")

func finish_card_acquisition(prefix: String) -> void:
 var reserved: bool = game.s.last_acquired_zone == "reserve"
 message = prefix + ("：出战已满 30 张，新卡已放入备用卡库，可拖动换牌。" if reserved else "：已加入出战卡组。")
 commit()
 if reserved: deck_manager.show_screen(self, message)

func show_deck_manager() -> void:
 deck_manager.show_screen(self)

func show_catalog(route_filter: String = "neutral") -> void:
 var body = open_modal("卡牌图鉴  /  通用 16 种 · 每条路线 10 种", Vector2(1240, 820))
 var tabs = row(14)
 for id in ["neutral", "venom", "bastion", "fury"]:
  tabs.add_child(button("通用 · 16" if id == "neutral" else Data.ROUTES[id].name + " · 10", func(): show_catalog(id), id == route_filter))
 body.add_child(tabs)
 if route_filter != "neutral": body.add_child(paragraph(Data.ROUTES[route_filter].tag + "；卡名带 + 为升级版，点击卡牌可查看基础与升级效果。", 16))
 else: body.add_child(paragraph("所有路线共享的攻击、防御、过牌与补给。点击查看升级效果；图鉴不会直接授予卡牌。", 16))
 var scroll = ScrollContainer.new()
 scroll.custom_minimum_size.y = 590
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var grid = GridContainer.new()
 grid.columns = 4
 grid.add_theme_constant_override("h_separation", 14)
 grid.add_theme_constant_override("v_separation", 14)
 for id in Data.CARDS:
  if Data.CARDS[id].route != route_filter: continue
  var view = card_view(id, func(): show_catalog_card(id, route_filter))
  view.custom_minimum_size = Vector2(275, 270)
  grid.add_child(view)
 scroll.add_child(grid)
 body.add_child(scroll)

func show_catalog_card(id: String, route_filter: String) -> void:
 var body = open_modal("卡牌详情与升级", Vector2(850, 560))
 var pair = row(22)
 for version in [id, id + "+"]:
  var view = card_view(version, func(): pass)
  view.custom_minimum_size = Vector2(380, 330)
  pair.add_child(view)
 body.add_child(pair)
 body.add_child(button("返回图鉴", func(): show_catalog(route_filter)))

func build_ending() -> void:
 var win: bool = game.s.phase == "victory"
 var center = CenterContainer.new()
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var tile = panel(PANEL, GOLD if win else RED, 42)
 tile.custom_minimum_size.x = 850
 var body = column(23)
 tile.add_child(body)
 body.add_child(label("THE END  /  " + ("十二关通关" if win else "本次冒险结束") + "  /  " + game.difficulty_info().name + "难度", 17, GOLD))
 body.add_child(label("余烬未熄，王座已空。" if win else "微火暂熄，再起一局。", 38))
 body.add_child(paragraph("你击败了余烬之王，完成全部 12 关。最终奖励：余烬王冠与通关记录。" if win else "倒在第 %d 关 · %s。尝试调整卡组、参考战斗记录，或使用药水与营火恢复。" % [game.s.stage, Data.STAGE_NAMES[game.s.stage - 1]], 19))
 var stats = row(40)
 for item in ["胜利场次\n%d / 12" % game.s.wins, "出牌次数\n%d" % game.s.played, "累计伤害\n%d" % game.s.damage_total, "收集遗物\n%d" % game.s.relics.size()]:
  stats.add_child(label(item, 23, GREEN))
 body.add_child(stats)
 body.add_child(button("查看最终卡组", func(): show_deck("view")))
 body.add_child(button("返回路线选择", func():
  on_menu = true
  message = "可以选择另一条路线，开始新的冒险。"
  render(), true))
 center.add_child(tile)
 layout.add_child(center)

func play_card(index: int) -> void:
 if busy: return
 if game.play(index):
  message = "已出牌。注意剩余能量和敌方意图。" if game.shows_intents() else "已出牌。注意剩余能量、护甲和敌人状态。"
  commit()

func end_player_turn() -> void:
 if busy or game.s.phase != "battle": return
 busy = true
 game.end_turn()
 message = "敌方行动结束，轮到你了。" if game.s.phase == "battle" else "战斗已结束。"
 commit()
 busy = false

func persist() -> void:
 var result = game.save_run()
 if result != OK: message = "存档写入失败（错误 %d），请检查本机用户目录权限。" % result

func commit() -> void:
 persist()
 render()

func open_modal(title_value: String, dimensions: Vector2 = Vector2(1030, 700)) -> VBoxContainer:
 if is_instance_valid(modal):
  remove_child(modal)
  modal.queue_free()
 modal = Control.new()
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(modal)
 var dim = ColorRect.new()
 dim.color = Color(0.015, 0.025, 0.05, 0.9)
 dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(dim)
 var center = CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 center.mouse_filter = Control.MOUSE_FILTER_IGNORE
 modal.add_child(center)
 var frame = panel(PANEL, Color("53647b"), 24)
 frame.custom_minimum_size = dimensions
 center.add_child(frame)
 var body = column(16)
 frame.add_child(body)
 var heading = row()
 heading.add_child(label(title_value, 24, GOLD))
 spacer(heading)
 heading.add_child(button("关闭  [Esc]", close_modal))
 body.add_child(heading)
 return body

func close_modal() -> void:
 if is_instance_valid(modal):
  remove_child(modal)
  modal.queue_free()
 modal = null

func show_deck(mode: String) -> void:
 if mode == "view":
  show_deck_manager()
  return
 var heading = "永久卡组 · %d 张" % game.s.deck.size()
 if mode == "upgrade": heading = "选择一张卡升级 · 营火免费锻造"
 if mode == "remove": heading = "选择一张卡移除 · 花费 40 金币"
 var content = open_modal(heading)
 if mode == "upgrade": content.add_child(paragraph("点击卡牌查看升级前后变化，再确认锻造。", 16))
 elif mode == "remove": content.add_child(paragraph("点击卡牌后确认移除。卡组至少保留 5 张。", 16))
 var scroll = ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.custom_minimum_size.y = 490
 var grid = GridContainer.new()
 grid.columns = 4
 grid.add_theme_constant_override("h_separation", 16)
 grid.add_theme_constant_override("v_separation", 16)
 for i in range(game.s.deck.size()):
  var id: String = game.s.deck[i]
  var action = func(): show_card_info(id)
  if mode == "upgrade": action = func(): confirm_deck_change(i, "upgrade")
  if mode == "remove": action = func(): confirm_deck_change(i, "remove")
  var view = card_view(id, action, "", mode == "upgrade" and id.ends_with("+"))
  view.custom_minimum_size.x = 225
  grid.add_child(view)
 scroll.add_child(grid)
 content.add_child(scroll)

func confirm_deck_change(index: int, mode: String) -> void:
 var id: String = game.s.deck[index]
 var content = open_modal("确认升级" if mode == "upgrade" else "确认移除", Vector2(730, 490))
 var cards = row(20)
 cards.add_child(card_view(id, func(): pass))
 if mode == "upgrade":
  cards.add_child(label("→", 30, GOLD))
  cards.add_child(card_view(id + "+", func(): pass))
 else:
  cards.add_child(paragraph("永久移除这张卡，花费 40 金币。\n更精简的卡组能更稳定地抽到核心卡牌。", 18))
 content.add_child(cards)
 content.add_child(button("确认锻造" if mode == "upgrade" else "确认移除 · 40 金币", func():
  var success = game.upgrade_card(index) if mode == "upgrade" else game.remove_card(index)
  if success:
   message = "卡牌已升级。" if mode == "upgrade" else "卡牌已移除。"
   commit(), true))
 content.add_child(button("返回卡组", func(): show_deck(mode)))

func show_card_info(id: String) -> void:
 var c = Data.card(id)
 var content = open_modal(c.name, Vector2(570, 420))
 content.add_child(paragraph("费用：%d 能量\n类型：%s\n\n%s" % [c.cost, c.kind, Data.describe(c)], 20, TEXT))

func show_pile(title_value: String, pile: Array) -> void:
 var content = open_modal(title_value)
 var scroll = ScrollContainer.new()
 scroll.custom_minimum_size.y = 500
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var grid = GridContainer.new()
 grid.columns = 4
 grid.add_theme_constant_override("h_separation", 16)
 grid.add_theme_constant_override("v_separation", 16)
 var sorted = pile.duplicate()
 sorted.sort()
 for id in sorted: grid.add_child(card_view(id, func(): show_card_info(id)))
 if pile.is_empty(): grid.add_child(label("这里还没有卡牌。", 20, MUTED))
 scroll.add_child(grid)
 content.add_child(scroll)

func relic_details() -> String:
 var details: Array[String] = []
 for id in game.s.relics:
  details.append("%s：%s" % [Data.RELICS[id].name, Data.RELICS[id].desc])
 return "\n\n".join(details)

func show_relics() -> void:
 var content = open_modal("本局遗物", Vector2(750, 560))
 content.add_child(paragraph(relic_details(), 19, TEXT))

func show_stage(stage: int) -> void:
 var content = open_modal("第 %d 关 · %s" % [stage, Data.STAGE_NAMES[stage - 1]], Vector2(650, 400))
 var chapter_index = int((stage - 1) / 3)
 content.add_child(label("第 %d 章 / %s" % [chapter_index + 1, Data.CHAPTERS[chapter_index]], 22, GREEN))
 var encounters: Array[String] = []
 for e in game.encounter_for(stage): encounters.append("%s · %d 生命" % [e.name, e.hp])
 content.add_child(label("当前冒险：" + game.difficulty_info().name + "难度", 17, GOLD))
 content.add_child(paragraph("\n".join(encounters), 20, TEXT))
 content.add_child(paragraph("Boss 关：80 金币、恢复 15 生命、升级卡三选一和遗物三选一。第 12 关直接结算通关。" if stage % 3 == 0 else "普通关：30 金币、卡牌三选一，随后进入营火与商店。", 17))

func show_help() -> void:
 var content = open_modal("玩法与状态说明", Vector2(1000, 730))
 var text_value = "【冒险流程】\n12 关依次推进，每两场普通战斗后挑战 Boss（第 3 / 6 / 9 / 12 关）。生命跨关保留，护甲和战斗状态重置；每关结束可补给。\n\n【战斗】\n每回合通常有 3 能量、抽 5 张牌。先点敌人选目标，再点击卡牌打出。数字 1–9 出牌，左右方向键切换目标，空格结束回合。未用的能量不保留，剩余手牌进入弃牌堆；抽牌堆耗尽时洗入弃牌堆。\n\n【护甲与伤害】\n护甲抵挡普通伤害，在你下回合开始时清空；「固守」本场每回合保留剩余护甲至上限，多张取最高上限。力量增加每段攻击伤害。毒素无视护甲，在该敌人行动前造成等于层数的伤害，再减少 1 层。\n\n【其他状态】\n虚弱：攻击伤害降低 25%。易伤：受到的普通伤害增加 50%。持续回合数在敌方行动后减少。反伤：每次受到攻击时反击，即使伤害被护甲完全抵挡。\n\n【成长与存档】\n只有能力牌生效后移入「已激活」，下场恢复；攻击和技能进入弃牌堆，可再次抽到。营火免费休息与升级二选一；商店独立开放。每次操作自动保存，退出窗口后可继续。开始新冒险会替换旧存档。"
 text_value += "\n\n【治疗与延迟效果】\n卡牌治疗仅恢复上一轮敌方攻击造成的未恢复伤势，多张共享额度；药水也会扣减该额度，下一轮敌方行动开始时过期。燃血自伤和旧伤不能靠卡牌恢复。棘甲反伤仅持续至下个玩家回合开始，其他反伤能力持续整场。振作、毒素回收提供下回合额外能量；催化翻倍最多新增12层，升级18层。"
 text_value += "\n\n【路线核心】\n蚀毒：叠毒侵蚀，或用毒爆消耗全部毒层，按倍率造成无视护甲的伤害（不受力量、易伤影响）。淬毒使每张攻击牌结算后向命中且存活的敌人施加等量毒素，多段只触发一次。毒素回收需要目标至少 4 层毒。\n铁壁：护甲转单体或全体伤害；也能叠反伤，使用反击风暴主动输出，保留反伤继续反击。\n狂刃：力量强化每段攻击；嗜战使每张攻击牌结算后获得等量狂怒，怒吼与血性冲锋也可积攒。怒斩清空狂怒获得加伤，再触发嗜战。狂怒跨回合保留，这些路线状态跨战斗清空。\n\n【卡组管理】\n出战卡组 5–30 张，备用卡库不参与抽牌。战斗外点击右上角卡组，可把卡牌拖到另一侧，或点击后选择移入。出战满 30 张时，新获得的卡自动进入备用卡库并打开管理界面；先拖出旧卡，再拖入新卡。换牌免费，卡牌不会被删除。图鉴可查看全部 46 种牌和升级版。"
 var scroll = ScrollContainer.new()
 scroll.custom_minimum_size.y = 590
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 text_value = "【难度】\n简单：显示下次攻击的单段伤害、连击次数和总伤害，也预告防御与蓄力。预告计入敌人的力量和虚弱，实际生命损失还会受到你的护甲影响。\n中等：隐藏所有行动预告，保留基础数值。\n困难：隐藏预告；敌人生命 +35%，攻击、防御、蓄力 +25%，向上取整。行动模式和连击次数不变。\n难度在新冒险开始前选择，本局固定；旧版存档按简单难度继续，已发生的行动仍显示在战斗记录中。\n\n" + text_value
 var text_label = paragraph(text_value, 18, TEXT)
 scroll.add_child(text_label)
 content.add_child(scroll)

func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 if is_instance_valid(modal):
  if event.keycode == KEY_ESCAPE:
   close_modal()
   get_viewport().set_input_as_handled()
  return
 if on_menu or game.s.is_empty() or game.s.phase != "battle": return
 if event.keycode == KEY_SPACE:
  end_player_turn()
  get_viewport().set_input_as_handled()
 elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
  play_card(event.keycode - KEY_1)
  get_viewport().set_input_as_handled()
 elif event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT:
  var targets = game.living()
  var index = targets.find(game.s.target)
  index = posmod(index + (1 if event.keycode == KEY_RIGHT else -1), targets.size())
  game.select_target(targets[index])
  commit()
  get_viewport().set_input_as_handled()
