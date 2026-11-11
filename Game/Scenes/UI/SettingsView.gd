extends Node

const SLIDER_KNOB = preload("res://Game/Assets/UI/Settings/音量旋钮.svg")
const CLOSE_ICON = preload("res://Game/Assets/UI/Settings/关闭按钮_圆徽章.svg")
const SETTINGS_EMBLEM = preload("res://Game/Assets/UI/MainMenu/圆角立体版/设置_圆齿轮.png")
const MENU_BUTTON = preload("res://Game/Scenes/MainMenu/HomeMenuButton.gd")
const PRIMARY_BUTTON_ART = preload("res://Game/Assets/UI/MainMenu/圆角立体版/主按钮_红金.png")
const SECONDARY_BUTTON_ART = preload("res://Game/Assets/UI/MainMenu/圆角立体版/次按钮_古铜棕.png")
const PRIMARY_BUTTON_REGION = Rect2(137, 99, 1890, 560)
const SECONDARY_BUTTON_REGION = Rect2(127, 94, 1916, 568)

const WOOD_DARK = Color("412a20")
const WOOD = Color("68432d")
const GOLD = Color("dca74b")
const GOLD_LIGHT = Color("f4d58d")
const PAPER = Color("f4e3c2")
const PAPER_LIGHT = Color("fff2d6")
const INK = Color("412a20")
const MUTED_INK = Color("80664e")
const RED = Color("9e3528")

func show_game_menu(ui: Control) -> void:
 var art = load("res://Game/Scenes/UI/AdventureUI.gd")
 var body = art.begin(ui, "冒险菜单", Vector2(780, 622), SETTINGS_EMBLEM)
 var paper = art.paper(ui)
 paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_child(paper)
 var content = ui.column(16)
 paper.add_child(content)
 var context = "%s  ·  %s难度  /  第 %d 关" % [ui.Data.ROUTES[ui.game.s.route].name, ui.game.difficulty_info().name, ui.game.s.stage]
 content.add_child(art.note(ui, context, 18))
 content.add_child(art.divider(ui))
 var grid = GridContainer.new()
 grid.columns = 2
 grid.add_theme_constant_override("h_separation", 22)
 grid.add_theme_constant_override("v_separation", 14)
 grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 for item in [["关卡地图", ui.open_map], ["卡组", ui.show_deck_manager], ["图鉴", ui.show_catalog], ["玩法", ui.show_help], ["保存", ui.manual_save], ["声音与显示", ui.show_settings]]:
  var action = art.button(ui, item[0], item[1], false, Vector2(280, 68))
  action.name = "Menu_" + str(item[0])
  grid.add_child(action)
 content.add_child(grid)
 content.add_child(art.divider(ui))
 var hint = art.note(ui, "冒险会自动保存，也可以在这里手动保存。", 16)
 hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
 content.add_child(hint)
 var actions = ui.row(18)
 actions.alignment = BoxContainer.ALIGNMENT_CENTER
 actions.add_child(art.button(ui, "返回主界面", ui.return_home, false, Vector2(280, 68)))
 var back = art.button(ui, "返回冒险", ui.close_modal, true, Vector2(280, 68))
 back.name = "MenuReturn"
 actions.add_child(back)
 body.add_child(actions)

