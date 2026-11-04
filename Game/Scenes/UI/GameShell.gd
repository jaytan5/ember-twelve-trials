extends Control
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
const Run = preload("res://Game/Scripts/Combat/CombatState.gd")
const Sigil = preload("res://Game/Scenes/Enemy/Sigil.gd")
const DeckManager = preload("res://Game/Scripts/CardSystem/DeckManager.gd")
const BG = Color("0c1220")
const PANEL = Color("141f30")
const PANEL_LIGHT = Color("1c2b40")
const TEXT = Color("eef1f6")
const MUTED = Color("94a6bd")
const GOLD = Color("e7b777")
const GREEN = Color("75cbb3")
const RED = Color("f08e85")
const READING_FONT = preload("res://Game/Assets/Fonts/MiSans-Regular.ttf")
const DISPLAY_FONT = preload("res://Game/Assets/Fonts/方圆体-标题.tres")
var mainmenu_view_component = preload("res://Game/Scenes/MainMenu/MainMenuView.tscn").instantiate()
var battle_view_component = preload("res://Game/Scenes/Battle/BattleView.tscn").instantiate()
var map_view_component = preload("res://Game/Scenes/Map/MapView.tscn").instantiate()
var card_view_component = preload("res://Game/Scenes/Card/CardView.tscn").instantiate()
var enemy_view_component = preload("res://Game/Scenes/Enemy/EnemyView.tscn").instantiate()
var ui_view_component = preload("res://Game/Scenes/UI/UIView.tscn").instantiate()
var home_view_component = preload("res://Game/Scenes/MainMenu/HomeView.tscn").instantiate()
var settings_view_component = preload("res://Game/Scenes/UI/SettingsView.tscn").instantiate()
var settings = preload("res://Game/Scripts/SaveSystem/AppSettings.gd").new()
var game = Run.new()
var deck_manager = DeckManager.new()
var layout: VBoxContainer
var modal: Control
var screen = "title"
var resuming = false
var on_menu: bool:
 get: return screen in ["title", "home", "routes"]
 set(value): screen = "routes" if value else "run"
var selected_route = "venom"
var selected_difficulty = "easy"
var message = ""
var busy = false
var battle_animator = preload("res://Game/Scenes/Battle/BattleAnimator.gd").new()
var game_cursor = preload("res://Game/Scenes/UI/GameCursor.gd").new()
signal combat_animation_finished

func _ready() -> void:
 add_child(battle_animator)
 add_child(game_cursor)
 add_child(settings)
 add_child(home_view_component)
 add_child(settings_view_component)
 add_child(mainmenu_view_component)
 add_child(battle_view_component)
 add_child(map_view_component)
 add_child(card_view_component)
 add_child(enemy_view_component)
 add_child(ui_view_component)
 var skin = Theme.new()
 skin.default_font = READING_FONT
 skin.set_font("font", "Button", DISPLAY_FONT)
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
 if size_value >= 22: node.add_theme_font_override("font", DISPLAY_FONT)
 node.add_theme_color_override("font_color", color)
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return node

func paragraph(text_value: String, size_value: int = 17, color: Color = MUTED) -> Label:
 var node = label(text_value, size_value, color)
 node.add_theme_font_override("font", READING_FONT)
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
 if action != settings.play_click: node.pressed.connect(settings.play_click)
 node.pressed.connect(action)
 return node

func spacer(parent: Control) -> void:
 var space = Control.new()
 space.mouse_filter = Control.MOUSE_FILTER_IGNORE
 space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 parent.add_child(space)

func render() -> void:
 settings.set_menu_music_enabled(screen in ["title", "home", "routes"])
 modal = null
 for child in get_children():
  if child == home_view_component.background: continue
  if not child is Control: continue
  remove_child(child)
  child.queue_free()
 var background = ColorRect.new()
 background.color = BG
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(background)
 move_child(background, 0)
 home_view_component.update_background(self, screen in ["title", "home"])
 if screen == "title":
  layout = null
  home_view_component.build_title(self)
  return
 if screen == "home":
  layout = null
  home_view_component.build_home(self)
  return
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
 if screen == "routes":
  build_menu()
 elif screen == "map":
  build_map()
 else:
  match game.s.phase:
   "battle": build_battle()
   "reward": build_reward()
   "relic": build_relic_reward()
   "camp": build_camp()
   "victory", "defeat": build_ending()
 if screen == "routes": return
 var footer = row()
 footer.add_child(label(message if not message.is_empty() else "四大场景 · 十二道试炼  /  冒险进度自动保存到本机", 13, MUTED))
 spacer(footer)
 layout.add_child(footer)

