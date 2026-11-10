extends SceneTree
const Main = preload("res://main.tscn")
const Animator = preload("res://Game/Scenes/Battle/BattleAnimator.gd")
var ui
var errors = 0
var checks = 0
var observed: Array = []

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  errors += 1
  printerr("FAIL: ", title)

func settle() -> void:
 for _i in range(4): await process_frame

func capture(name_value: String) -> void:
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test-results/feedback-" + name_value + ".png")

func setup() -> void:
 ui.game.new_run("fury", 123)
 ui.screen = "run"
 ui.game.s.enemies = [ui.Data.enemy("测试敌人", 100, [ui.Data.defend(0)])]
 ui.game.s.strength = 0
 ui.game.s.hp = 80
 ui.game.s.max_hp = 80
 ui.game.s.energy = 20
 ui.game.s.hand = ["strike"]
 ui.render()
 observed.clear()
 await settle()

func run() -> void:
 root.size = Vector2i(1600, 900)
 root.gui_embed_subwindows = true
 ui = Main.instantiate()
 root.add_child(ui)
 await test_title()
 await test_retry_ui_and_fonts()
 ui.battle_animator.event_started.connect(func(event): observed.append(event.duplicate()))
 for entry in [[-1, 0, 0], [-1, 14, 1], [-1, 15, 2], [-1, 40, 2], [-1, 41, 3], [0, 19, 1], [0, 20, 2], [0, 50, 2], [0, 51, 3]]:
  check(Animator.impact_tier(entry[0], entry[1]) == entry[2], "impact threshold " + str(entry))
 await test_statuses()
 await test_deck_names()
 await test_animation_order()
 await test_lifesteal_and_turn()
 await test_death()
 print("UI FEEDBACK CHECKS: ", checks, " passed: ", checks - errors, " failed: ", errors)
 ui.queue_free()
 await process_frame
 quit(0 if errors == 0 else 1)