func show_settings(ui: Control) -> void:
 var body = _begin_modal(ui, "基础设置", Vector2(1120, 760))
 var paper = _paper_panel()
 paper.custom_minimum_size.y = 600
 paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_child(paper)

 var content = VBoxContainer.new()
 content.add_theme_constant_override("separation", 11)
 paper.add_child(content)

 var intro = ui.paragraph("调整适合你的声音与显示方式。设置会自动保存。", 18, MUTED_INK)
 intro.custom_minimum_size.y = 30
 content.add_child(intro)

 content.add_child(_section_heading(ui, "声音设置", "调整后立即生效"))
 var volume_controls: Dictionary = {}
 volume_controls["master"] = _volume_row(ui, "总音量", "master", ui.settings.master_volume)
 content.add_child(volume_controls["master"]["row"])
 volume_controls["music"] = _volume_row(ui, "背景音乐音量", "music", ui.settings.music_volume)
 content.add_child(volume_controls["music"]["row"])
 volume_controls["effects"] = _volume_row(ui, "音效音量", "effects", ui.settings.effects_volume)
 content.add_child(volume_controls["effects"]["row"])

 var audio_actions = HBoxContainer.new()
 audio_actions.add_theme_constant_override("separation", 10)
 _add_spacer(audio_actions)
 var preview_button = _art_button(ui, "试听音效", true, Vector2(150, 42), ui.settings.play_click)
 audio_actions.add_child(preview_button)
 content.add_child(audio_actions)

 content.add_child(_divider())
 content.add_child(_section_heading(ui, "显示设置", "窗口大小按 16:9 比例适配"))

 var mode_row = _setting_row(ui, "显示模式", "选择窗口或全屏显示")
 var mode_buttons = HBoxContainer.new()
 mode_buttons.add_theme_constant_override("separation", 8)
 var window_button: TextureButton
 var fullscreen_button: TextureButton
 window_button = _art_button(ui, "窗口", not ui.settings.fullscreen, Vector2(124, 44), func(): _set_display_mode(ui, false, window_button, fullscreen_button))
 fullscreen_button = _art_button(ui, "全屏", ui.settings.fullscreen, Vector2(124, 44), func(): _set_display_mode(ui, true, window_button, fullscreen_button))
 mode_buttons.add_child(window_button)
 mode_buttons.add_child(fullscreen_button)
 mode_row.add_child(mode_buttons)
 content.add_child(mode_row)
 _set_display_mode(ui, ui.settings.fullscreen, window_button, fullscreen_button, false)

 var ratio_row = _setting_row(ui, "画面比例", "适配当前游戏画面")
 var ratio_badge = PanelContainer.new()
 ratio_badge.custom_minimum_size = Vector2(112, 40)
 ratio_badge.add_theme_stylebox_override("panel", _style(PAPER_LIGHT, GOLD, 10, 8, 2))
 var ratio_text = Label.new()
 ratio_text.text = "16:9"
 ratio_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 ratio_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 ratio_text.add_theme_font_size_override("font_size", 19)
 ratio_text.add_theme_color_override("font_color", INK)
 ratio_badge.add_child(ratio_text)
 ratio_row.add_child(ratio_badge)
 content.add_child(ratio_row)

 content.add_child(_shortcut_strip(ui))
 content.add_child(_divider())

 var footer = HBoxContainer.new()
 footer.add_theme_constant_override("separation", 12)
 var restore_button = _art_button(ui, "恢复默认", false, Vector2(156, 44), func(): _restore_defaults(ui, volume_controls, window_button, fullscreen_button))
 footer.add_child(restore_button)
 _add_spacer(footer)
 var license_label = ui.label("版权、字体授权及 AI 资产声明", 16, MUTED_INK)
 footer.add_child(license_label)
 var details_button = _art_button(ui, "查看详情", true, Vector2(136, 44), func(): show_legal_details(ui))
 footer.add_child(details_button)
 content.add_child(footer)

func show_legal_details(ui: Control) -> void:
 var body = _begin_modal(ui, "版权与授权说明", Vector2(820, 500))
 var paper = _paper_panel()
 paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_child(paper)
 var content = VBoxContainer.new()
 content.add_theme_constant_override("separation", 18)
 paper.add_child(content)

 content.add_child(ui.paragraph(
  "字体：阿里妈妈方圆体、MiSans。\n阿里妈妈方圆体 © 2023 阿里巴巴（中国）有限公司；MiSans © 2020–2025 北京小米移动软件有限公司。字体按各自授权条款使用。",
  18, INK))
 content.add_child(_divider())
 var assets_notice = ui.paragraph(
  "美术与音乐说明：本游戏使用的美术及音乐资产由 AI 生成，用于本游戏的视觉与听觉呈现。字体遵循各自的授权条款。",
  18, INK)
 assets_notice.name = "AssetsNotice"
 content.add_child(assets_notice)

 var footer = HBoxContainer.new()
 _add_spacer(footer)
 var back_button = _art_button(ui, "返回基础设置", true, Vector2(188, 48), func(): show_settings(ui))
 footer.add_child(back_button)
 content.add_child(footer)

func _begin_modal(ui: Control, title: String, dimensions: Vector2, emblem: Texture2D = SETTINGS_EMBLEM, close_action: Callable = Callable()) -> VBoxContainer:
 var body = ui.open_modal(title, dimensions)
 var frame = body.get_parent() as PanelContainer
 if is_instance_valid(frame):
  frame.add_theme_stylebox_override("panel", _style(WOOD_DARK, GOLD, 28, 22, 5, 14))

 if body.get_child_count() > 0:
  var old_heading = body.get_child(0)
  body.remove_child(old_heading)
  old_heading.queue_free()

 body.add_child(_title_bar(ui, title, emblem, close_action))
 return body