func build_header() -> void:
 var header = row(18)
 var branding = column(0)
 branding.add_child(label("小泥团，出击！", 29))
 header.add_child(branding)
 spacer(header)
 if screen in ["map", "run"]:
  header.add_child(label("%s · %s  /  金币 %d" % [Data.ROUTES[game.s.route].name, game.difficulty_info().name, game.s.gold], 17, GOLD))
 var menu_button = button("☰  设置", show_game_menu if screen in ["map", "run"] else show_settings)
 menu_button.name = "SettingsButton"
 menu_button.custom_minimum_size.x = 120
 header.add_child(menu_button)
 layout.add_child(header)

func build_menu() -> void:
 mainmenu_view_component.build_menu(self)

func start_new() -> void:
 game.new_run(selected_route, 0, selected_difficulty)
 resuming = false
 screen = "map"
 message = "选择地图上亮起的关卡，开始你的冒险。"
 commit()

func confirm_new_run() -> void:
 var content = open_modal("开始新的冒险？", Vector2(550, 270))
 content.add_child(paragraph("新的冒险会替换本地的上一局存档。", 18))
 content.add_child(button("确认开始「%s」· %s难度" % [Data.ROUTES[selected_route].name, Data.DIFFICULTIES[selected_difficulty].name], start_new, true))

func build_map() -> void:
 map_view_component.build_map(self)

func build_battle() -> void:
 battle_view_component.build_battle(self)

func enemy_view(index: int) -> Button:
 return enemy_view_component.enemy_view(self, index)

func health_bar(hp: int, maximum: int, tint: Color, width: int = 0) -> Control:
 return ui_view_component.health_bar(self, hp, maximum, tint, width)

func card_view(id: String, action: Callable, hint: String = "", locked: bool = false) -> Button:
 return card_view_component.card_view(self, id, action, hint, locked)

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
 if game.s.phase != "camp": return
 game.next_stage()
 screen = "map"
 message = "新的关卡已解锁，点击地图上的关卡进入。"
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
 var body = open_modal("卡牌图鉴  /  通用 %d 种 · 每条路线 10 种" % Data.card_count("neutral"), Vector2(1240, 820))
 var tabs = row(14)
 for id in ["neutral", "venom", "bastion", "fury"]:
  tabs.add_child(button("通用 · %d" % Data.card_count("neutral") if id == "neutral" else Data.ROUTES[id].name + " · 10", func(): show_catalog(id), id == route_filter))
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
 if game.can_retry_battle():
  var retry = button("重新开始本小关", retry_current_battle, true)
  retry.name = "RetryBattle"
  body.add_child(retry)
  body.add_child(paragraph("恢复至本关开战时的生命、药水、手牌与敌人状态。" if game.s.has("battle_checkpoint") else "此旧存档没有开战记录：保留现有卡组与资源，满血重新开始本关。", 15))
 elif not win:
  body.add_child(paragraph("传奇难度无法重试小关，只能从第一关重新冒险。", 15, RED))
 body.add_child(button("返回主界面", return_home, true))
 center.add_child(tile)
 layout.add_child(center)

func retry_current_battle() -> void:
 if busy or not game.retry_battle(): return
 screen = "run"
 message = "已重新开始第 %d 关。" % game.s.stage
 commit()

func play_card(index: int) -> void:
 if busy or screen != "run" or is_instance_valid(modal) or not game.can_play(index): return
 await animate_combat_action("card", index)

func end_player_turn() -> void:
 if busy or screen != "run" or is_instance_valid(modal) or game.s.phase != "battle": return
 await animate_combat_action("end_turn")

func use_battle_potion() -> void:
 if busy or game.s.phase != "battle" or game.s.potions <= 0 or game.s.hp >= game.s.max_hp: return
 await animate_combat_action("potion")

func animate_combat_action(action: String, index: int = -1) -> void:
 # Resolve on an isolated copy; live state, RNG, saving and reward screens wait.
 var prepared = Run.new()
 prepared.s = game.s.duplicate(true)
 prepared.rng.state = game.rng.state
 prepared.capture_combat_events = true
 match action:
  "card":
   if not prepared.play(index): return
  "end_turn": prepared.end_turn()
  "potion":
   if not prepared.use_potion(): return
 busy = true
 var input_shield = Control.new()
 input_shield.name = "CombatInputShield"
 input_shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 input_shield.mouse_filter = Control.MOUSE_FILTER_STOP
 input_shield.mouse_default_cursor_shape = Control.CURSOR_WAIT
 add_child(input_shield)
 await battle_animator.play_events(self, prepared.combat_events, index)
 game.s = prepared.s
 game.rng.state = prepared.rng.state
 busy = false
 message = "敌方行动结束，轮到你了。" if action == "end_turn" else "已出牌。" if action == "card" else "已使用治疗药水。"
 if game.s.phase != "battle": message = "战斗已结束。"
 commit()
 combat_animation_finished.emit()