func test_title() -> void:
 await settle()
 check(ui.screen == "title" and ui.layout == null, "startup shows title without header or footer")
 check(ui.find_child("HomeNew", true, false) == null and ui.find_child("SettingsButton", true, false) == null, "title hides menu controls")
 var logo: TextureRect = ui.find_child("TitleLogo", true, false)
 var prompt: Label = ui.find_child("TitlePrompt", true, false)
 check(logo.texture != null and absf(logo.get_global_rect().get_center().x - ui.size.x / 2.0) < 1.0 and logo.get_global_rect().end.y < ui.size.y * 0.4, "logo centered in upper screen")
 check(prompt.text == "按任意键开始游戏" and prompt.get_global_rect().position.y > ui.size.y * 0.7, "small opening prompt sits below center")
 var video = ui.home_view_component.video
 var music = ui.settings.menu_music_player
 check(video.is_playing() and video.loop and music.playing and music.stream.loop, "title starts looping video and music")
 check(not ui.home_view_component.shade.visible, "title shows unshaded background")
 await create_timer(0.5).timeout
 await capture("title-screen")
 var motion = InputEventMouseMotion.new()
 motion.position = Vector2(900, 650)
 root.push_input(motion)
 check(ui.screen == "title", "incidental mouse motion keeps title visible")
 var video_time: float = video.stream_position
 var music_time: float = music.get_playback_position()
 var key = InputEventKey.new()
 key.keycode = KEY_ESCAPE
 key.pressed = true
 root.push_input(key)
 await settle()
 check(ui.screen == "home" and ui.find_child("HomeNew", true, false) != null and ui.modal == null, "any key reveals menu without opening settings")
 check(ui.layout == null and ui.find_child("TitlePrompt", true, false) == null, "home has no old header footer panel or opening prompt")
 var home: Control = ui.find_child("HomeScreen", true, false)
 var start: TextureButton = ui.find_child("HomeNew", true, false)
 var resume: TextureButton = ui.find_child("HomeContinue", true, false)
 var gear: TextureButton = ui.find_child("HomeSettings", true, false)
 check([start, resume, gear].all(func(node): return node.tooltip_text.is_empty()), "home buttons have no hover text including disabled continue")
 check(home.get_child_count() == 4 and home.get_children().filter(func(node): return node is PanelContainer or node is Label).is_empty(), "home shows only logo two standalone buttons and gear")
 check(start.size.x < ui.size.x * 0.2 and resume.size.x == start.size.x and absf(start.get_global_rect().get_center().x - ui.size.x * 0.5) < 1.0, "refined buttons are narrow and centered")
 check(start.get_global_rect().end.y < resume.get_global_rect().position.y and resume.get_global_rect().end.y < ui.size.y, "button ornaments fit with a clear gap and bottom margin")
 check(gear.get_global_rect().position.x > ui.size.x * 0.9 and gear.get_global_rect().end.y < ui.size.y * 0.15, "settings gear sits in upper right")
 check(not ui.home_view_component.shade.visible and ui.find_child("TitleLogo", true, false) != null, "menu retains bright background and original title logo")
 check(video == ui.home_view_component.video and video.stream_position >= video_time and music.get_playback_position() >= music_time, "reveal preserves video and music playback")
 await capture("title-menu-revealed")
 start.grab_focus()
 var down = InputEventKey.new()
 down.keycode = KEY_DOWN
 down.pressed = true
 root.push_input(down)
 await settle()
 check(root.gui_get_focus_owner() == (gear if resume.disabled else resume), "keyboard moves focus between menu actions")
 gear.grab_focus()
 var accept = InputEventKey.new()
 accept.keycode = KEY_ENTER
 accept.pressed = true
 root.push_input(accept)
 accept = accept.duplicate()
 accept.pressed = false
 root.push_input(accept)
 await settle()
 check(is_instance_valid(ui.modal) and ui.find_child("Volume_master", true, false) != null, "keyboard activates settings gear")
 ui.close_modal()
 gear.release_focus()
 for dimensions in [Vector2i(1280, 720), Vector2i(1024, 768)]:
  root.size = dimensions
  await settle()
  check(is_equal_approx(ui.size.x / ui.size.y, 16.0 / 9.0) and resume.get_global_rect().end.y < ui.size.y and gear.get_global_rect().end.x < ui.size.x, "menu scales inside the canvas at " + str(dimensions))
  await capture("home-%dx%d" % [dimensions.x, dimensions.y])
 root.size = Vector2i(1600, 900)
 await settle()
 await capture("warm-menu")
 var hover = InputEventMouseMotion.new()
 hover.position = start.get_global_rect().get_center()
 root.push_input(hover)
 await create_timer(0.16).timeout
 check(start.scale.x > 1.0 and start.self_modulate.r > 1.0, "hover highlights refined button without an outer panel")
 var broken_save = FileAccess.open("user://run_save.json", FileAccess.WRITE)
 broken_save.store_string("{}")
 broken_save.close()
 ui.open_continue_routes()
 await settle()
 check(ui.screen == "home" and is_instance_valid(ui.modal), "unreadable save produces a visible message without the removed footer")
 ui.close_modal()
 DirAccess.remove_absolute(ProjectSettings.globalize_path("user://run_save.json"))
 ui.render()
 await settle()
 start = ui.find_child("HomeNew", true, false)
 resume = ui.find_child("HomeContinue", true, false)
 gear = ui.find_child("HomeSettings", true, false)
 start.grab_focus()
 root.push_input(down)
 await create_timer(0.16).timeout
 check(resume.disabled and root.gui_get_focus_owner() == gear and resume.self_modulate.a < 1.0, "missing save dims continue and keyboard skips the disabled action")
 gear.release_focus()
 hover.position = Vector2(10, 450)
 root.push_input(hover)
 await create_timer(0.16).timeout
 await capture("home-no-save")
 ui.screen = "title"
 ui.render()
 await settle()
 var click = InputEventMouseButton.new()
 click.position = Vector2(1100, 510)
 click.button_index = MOUSE_BUTTON_LEFT
 click.pressed = true
 root.push_input(click)
 await settle()
 check(ui.screen == "home" and ui.modal == null, "mouse opening action does not also activate menu")
 ui.screen = "routes"
 ui.render()
 check(not video.is_playing() and music.playing, "route selection stops video but keeps music")
 ui.return_home()
 check(ui.screen == "home" and video.is_playing(), "returning home opens usable menu directly")