func _title_bar(ui: Control, title: String, icon: Texture2D = SETTINGS_EMBLEM, close_action: Callable = Callable()) -> PanelContainer:
 var plaque = PanelContainer.new()
 plaque.custom_minimum_size.y = 72
 plaque.add_theme_stylebox_override("panel", _style(RED, GOLD_LIGHT, 18, 8, 3, 6))

 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation", 12)
 plaque.add_child(row)

 var emblem = TextureRect.new()
 emblem.texture = icon
 emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 emblem.custom_minimum_size = Vector2(54, 54)
 emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.add_child(emblem)

 var heading = ui.label(title, 31, PAPER_LIGHT)
 heading.add_theme_constant_override("outline_size", 4)
 heading.add_theme_color_override("font_outline_color", WOOD_DARK)
 heading.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
 heading.add_theme_constant_override("shadow_offset_x", 1)
 heading.add_theme_constant_override("shadow_offset_y", 3)
 heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 row.add_child(heading)
 _add_spacer(row)

 var close_button = TextureButton.new()
 close_button.name = "CloseSettingsButton"
 close_button.texture_normal = CLOSE_ICON
 close_button.texture_hover = CLOSE_ICON
 close_button.texture_pressed = CLOSE_ICON
 close_button.ignore_texture_size = true
 close_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
 close_button.custom_minimum_size = Vector2(54, 54)
 close_button.tooltip_text = "关闭" + title
 close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 close_button.focus_mode = Control.FOCUS_ALL
 close_button.pressed.connect(ui.settings.play_click)
 close_button.pressed.connect(close_action if close_action.is_valid() else ui.close_modal)
 close_button.mouse_entered.connect(func(): close_button.self_modulate = Color(1.12, 1.08, 1.0))
 close_button.mouse_exited.connect(func(): close_button.self_modulate = Color.WHITE)
 row.add_child(close_button)
 return plaque

func _paper_panel() -> PanelContainer:
 var panel = PanelContainer.new()
 panel.add_theme_stylebox_override("panel", _style(PAPER, GOLD, 20, 18, 3, 5))
 return panel

func _section_heading(ui: Control, title: String, hint: String) -> HBoxContainer:
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation", 10)
 var heading = ui.label(title, 24, RED)
 heading.add_theme_constant_override("outline_size", 1)
 heading.add_theme_color_override("font_outline_color", PAPER_LIGHT)
 heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 row.add_child(heading)
 var note = ui.label(hint, 15, MUTED_INK)
 note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 row.add_child(note)
 _add_spacer(row)
 return row

func _volume_row(ui: Control, caption: String, channel: String, current_value: float) -> Dictionary:
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation", 14)
 row.custom_minimum_size.y = 42

 var label = ui.label(caption, 18, INK)
 label.custom_minimum_size.x = 154
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 row.add_child(label)

 var slider = HSlider.new()
 slider.name = "Volume_" + channel
 slider.min_value = 0
 slider.max_value = 100
 slider.step = 1
 slider.value = current_value * 100.0
 slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 slider.custom_minimum_size = Vector2(280, 38)
 slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 slider.add_theme_stylebox_override("slider", _slider_track(Color("bda17d"), WOOD))
 slider.add_theme_stylebox_override("grabber_area", _slider_track(GOLD, Color("b47b2e")))
 slider.add_theme_stylebox_override("grabber_area_highlight", _slider_track(GOLD_LIGHT, GOLD))
 slider.add_theme_icon_override("grabber", SLIDER_KNOB)
 slider.add_theme_icon_override("grabber_highlight", SLIDER_KNOB)
 slider.add_theme_icon_override("grabber_pressed", SLIDER_KNOB)
 slider.add_theme_icon_override("grabber_disabled", SLIDER_KNOB)
 row.add_child(slider)

 var value_badge = PanelContainer.new()
 value_badge.custom_minimum_size = Vector2(66, 34)
 value_badge.add_theme_stylebox_override("panel", _style(PAPER_LIGHT, GOLD, 10, 6, 2))
 var value_text = Label.new()
 value_text.text = "%d%%" % int(round(slider.value))
 value_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 value_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 value_text.add_theme_font_size_override("font_size", 17)
 value_text.add_theme_color_override("font_color", INK)
 value_badge.add_child(value_text)
 row.add_child(value_badge)

 slider.value_changed.connect(func(value: float):
  ui.settings.set_volume(channel, value / 100.0)
  value_text.text = "%d%%" % int(round(value)))
 return {"row": row, "slider": slider, "label": value_text}

func _slider_track(fill: Color, border: Color) -> StyleBoxFlat:
 var track = _style(fill, border, 6, 0, 1)
 # HSlider uses the style's minimum height for its track, not the control height.
 track.content_margin_top = 5
 track.content_margin_bottom = 5
 return track

func _setting_row(ui: Control, title: String, hint: String) -> HBoxContainer:
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation", 10)
 row.custom_minimum_size.y = 46
 var text_stack = VBoxContainer.new()
 text_stack.add_theme_constant_override("separation", 1)
 text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var title_label = ui.label(title, 18, INK)
 text_stack.add_child(title_label)
 var hint_label = ui.label(hint, 14, MUTED_INK)
 text_stack.add_child(hint_label)
 row.add_child(text_stack)
 return row

