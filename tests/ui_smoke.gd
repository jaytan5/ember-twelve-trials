extends SceneTree
const Main = preload("res://main.tscn")
var ui
var errors = 0

func _initialize() -> void:
 call_deferred("run")

func settle() -> void:
 for _i in range(5): await process_frame

func capture(name_value: String) -> void:
 await settle()
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test-results/" + name_value + ".png")
 check_bounds(ui.layout)
 if is_instance_valid(ui.modal): check_bounds(ui.modal)
 print("UI SCREEN: ", name_value)

func check_bounds(node: Node) -> void:
 if node is Button and node.get_meta("card_view", false): check_card_contents(node, node.get_global_rect())
 if node is Control and node.visible and (node is Button or node is Label):
  var rect: Rect2 = node.get_global_rect()
  var clipped = false
  var parent = node.get_parent()
  while parent != null:
   if parent is ScrollContainer: clipped = true
   parent = parent.get_parent()
  if not clipped and (rect.end.y > ui.size.y + 2 or rect.end.x > ui.size.x + 2):
   printerr("OVERFLOW: ", node.text, " rect ", rect, " canvas ", ui.size)
   errors += 1
 for child in node.get_children(): check_bounds(child)

func check_card_contents(node: Node, card_rect: Rect2) -> void:
 if node is Label and node.get_global_rect().end.y > card_rect.end.y + 1:
  printerr("OVERFLOW: card text ", node.text)
  errors += 1
 for child in node.get_children(): check_card_contents(child, card_rect)

func click_node(node: Control) -> void:
 var p = node.get_global_rect().get_center()
 var motion = InputEventMouseMotion.new()
 motion.position = p
 root.push_input(motion)
 var press = InputEventMouseButton.new()
 press.position = p
 press.button_index = MOUSE_BUTTON_LEFT
 press.pressed = true
 root.push_input(press)
 var release = InputEventMouseButton.new()
 release.position = p
 release.button_index = MOUSE_BUTTON_LEFT
 release.pressed = false
 root.push_input(release)
 await settle()

func run() -> void:
 root.size = Vector2i(1600, 900)
 ui = Main.instantiate()
 root.add_child(ui)
 await capture("01-home")
 await test_navigation()
 ui.game.new_run("venom", 18)
 ui.on_menu = false
 ui.render()
 await capture("02-battle")
 # Real input: click a visible playable card, including its child controls.
 var hand = ui.find_child("HandCards", true, false)
 var index = 0
 while ui.game.s.energy < ui.Data.card(ui.game.s.hand[index]).cost: index += 1
 var played: int = ui.game.s.played
 await click_node(hand.get_child(index))
 if ui.game.s.played != played + 1:
  printerr("FAIL: card mouse input")
  errors += 1
 var turn: int = ui.game.s.turn
 var key = InputEventKey.new()
 key.keycode = KEY_SPACE
 key.pressed = true
 root.push_input(key)
 await settle()
 if ui.game.s.turn != turn + 1:
  printerr("FAIL: space end-turn input")
  errors += 1
 ui.game.s.stage = 3
 ui.game.start_battle()
 ui.render()
 await capture("03-boss")
 for enemy in ui.game.s.enemies: enemy.hp = 0
 ui.game.check_outcome()
 ui.render()
 await capture("04-reward")
 ui.game.take_card(0)
 ui.render()
 await capture("05-relic")
 ui.game.take_relic(0)
 ui.render()
 await capture("06-camp")
 ui.show_deck("upgrade")
 await capture("07-deck")
 ui.confirm_deck_change(0, "upgrade")
 await capture("08-upgrade")
 ui.close_modal()
 ui.show_help()
 await capture("09-help")
 ui.close_modal()
 ui.game.s.stage = 12
 ui.game.s.phase = "victory"
 ui.game.s.wins = 12
 ui.render()
 await capture("10-victory")
 ui.game.s.phase = "defeat"
 ui.render()
 await capture("11-defeat")
 ui.game.s.stage = 2
 ui.game.start_battle()
 ui.render()
 await capture("12-two-enemies")
 await test_deck_drag()
 for route in ["neutral", "venom", "bastion", "fury"]:
  ui.show_catalog(route)
  await capture("catalog-" + route)
 ui.show_catalog_card("coating", "venom")
 await capture("catalog-upgrade")
 ui.close_modal()
 ui.game.new_run("fury", 24)
 ui.game.s.hand = ["battle_trance+", "warcry", "rage_slash+", "blood_charge", "blizzard+"]
 ui.game.s.fury = 8
 ui.game.s.fury_engine = 2
 ui.game.s.next_draw = 2
 ui.game.s.next_block = 11
 ui.game.s.next_energy = 3
 ui.game.s.recoverable_hp = 12
 ui.render()
 await capture("expanded-fury-battle")
 ui.game.new_run("venom", 24)
 ui.game.s.hand = ["coating+", "detonate+", "recycle+", "corrosion+", "shield_charge+"]
 ui.game.s.coating = 3
 ui.render()
 await capture("expanded-venom-battle")
 ui.game.new_run("bastion", 24)
 ui.game.s.hand = ["hold+", "thorn_armor+", "thorn_growth+", "thorn_storm+", "blizzard+"]
 ui.game.s.retain_cap = 16
 ui.game.s.temp_thorns = 3
 ui.game.s.thorns = 5
 ui.game.s.next_energy = 3
 ui.game.s.next_block = 14
 ui.game.s.next_draw = 1
 ui.game.s.recoverable_hp = 12
 ui.render()
 await capture("balance-bastion-battle")
 ui.show_catalog_card("hold", "bastion")
 await capture("balance-hold-upgrade")
 ui.close_modal()
 ui.game.new_run("venom", 24)
 ui.game.s.hand = ["mend+", "polymath+", "stockpile+", "catalyst+", "blizzard+"]
 ui.render()
 await capture("balance-neutral-battle")
 ui.game.new_run("fury", 24)
 ui.game.s.hand = ["polymath", "stockpile", "blizzard", "aegis", "erudition", "mend", "sunder", "brace", "guard", "quick"]
 ui.game.s.barrier = 1
 ui.game.s.enemies[0].frozen = 1
 ui.render()
 await capture("new-ten-card-hand")
 expect(ui.game.s.hand.size() == 10, "ten card hand renders")
 expect(ui.find_child("EnemyIntent0", true, false).text == "冰冻 · 本次无法行动", "freeze shown independently of intent visibility")
 ui.show_catalog_card("stockpile", "neutral")
 await capture("new-x-cost-upgrade")
 ui.close_modal()
 await test_difficulty_ui()
 await test_display_scaling()
 print("UI CHECKS FAILED: ", errors)
 quit(0 if errors == 0 else 1)