func test_retry_ui_and_fonts() -> void:
 check(ProjectSettings.get_setting("display/window/size/window_width_override") == 1280 and ProjectSettings.get_setting("display/window/size/window_height_override") == 720, "default window is 1280 by 720")
 check(ui.theme.default_font == ui.READING_FONT and ui.theme.get_font("font", "Button") == ui.DISPLAY_FONT, "MiSans body and FangYuan button fonts embedded")
 check(ui.DISPLAY_FONT.variation_opentype.get(2003265652) == 600.0, "FangYuan title uses readable medium-bold variable weight")
 for difficulty in ["easy", "normal", "hard", "legendary"]:
  ui.game.new_run("bastion", 42, difficulty)
  var before: Dictionary = ui.game.s.duplicate(true)
  ui.game.s.hp = 0
  ui.game.check_outcome()
  ui.screen = "run"
  ui.render()
  await settle()
  var retry = ui.find_child("RetryBattle", true, false)
  check(is_instance_valid(retry) == (difficulty != "legendary"), "retry button visibility " + difficulty)
  if difficulty == "easy" or difficulty == "legendary": await capture("defeat-" + difficulty)
  if difficulty != "legendary":
   var press = InputEventMouseButton.new()
   press.position = retry.get_global_rect().get_center()
   press.button_index = MOUSE_BUTTON_LEFT
   press.pressed = true
   root.push_input(press)
   press = press.duplicate()
   press.pressed = false
   root.push_input(press)
   await settle()
   check(ui.game.s.hp == before.hp and ui.game.s.hand.size() == before.hand.size() and ui.game.s.draw != before.draw and ui.screen == "run" and ui.find_child("HeroPanel", true, false) != null, "retry click restores opening battle " + difficulty)
   var saved = ui.Run.new()
   check(saved.load_run() and saved.s == ui.game.s, "retry saves restored state " + difficulty)
 ui.return_home()
 ui.open_new_routes()
 await settle()
 await capture("four-difficulties-fonts")
 check(ProjectSettings.get_setting("application/config/name") == "小泥团，出击！", "application name updated")
 check(OS.get_user_data_dir().replace("\\", "/").ends_with("/Godot/app_userdata/余烬十二关 · 卡牌 Demo"), "rename preserves legacy save and settings directory")
 for id in ["easy", "normal", "hard", "legendary"]:
  check(ui.find_child("Difficulty_" + id, true, false).tooltip_text.is_empty(), "difficulty has no hover text " + id)
 var displayed = collect_text(ui.find_child("TalentScreen", true, false))
 for removed in ["YOUR PATH", "选择一条战斗路线。以", "12 场战斗", "4 位 Boss", "3 条成长路线", "4 档难度", "路线决定起始卡组和奖励池", "建议先试", "EMBER", "选择起始路线和本局难度。", "一副卡牌，一条通往王座的路。"]:
  check(not removed in displayed, "removed route decoration: " + removed)
 check(ui.find_child("TalentFrame", true, false) != null and ui.find_child("TitleCopy", true, false).text == "选择你的天赋路线" and ui.find_child("SettingsButton", true, false) == null, "approved talent art replaces the old shell header")
 var cursor: Image = ui.game_cursor.texture.get_image()
 check(cursor.get_size() == Vector2i(48, 48) and cursor.detect_alpha() != Image.ALPHA_NONE and cursor.get_pixel(0, 0).a == 0, "sword cursor uses compact transparent PNG")
 ui.show_settings()
 await settle()
 ui.settings_view_component.show_legal_details(ui)
 await settle()
 var notice: Label = ui.find_child("AssetsNotice", true, false)
 check(is_instance_valid(notice) and "美术及音乐资产由 AI 生成" in notice.text and notice.get_theme_font_size("font_size") == 18, "settings details preserve readable AI asset notice")
 await capture("settings-asset-notice")
 ui.close_modal()

