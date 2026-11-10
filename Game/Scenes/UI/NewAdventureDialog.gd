extends RefCounted
## New-run presentation only; the host owns starting and saving the adventure.
const DATA = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
const ART_BUTTON = preload("res://Game/Scenes/MainMenu/HomeMenuButton.gd")
const CLOSE_ICON = preload("res://Game/Assets/UI/Settings/关闭按钮_圆徽章.svg")
const PRIMARY_ART = preload("res://Game/Assets/UI/MainMenu/圆角立体版/主按钮_红金.png")
const SECONDARY_ART = preload("res://Game/Assets/UI/MainMenu/圆角立体版/次按钮_古铜棕.png")
const WOOD = Color("412a20")
const GOLD = Color("dca74b")
const GOLD_LIGHT = Color("f4d58d")
const PAPER = Color("f4e3c2")
const PAPER_LIGHT = Color("fff2d6")
const MUTED_INK = Color("80664e")
const RED = Color("9e3528")

static func show(ui: Control) -> void:
 var body = ui.open_modal("开始新的冒险？", Vector2(740, 452))
 ui.modal.name = "NewAdventureDialog"
 var frame = body.get_parent() as PanelContainer
 frame.name = "AdventureDialogFrame"
 frame.add_theme_stylebox_override("panel", _style(WOOD, GOLD, 26, 22, 5, 14))
 var old_heading = body.get_child(0)
 body.remove_child(old_heading)
 old_heading.queue_free()
 body.add_theme_constant_override("separation", 14)
 body.add_child(_title_bar(ui))

 var paper = PanelContainer.new()
 paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
 paper.add_theme_stylebox_override("panel", _style(PAPER, GOLD, 18, 20, 3, 5))
 body.add_child(paper)
 var content = VBoxContainer.new()
 content.add_theme_constant_override("separation", 18)
 paper.add_child(content)

 var selection = HBoxContainer.new()
 selection.add_theme_constant_override("separation", 14)
 selection.add_child(_selection_card(ui, "天赋路线", DATA.ROUTES[ui.selected_route].name, "SelectedRoute"))
 selection.add_child(_selection_card(ui, "挑战难度", DATA.DIFFICULTIES[ui.selected_difficulty].name, "SelectedDifficulty"))
 content.add_child(selection)

 var notice = PanelContainer.new()
 notice.add_theme_stylebox_override("panel", _style(Color("edd4ad"), Color("c69b62"), 12, 12, 1))
 var notice_body = VBoxContainer.new()
 notice_body.add_theme_constant_override("separation", 4)
 notice.add_child(notice_body)
 notice_body.add_child(ui.label("存档提醒", 18, RED))
 var warning = ui.paragraph("新的冒险会替换本地的上一局存档。", 18, WOOD)
 warning.name = "SaveReplacementNotice"
 notice_body.add_child(warning)
 content.add_child(notice)

 var actions = HBoxContainer.new()
 actions.alignment = BoxContainer.ALIGNMENT_CENTER
 actions.add_theme_constant_override("separation", 18)
 var cancel = _button(ui, "返回选择", false, ui.close_modal)
 cancel.name = "CancelNewAdventure"
 var confirm = _button(ui, "确认开始", true, ui.start_new)
 confirm.name = "ConfirmNewAdventure"
 actions.add_child(cancel)
 actions.add_child(confirm)
 content.add_child(actions)
 cancel.focus_neighbor_right = confirm.get_path()
 confirm.focus_neighbor_left = cancel.get_path()
 cancel.grab_focus.call_deferred()

static func _title_bar(ui: Control) -> PanelContainer:
 var plaque = PanelContainer.new()
 plaque.custom_minimum_size.y = 70
 plaque.add_theme_stylebox_override("panel", _style(RED, GOLD_LIGHT, 17, 9, 3, 6))
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation", 12)
 plaque.add_child(row)
 var title = ui.label("开始新的冒险？", 29, PAPER_LIGHT)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 title.add_theme_constant_override("outline_size", 4)
 title.add_theme_color_override("font_outline_color", WOOD)
 title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
 title.add_theme_constant_override("shadow_offset_y", 3)
 row.add_child(title)
 var close = ART_BUTTON.new()
 close.name = "CloseNewAdventure"
 close.texture_normal = CLOSE_ICON
 close.custom_minimum_size = Vector2(52, 52)
 close.tooltip_text = "关闭"
 close.pressed.connect(ui.settings.play_click)
 close.pressed.connect(ui.close_modal)
 row.add_child(close)
 return plaque

static func _selection_card(ui: Control, caption: String, value: String, node_name: String) -> PanelContainer:
 var card = PanelContainer.new()
 card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 card.custom_minimum_size.y = 88
 card.add_theme_stylebox_override("panel", _style(PAPER_LIGHT, Color("cba361"), 12, 13, 2))
 var column = VBoxContainer.new()
 column.add_theme_constant_override("separation", 4)
 card.add_child(column)
 column.add_child(ui.label(caption, 16, MUTED_INK))
 var value_label = ui.label(value, 26, RED)
 value_label.name = node_name
 column.add_child(value_label)
 return card

static func _button(ui: Control, caption: String, primary: bool, action: Callable) -> TextureButton:
 var atlas = AtlasTexture.new()
 atlas.atlas = PRIMARY_ART if primary else SECONDARY_ART
 atlas.region = Rect2(137, 99, 1890, 560) if primary else Rect2(127, 94, 1916, 568)
 var button = ART_BUTTON.new()
 button.texture_normal = atlas
 button.custom_minimum_size = Vector2(244, 72)
 button.set_caption(caption)
 button.caption_label.add_theme_font_size_override("font_size", 27)
 var mask = BitMap.new()
 mask.create_from_image_alpha(atlas.get_image(), 0.5)
 button.texture_click_mask = mask
 button.pressed.connect(ui.settings.play_click)
 button.pressed.connect(action)
 return button

static func _style(fill: Color, border: Color, radius: int, padding: int, border_width: int, shadow_size: int = 0) -> StyleBoxFlat:
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