func expect(condition: bool, title: String) -> void:
 if not condition:
  errors += 1
  printerr("FAIL: ", title)
 else: print("UI PASS: ", title)

func press_key(keycode: int) -> void:
 var key = InputEventKey.new()
 key.keycode = keycode
 key.pressed = true
 root.push_input(key)
 await settle()

func test_navigation() -> void:
 # All UI checks use the isolated APPDATA selected by run_checks.ps1.
 DirAccess.remove_absolute(ProjectSettings.globalize_path("user://run_save.json"))
 ui.render()
 await settle()
 expect(ui.screen == "home" and ui.find_child("HomeContinue", true, false).disabled, "fresh launch shows home and disables empty continue")
 await click_node(ui.find_child("HomeSettings", true, false))
 var slider = ui.find_child("Volume_master", true, false)
 slider.value = 31
 ui.find_child("Volume_effects", true, false).value = 48
 expect(is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.31), "master slider updates live audio")
 ui.settings.master_volume = 1.0
 ui.settings.effects_volume = 1.0
 ui.settings.load_settings()
 expect(is_equal_approx(ui.settings.master_volume, 0.31) and is_equal_approx(ui.settings.effects_volume, 0.48), "settings persist independently of adventure")
 slider.value = 0
 expect(AudioServer.is_bus_mute(0), "zero volume mutes audio")
 slider.value = 80
 await capture("navigation-settings")
 ui.close_modal()
 await click_node(ui.find_child("HomeNew", true, false))
 expect(ui.screen == "routes" and not ui.resuming, "new adventure enters route picker")
 await click_node(ui.find_child("Route_bastion", true, false))
 await capture("navigation-routes")
 await click_node(ui.find_child("ConfirmRoute", true, false))
 expect(ui.screen == "map" and ui.game.s.route == "bastion" and ui.game.s.deck.size() == 17, "route confirmation creates adventure on map")
 await capture("navigation-map")
 expect(ui.find_child("ChapterMap", true, false).get_child_count() == 4, "map has four chapter areas")
 for stage in range(1, 13):
  expect(ui.find_child("MapStage_%d" % stage, true, false).disabled == (stage != 1), "only current map stage available: %d" % stage)
 var before = ui.game.s.duplicate(true)
 await press_key(KEY_SPACE)
 await press_key(KEY_1)
 ui.enter_map_stage(2)
 expect(ui.screen == "map" and ui.game.s == before, "map blocks combat hotkeys and future-stage access")
 await click_node(ui.find_child("MapStage_1", true, false))
 expect(ui.screen == "run" and ui.game.s == before, "map entry preserves prepared battle")
 await capture("navigation-battle")
 var hero: Rect2 = ui.find_child("HeroPanel", true, false).get_global_rect()
 var hand: Rect2 = ui.find_child("HandScroll", true, false).get_global_rect()
 var end: Rect2 = ui.find_child("EndTurn", true, false).get_global_rect()
 expect(hero.end.x <= hand.position.x and hand.end.x <= end.position.x, "hero left and end turn right leave space for hand")
 await click_node(ui.find_child("EndTurn", true, false))
 expect(ui.game.s.turn == 2 and ui.game.s.hand.size() == 7, "end-turn button retains hand and draws two")
 before = ui.game.s.duplicate(true)
 await click_node(ui.find_child("SettingsButton", true, false))
 await capture("navigation-menu")
 await press_key(KEY_SPACE)
 expect(ui.game.s == before, "settings menu pauses combat input")
 await click_node(ui.find_child("Menu_关卡地图", true, false))
 await click_node(ui.find_child("MapStage_1", true, false))
 expect(ui.game.s == before, "battle-map-battle keeps hand enemies hp and turn")
 await click_node(ui.find_child("DrawPile", true, false))
 expect(is_instance_valid(ui.modal), "vertical draw pile button opens pile")
 ui.close_modal()
 ui.return_home()
 await settle()
 await click_node(ui.find_child("HomeContinue", true, false))
 expect(ui.screen == "routes" and ui.resuming, "continue also opens route confirmation")
 for route in ["venom", "bastion", "fury"]:
  expect(ui.find_child("Route_" + route, true, false).disabled, "saved route locked: " + route)
 for difficulty in ["easy", "normal", "hard"]:
  expect(ui.find_child("Difficulty_" + difficulty, true, false).disabled, "saved difficulty locked: " + difficulty)
 await capture("navigation-continue")
 await click_node(ui.find_child("ConfirmRoute", true, false))
 expect(ui.screen == "map" and ui.game.s == before, "continue preserves entire saved state")
 await click_node(ui.find_child("MapStage_1", true, false))
 for enemy in ui.game.s.enemies: enemy.hp = 0
 ui.game.check_outcome()
 ui.commit()
 ui.open_map()
 ui.enter_map_stage(1)
 expect(ui.game.s.phase == "reward", "map resumes unclaimed reward without new battle")
 ui.game.take_card(-1)
 ui.game.s.camp_used = true
 ui.advance()
 await settle()
 expect(ui.screen == "map" and ui.game.s.stage == 2 and ui.game.s.phase == "battle", "after camp next stage opens on map")
 expect(ui.find_child("MapStage_1", true, false).disabled and not ui.find_child("MapStage_2", true, false).disabled, "completed stage locked and next stage unlocked")
 await capture("navigation-map-progress")
 ui.enter_map_stage(2)
 ui.game.s.hand = ["guard", "guard", "guard", "guard", "guard", "guard", "guard", "guard", "guard", "guard"]
 ui.game.s.energy = 3
 ui.render()
 await settle()
 var count: int = ui.game.s.played
 await press_key(KEY_0)
 expect(ui.game.s.played == count + 1 and ui.game.s.hand.size() == 9, "zero hotkey plays tenth card")
 ui.return_home()
 ui.open_new_routes()
 ui.confirm_route()
 await settle()
 expect(is_instance_valid(ui.modal), "new adventure asks before replacing existing save")
 ui.close_modal()
 ui.return_home()