func collect_text(node: Node) -> String:
 var has_text = node is Label or node is Button or node.get_script() == preload("res://Game/Scenes/MainMenu/Components/TalentText.gd")
 var result: String = node.text + "\n" if has_text else ""
 for child in node.get_children(): result += collect_text(child)
 return result

func test_statuses() -> void:
 await setup()
 check(ui.battle_view_component.active_status_lines(ui.game.s).is_empty(), "zero statuses produce no text")
 check(not ui.find_child("HeroStatuses", true, false).visible, "empty status label hidden")
 await capture("no-statuses")
 ui.game.s.next_energy = 3
 ui.game.s.lifesteal = 75
 var lines: Array = ui.battle_view_component.active_status_lines(ui.game.s)
 check(lines.size() == 2 and "吸血 75%" in lines and "下回合能量 +3" in lines, "only existing current and queued statuses shown")
 ui.render()
 await settle()
 await capture("active-statuses")
 ui.game.s.recoverable_hp = 10
 ui.game.s.deck = ["strike"]
 ui.game.s.reserve = ["leech"]
 ui.render()
 check(not "汲取" in ui.find_child("HeroStatuses", true, false).text and not "汲取" in ui.find_child("HeroStatuses", true, false).tooltip_text, "reserve-only leech hides wound status and tooltip")
 for id in ["leech", "leech+"]:
  ui.game.s.deck = [id]
  check("汲取可恢复：10 生命" in ui.battle_view_component.active_status_lines(ui.game.s), "equipped leech shows available healing: " + id)
 ui.game.s.recoverable_hp = 0
 check(not "汲取" in "\n".join(ui.battle_view_component.active_status_lines(ui.game.s)), "equipped leech with no wounds stays hidden")
 await setup()

func test_deck_names() -> void:
 ui.game.enter_camp()
 while ui.game.s.deck.size() < 30: ui.game.acquire_card("guard")
 ui.game.acquire_card("battle_trance+")
 ui.game.acquire_card("whirlwind+")
 ui.game.acquire_card("rage_slash")
 ui.render()
 ui.show_deck_manager()
 await settle()
 var first = ui.find_child("DeckCard0", true, false)
 var reserve = ui.find_child("ReserveCard0", true, false)
 check(first.text == ui.Data.card(ui.game.s.deck[0]).name and first.get_child_count() == 0, "active entry shows only name")
 check(reserve.text == "嗜血+" and reserve.get_child_count() == 0, "reserve entry shows only name with upgrade")
 check(first.size.y <= 45 and ui.find_child("DeckCard29", true, false).get_global_rect().end.y < 800, "thirty compact names fit panel")
 await capture("compact-deck")
 var motion = InputEventMouseMotion.new()
 motion.position = reserve.get_global_rect().get_center()
 motion.global_position = motion.position
 root.push_input(motion)
 await create_timer(0.8).timeout
 var tooltip = root.find_child("OwnedCardTooltip", true, false)
 if DisplayServer.get_name() != "headless":
  check(is_instance_valid(tooltip), "native mouse hover opens full card tooltip")
  if is_instance_valid(tooltip): await capture("card-hover")
 # Verify the native tooltip content also in headless runs.
 var preview = reserve._make_custom_tooltip("")
 check(preview.get_meta("card_view", false) and preview.tooltip_text.is_empty(), "hover preview uses full card without recursive tooltip")
 preview.free()
 motion = InputEventMouseMotion.new()
 motion.position = Vector2(5, 5)
 root.push_input(motion)
 ui.close_modal()
 await settle()