func _set_display_mode(ui: Control, fullscreen: bool, window_button: TextureButton, fullscreen_button: TextureButton, save: bool = true) -> void:
 if save:
  ui.settings.set_fullscreen(fullscreen)
 window_button.texture_normal = window_button.get_meta("primary_art") if not fullscreen else window_button.get_meta("secondary_art")
 fullscreen_button.texture_normal = fullscreen_button.get_meta("primary_art") if fullscreen else fullscreen_button.get_meta("secondary_art")

func _restore_defaults(ui: Control, volume_controls: Dictionary, window_button: TextureButton, fullscreen_button: TextureButton) -> void:
 ui.settings.reset_defaults()
 for channel in ["master", "music", "effects"]:
  var control: Dictionary = volume_controls[channel]
  var value = float(ui.settings.get(channel + "_volume"))
  control["slider"].set_value_no_signal(value * 100.0)
  control["label"].text = "%d%%" % int(round(value * 100.0))
 _set_display_mode(ui, false, window_button, fullscreen_button, false)

func _shortcut_strip(ui: Control) -> PanelContainer:
 var strip = PanelContainer.new()
 strip.add_theme_stylebox_override("panel", _style(Color("ead4ac"), Color("c49a5b"), 12, 9, 1))
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation", 9)
 strip.add_child(row)
 row.add_child(_keycap("1–0"))
 row.add_child(ui.label("出牌", 15, MUTED_INK))
 row.add_child(_keycap("Space"))
 row.add_child(ui.label("结束回合", 15, MUTED_INK))
 row.add_child(_keycap("Esc"))
 row.add_child(ui.label("打开或关闭菜单", 15, MUTED_INK))
 _add_spacer(row)
 row.add_child(ui.label("快捷键", 15, RED))
 return strip

func _keycap(value: String) -> PanelContainer:
 var key = PanelContainer.new()
 key.custom_minimum_size = Vector2(46 if value.length() <= 3 else 62, 28)
 key.add_theme_stylebox_override("panel", _style(WOOD, GOLD, 7, 4, 1, 2))
 var text = Label.new()
 text.text = value
 text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 text.add_theme_font_size_override("font_size", 14)
 text.add_theme_color_override("font_color", PAPER_LIGHT)
 key.add_child(text)
 return key

func _divider() -> HSeparator:
 var divider = HSeparator.new()
 divider.add_theme_stylebox_override("separator", _style(Color("c8ad82"), Color("c8ad82"), 1, 0, 0))
 divider.custom_minimum_size.y = 2
 return divider

func _art_button(ui: Control, caption: String, primary: bool, minimum_size: Vector2, action: Callable) -> TextureButton:
 var primary_atlas = _button_texture(true)
 var secondary_atlas = _button_texture(false)
 var control = MENU_BUTTON.new()
 control.texture_normal = primary_atlas if primary else secondary_atlas
 control.set_meta("primary_art", primary_atlas)
 control.set_meta("secondary_art", secondary_atlas)
 control.custom_minimum_size = minimum_size
 control.pressed.connect(ui.settings.play_click)
 if action != ui.settings.play_click:
  control.pressed.connect(action)
 control.set_caption(caption)
 control.caption_label.add_theme_font_size_override("font_size", maxi(14, int(minimum_size.y * 0.45)))
 var hit_mask = BitMap.new()
 hit_mask.create_from_image_alpha(control.texture_normal.get_image(), 0.5)
 control.texture_click_mask = hit_mask
 return control

func _button_texture(primary: bool) -> AtlasTexture:
 var atlas = AtlasTexture.new()
 atlas.atlas = PRIMARY_BUTTON_ART if primary else SECONDARY_BUTTON_ART
 atlas.region = PRIMARY_BUTTON_REGION if primary else SECONDARY_BUTTON_REGION
 return atlas

func _style(fill: Color, border: Color, radius: int, padding: int, border_width: int, shadow_size: int = 0) -> StyleBoxFlat:
 var style = StyleBoxFlat.new()
 style.bg_color = fill
 style.border_color = border
 style.set_border_width_all(border_width)
 style.set_corner_radius_all(radius)
 style.content_margin_left = padding
 style.content_margin_right = padding
 style.content_margin_top = padding
 style.content_margin_bottom = padding
 if shadow_size > 0:
  style.shadow_color = Color(0.18, 0.08, 0.035, 0.42)
  style.shadow_size = shadow_size
  style.shadow_offset = Vector2(0, 3)
 return style

func _add_spacer(parent: Control) -> void:
 var spacer = Control.new()
 spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 parent.add_child(spacer)