func persist() -> void:
 if game.s.is_empty(): return
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
 elif mode == "remove": content.add_child(paragraph("点击卡牌后确认移除。卡组至少保留 15 张。", 16))
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
 content.add_child(paragraph("费用：%s 能量\n类型：%s\n\n%s" % [Data.cost_text(c), c.kind, Data.describe(c)], 20, TEXT))

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
 var text_value = "【新增效果】\n厚积薄发：消耗全部当前能量，下回合额外获得等量能量。冰冻：跳过下一次敌方行动（毒照常结算，行动顺序不前进）。金钟罩：抵挡一次正伤害，连续攻击只挡一段，可叠加次数，跨回合保留。碎甲击：移除护甲并造成等量伤害，不受力量或易伤加成。\n\n【冒险流程】\n从主界面选择新冒险或继续冒险，确认路线后进入关卡地图。继续冒险锁定存档路线和难度。四大场景共 12 关依次推进，每两场普通战斗后挑战 Boss（第 3 / 6 / 9 / 12 关）。生命跨关保留，护甲和战斗状态重置；每关结束可补给。\n\n【战斗】\n每回合通常有 3 能量。首回合抽5张，之后每回合抽2张，手牌上限10张。先点敌人选目标，再点击卡牌打出。数字 1–9、0 出牌，左右方向键切换目标，空格结束回合。未用的能量不保留，剩余手牌保留；满手牌时停止抽牌，未抽的牌留在牌库；抽牌堆耗尽时洗入弃牌堆。\n\n【护甲与伤害】\n护甲抵挡普通伤害，在你下回合开始时清空；「固守」本场每回合保留剩余护甲至上限，多张取最高上限。力量增加每段攻击伤害。毒素无视护甲，在该敌人行动前造成等于层数的伤害，再减少 1 层。\n\n【其他状态】\n虚弱：攻击伤害降低 30%。易伤：受到的普通伤害增加 20%。两者本场持续、不衰减，重复施加不叠加。反伤：每次受到攻击时反击，即使伤害被护甲完全抵挡。\n\n【成长与存档】\n能力牌与急救使用后本场移出，下场恢复；其他已打出的牌进入弃牌堆，可再次抽到。营火免费休息与升级二选一；商店独立开放。每次操作自动保存，退出窗口后可继续。开始新冒险会替换旧存档。"
 text_value += "\n\n【治疗与延迟效果】\n卸力、急救、全才可直接恢复生命；汲取仅恢复上一轮敌方攻击造成的未恢复伤势。棘甲反伤仅持续至下个玩家回合开始，其他反伤能力持续整场。厚积薄发、毒素回收提供下回合额外能量；催化翻倍最多新增12层，升级18层。"
 text_value += "\n\n【路线核心】\n蚀毒：叠毒侵蚀，或用毒爆消耗全部毒层，按倍率造成无视护甲的伤害（不受力量、易伤影响）。淬毒使每张攻击牌结算后向命中且存活的敌人施加等量毒素，多段只触发一次。毒素回收需要目标至少 4 层毒。\n铁壁：护甲转单体或全体伤害；也能叠反伤，使用反击风暴主动输出，保留反伤继续反击。\n狂刃：力量强化每段攻击。嗜血使下一回合所有对敌伤害附带75%吸血，按实际扣除的敌方生命逐段向下取整治疗；持续至再下一回合开始，包含毒素和反伤。怒吼下回合增加临时力量，仅持续该回合。暴力执法生效后，生命严格低于25%时，每段对敌伤害有50%（升级60%）几率翻倍；治疗使生命回到门槛以上后立即停止暴击。顺劈斩每段重新随机选择存活敌人。这些状态下场清空。\n\n【卡组管理】\n出战卡组 15–30 张，备用卡库不参与抽牌。战斗外打开右上角设置菜单中的卡组，可把卡牌拖到另一侧，或点击后选择移入。出战满 30 张时，新获得的卡自动进入备用卡库并打开管理界面；先拖出旧卡，再拖入新卡。换牌免费，卡牌不会被删除。图鉴可查看全部 47 种牌和升级版。"
 var scroll = ScrollContainer.new()
 scroll.custom_minimum_size.y = 590
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 text_value = "【难度】\n轻松：显示下次攻击的单段伤害、连击次数和总伤害，也预告防御与蓄力。预告计入敌人的力量和虚弱，实际生命损失还会受到你的护甲影响。\n标准：隐藏所有行动预告，保留基础数值。\n勇者：隐藏预告；敌人生命 +35%，攻击、防御、蓄力 +25%，向上取整。行动模式和连击次数不变。\n轻松、标准、勇者战败后均可重新开始本小关。传奇沿用勇者数值，但战败不能重试，只能从头开始。\n难度在新冒险开始前选择，本局固定；旧版存档按轻松难度继续，已发生的行动仍显示在战斗记录中。\n\n" + text_value
 var text_label = paragraph(text_value, 18, TEXT)
 scroll.add_child(text_label)
 content.add_child(scroll)