func test_animation_order() -> void:
 await setup()
 ui.persist()
 var before: Dictionary = ui.game.s.duplicate(true)
 var before_rng: int = ui.game.rng.state
 var saved = FileAccess.get_file_as_string("user://run_save.json")
 var panel: Control = ui.find_child("EnemyPanel0", true, false)
 var original_position = panel.position
 ui.play_card(0)
 check(ui.busy and ui.game.s == before and ui.game.rng.state == before_rng, "live state stays unchanged while animation begins")
 ui.play_card(0)
 ui.end_player_turn()
 var key = InputEventKey.new()
 key.keycode = KEY_ESCAPE
 key.pressed = true
 root.push_input(key)
 check(not is_instance_valid(ui.modal), "input is locked during animation")
 await ui.battle_animator.event_started
 await create_timer(0.04).timeout
 check(panel.position.distance_to(original_position) > 0.05, "target frame shakes before health loss")
 var fill: ProgressBar = ui.find_child("EnemyHealth0", true, false).get_node("HealthFill")
 check(fill.value == 100, "health does not jump before impact")
 await create_timer(0.19).timeout
 check(fill.value > 93 and fill.value < 100, "health visibly interpolates through intermediate values")
 check(ui.game.s == before and saved == FileAccess.get_file_as_string("user://run_save.json"), "state and save wait until health animation completes")
 await capture("health-in-motion")
 if ui.busy: await ui.combat_animation_finished
 check(ui.game.s.enemies[0].hp == 93 and ui.game.s.played == before.played + 1 and ui.game.s.turn == before.turn, "one action commits after animation, duplicate input ignored")
 check(not is_instance_valid(ui.find_child("CombatInputShield", true, false)), "input shield removed after completion")

func test_lifesteal_and_turn() -> void:
 await setup()
 ui.battle_animator.speed_scale = 3.0
 ui.game.s.hp = 10
 ui.game.s.lifesteal = 75
 ui.game.s.low_hp_crit = 50
 ui.game.s.hand = ["whirlwind+"]
 ui.game.s.enemies.append(ui.Data.enemy("第二敌人", 100, [ui.Data.defend(0)]))
 var expected = ui.Run.new()
 expected.s = ui.game.s.duplicate(true)
 expected.rng.state = ui.game.rng.state
 expected.play(0)
 ui.render()
 await settle()
 await ui.play_card(0)
 check(ui.game.s == expected.s and ui.game.rng.state == expected.rng.state, "animated random multiattack matches one rules evaluation and RNG")
 check(observed.size() == 8, "four hits each followed by their own lifesteal event")
 for i in range(0, observed.size(), 2):
  check(observed[i].kind == "damage" and observed[i + 1].kind == "heal", "lifesteal follows each damage event")
 await setup()
 ui.game.s.enemies[0].pattern = [ui.Data.attack(16, 2)]
 ui.game.s.thorns = 5
 ui.render()
 await settle()
 await ui.end_player_turn()
 check(ui.game.s.hp == 48 and ui.game.s.turn == 2, "enemy multiattack completes before next turn")
 check(observed.size() == 4 and observed[0].target == -1 and observed[1].target == 0 and observed[2].target == -1, "enemy hit and thorns animation order preserved")
 observed.clear()
 await ui.use_battle_potion()
 check(ui.game.s.hp == 68 and observed.size() == 1 and observed[0].kind == "heal", "potion animates healing before committing")

func test_death() -> void:
 await setup()
 ui.game.s.enemies[0].hp = 3
 ui.render()
 await settle()
 ui.play_card(0)
 check(ui.busy and ui.game.s.phase == "battle", "lethal hit does not immediately show reward")
 await ui.battle_animator.event_started
 check(ui.game.s.enemies[0].hp == 3 and ui.game.s.phase == "battle", "enemy remains unsettled until lethal animation")
 if ui.busy: await ui.combat_animation_finished
 check(ui.game.s.phase == "reward" and ui.game.s.enemies[0].hp == 0, "reward appears after lethal animation")
 await setup()
 ui.game.s.hp = 5
 ui.game.s.enemies[0].pattern = [ui.Data.attack(50)]
 ui.render()
 await settle()
 ui.end_player_turn()
 check(ui.busy and ui.game.s.phase == "battle", "player death also waits for animation")
 if ui.busy: await ui.combat_animation_finished
 check(ui.game.s.phase == "defeat" and ui.game.s.hp == 0, "defeat appears after player health reaches zero")