func test_display_scaling() -> void:
 ui.game.new_run("bastion", 18)
 ui.screen = "run"
 ui.render()
 for dimensions in [Vector2i(1280, 720), Vector2i(1024, 768)]:
  root.size = dimensions
  await settle()
  expect(is_equal_approx(ui.size.x / ui.size.y, 16.0 / 9.0), "canvas keeps 16:9 at " + str(dimensions))
  await capture("scaled-battle-%dx%d" % [dimensions.x, dimensions.y])
  ui.open_map()
  await capture("scaled-map-%dx%d" % [dimensions.x, dimensions.y])
  ui.enter_map_stage(1)
 root.size = Vector2i(1600, 900)
 await settle()

func drag_to(source: Control, destination: Vector2, should_start: bool = true) -> void:
 var start = source.get_global_rect().get_center()
 var motion = InputEventMouseMotion.new()
 motion.position = start
 motion.global_position = start
 root.push_input(motion)
 var press = InputEventMouseButton.new()
 press.position = start
 press.global_position = start
 press.button_index = MOUSE_BUTTON_LEFT
 press.button_mask = MOUSE_BUTTON_MASK_LEFT
 press.pressed = true
 root.push_input(press)
 await process_frame
 for position in [start + Vector2(24, 10), destination]:
  motion = InputEventMouseMotion.new()
  motion.position = position
  motion.global_position = position
  motion.relative = position - start
  motion.button_mask = MOUSE_BUTTON_MASK_LEFT
  root.push_input(motion)
  await process_frame
 expect(root.gui_is_dragging() == should_start, "native drag state")
 var release = InputEventMouseButton.new()
 release.position = destination
 release.global_position = destination
 release.button_index = MOUSE_BUTTON_LEFT
 release.pressed = false
 root.push_input(release)
 await settle()