func _input(event: InputEvent) -> void:
 if screen != "title": return
 var start_pressed = (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventJoypadButton and event.pressed)
 if not start_pressed: return
 # Consume the opening action so it cannot also activate a newly revealed menu.
 get_viewport().set_input_as_handled()
 screen = "home"
 render()

func _unhandled_key_input(event: InputEvent) -> void:
 if busy:
  get_viewport().set_input_as_handled()
  return
 if not event is InputEventKey or not event.pressed or event.echo: return
 if is_instance_valid(modal):
  if event.keycode == KEY_ESCAPE:
   close_modal()
   get_viewport().set_input_as_handled()
  return
 if event.keycode == KEY_ESCAPE:
  if screen in ["map", "run"]: show_game_menu()
  elif screen == "routes": return_home()
  else: show_settings()
  get_viewport().set_input_as_handled()
  return
 if screen != "run" or game.s.is_empty() or game.s.phase != "battle": return
 if event.keycode == KEY_SPACE:
  end_player_turn()
  get_viewport().set_input_as_handled()
 elif event.keycode >= KEY_1 and event.keycode <= KEY_9 or event.keycode == KEY_0:
  play_card(9 if event.keycode == KEY_0 else event.keycode - KEY_1)
  get_viewport().set_input_as_handled()
 elif event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT:
  var targets = game.living()
  if targets.is_empty(): return
  var index = targets.find(game.s.target)
  index = posmod(index + (1 if event.keycode == KEY_RIGHT else -1), targets.size())
  game.select_target(targets[index])
  commit()
  get_viewport().set_input_as_handled()

func open_new_routes() -> void:
 resuming = false
 screen = "routes"
 message = "选择起始路线和本局难度。"
 render()

func open_continue_routes() -> void:
 if not game.load_run():
  message = "存档无法读取。可以开始新冒险。"
  render()
  var body = open_modal("无法继续游戏", Vector2(550, 270))
  body.add_child(paragraph(message, 18))
  body.add_child(button("开始新的游戏", open_new_routes, true))
  return
 resuming = true
 selected_route = game.s.route
 selected_difficulty = game.s.difficulty
 screen = "routes"
 message = "已读取存档；确认原路线后前往关卡地图。"
 render()

func confirm_route() -> void:
 if resuming:
  screen = "map"
  resuming = false
  message = "进度与卡组已保留，点击当前关卡继续冒险。"
  render()
 elif FileAccess.file_exists("user://run_save.json"):
  confirm_new_run()
 else: start_new()

func open_map() -> void:
 if game.s.is_empty(): return
 screen = "map"
 message = "点击当前关卡继续；后续关卡将在战后补给结束时解锁。"
 render()

func enter_map_stage(stage: int) -> void:
 if screen != "map" or stage != int(game.s.stage): return
 screen = "run"
 message = "点击敌人选择目标，再点击手牌出牌。" if game.s.phase == "battle" else "继续完成当前关卡的结算与补给。"
 render()

func return_home() -> void:
 if screen in ["map", "run"]: persist()
 screen = "home"
 resuming = false
 message = ""
 render()

func show_settings() -> void:
 settings_view_component.show_settings(self)

func show_game_menu() -> void:
 settings_view_component.show_game_menu(self)

func manual_save() -> void:
 var result = game.save_run()
 close_modal()
 message = "冒险进度已保存。" if result == OK else "存档写入失败（错误 %d）。" % result
 render()

func make_portrait(full_body: bool = false) -> TextureRect:
 var atlas = AtlasTexture.new()
 atlas.atlas = preload("res://Game/Assets/Characters/主角四视图.png")
 atlas.region = Rect2(620, 40, 350, 840) if full_body else Rect2(75, 145, 470, 530)
 var portrait = TextureRect.new()
 portrait.texture = atlas
 portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return portrait