func test_deck_drag() -> void:
 ui.game.enter_camp()
 while ui.game.s.deck.size() < 30: ui.game.acquire_card("guard")
 ui.game.acquire_card("detonate+")
 ui.render()
 ui.show_deck_manager()
 await capture("deck-30-full")
 var reserve_zone = ui.find_child("ReserveZone", true, false)
 var active_card = ui.find_child("DeckCard0", true, false)
 var moved_id: String = ui.game.s.deck[0]
 await drag_to(active_card, ui.find_child("ReserveCard0", true, false).get_global_rect().get_center())
 expect(ui.game.s.deck.size() == 29 and ui.game.s.reserve == ["detonate+", moved_id], "mouse drag from active deck to reserve retains card")
 var active_zone = ui.find_child("DeckZone", true, false)
 var reserve_card = ui.find_child("ReserveCard0", true, false)
 await drag_to(reserve_card, active_zone.get_global_rect().position + Vector2(8, 180))
 expect(ui.game.s.deck.size() == 30 and ui.game.s.deck[-1] == "detonate+" and ui.game.s.reserve == [moved_id], "mouse drag into deck preserves upgrade")
 await capture("deck-swap-complete")
 active_zone = ui.find_child("DeckZone", true, false)
 reserve_card = ui.find_child("ReserveCard0", true, false)
 await drag_to(reserve_card, active_zone.get_global_rect().position + Vector2(8, 180), false)
 expect(ui.game.s.deck.size() == 30 and ui.game.s.reserve.size() == 1, "full deck rejects mouse drag")
 var before = ui.game.s.deck.duplicate()
 active_card = ui.find_child("DeckCard0", true, false)
 await drag_to(active_card, Vector2(10, 10))
 expect(ui.game.s.deck == before, "drop outside zones cancels without losing card")
 ui.close_modal()
 ui.game.s.shop_cards = ["coating+"]
 ui.game.s.shop_sold = []
 ui.game.s.gold = 100
 ui.buy_shop_card(0)
 await settle()
 expect(is_instance_valid(ui.modal) and ui.game.s.reserve.has("coating+") and ui.game.s.gold == 55, "overflow purchase automatically opens manager")
 await capture("deck-overflow-notice")
 ui.close_modal()
 ui.game.next_stage()
 ui.render()
 ui.show_deck_manager()
 await settle()
 active_card = ui.find_child("DeckCard0", true, false)
 reserve_zone = ui.find_child("ReserveZone", true, false)
 await drag_to(active_card, reserve_zone.get_global_rect().position + Vector2(8, 180), false)
 expect(ui.game.s.deck.size() == 30, "battle manager is read only")
 ui.close_modal()

func test_difficulty_ui() -> void:
 for difficulty in ["easy", "normal", "hard"]:
  ui.on_menu = true
  ui.render()
  await settle()
  await click_node(ui.find_child("Difficulty_" + difficulty, true, false))
  expect(ui.selected_difficulty == difficulty, "mouse difficulty selection: " + difficulty)
  await capture("difficulty-menu-" + difficulty)
  ui.start_new()
  ui.enter_map_stage(1)
  expect(ui.game.s.difficulty == difficulty, "selection starts correct difficulty")
  ui.game.s.stage = 3
  ui.game.start_battle()
  ui.game.s.enemies[0].step = 2
  ui.render()
  await capture("difficulty-battle-" + difficulty)
  var intent = ui.find_child("EnemyIntent0", true, false)
  expect(intent.text == ("连续攻击 6 ×2（共 12）" if difficulty == "easy" else "行动未知"), "battle preview text: " + difficulty)
  if difficulty != "easy":
   var hidden_color = intent.get_theme_color("font_color")
   expect(hidden_color == ui.MUTED and intent.tooltip_text == "", "hidden attack has no color or tooltip leak")
   for step in [1, 3]:
    ui.game.s.enemies[0].step = step
    ui.render()
    await settle()
    intent = ui.find_child("EnemyIntent0", true, false)
    expect(intent.text == "行动未知" and intent.get_theme_color("font_color") == hidden_color, "defense/buff reveal no advance hint")
  ui.show_stage(3)
  await capture("difficulty-stage-" + difficulty)
  ui.close_modal()
  var expected_enemies: Array = ui.game.s.enemies.duplicate(true)
  ui.persist()
  ui.selected_difficulty = "normal" if difficulty != "normal" else "easy"
  expect(ui.game.load_run() and ui.game.s.difficulty == difficulty and ui.game.s.enemies == expected_enemies, "continue ignores menu difficulty and preserves enemy stats")
