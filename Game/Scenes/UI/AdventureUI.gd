extends RefCounted
## 六个冒险弹窗共用 SettingsView 的颜色、标题结构、字体与按钮素材。
const ART_BUTTON = preload("res://Game/Scenes/UI/AdventureArtButton.gd")
const CARD_ICON = preload("res://Game/Assets/UI/Adventure/卡牌徽记.png")
const CAMP_ICON = preload("res://Game/Assets/UI/Adventure/营火徽记.png")
const BOOK_ICON = preload("res://Game/Assets/UI/Adventure/手册徽记.png")
const WOOD = Color("412a20")
const GOLD = Color("dca74b")
const GOLD_LIGHT = Color("f4d58d")
const PAPER = Color("f4e3c2")
const PAPER_LIGHT = Color("fff2d6")
const MUTED_INK = Color("80664e")
const RED = Color("9e3528")
const BLUE = Color("2c4d70")
static var button_masks: Dictionary = {}

static func begin(ui: Control, title: String, dimensions: Vector2, icon: Texture2D = CARD_ICON) -> VBoxContainer:
 var body = ui.settings_view_component._begin_modal(ui, title, dimensions, icon)
 body.add_theme_constant_override("separation", 14)
 body.get_parent().name = "AdventureDialogFrame"
 return body

static func paper(ui: Control, padding: int = 18, pale: bool = false) -> PanelContainer:
 var node = PanelContainer.new()
 node.add_theme_stylebox_override("panel", ui.settings_view_component._style(PAPER_LIGHT if pale else PAPER, GOLD, 18, padding, 3, 5))
 return node

static func inset(ui: Control, padding: int = 12) -> PanelContainer:
 var node = PanelContainer.new()
 node.add_theme_stylebox_override("panel", ui.settings_view_component._style(Color("ead4ac"), Color("c49a5b"), 12, padding, 1, 2))
 return node

static func note(ui: Control, value: String, size: int = 16) -> Label:
 return ui.paragraph(value, size, MUTED_INK)

static func heading(ui: Control, value: String, size: int = 25) -> Label:
 return ui.label(value, size, RED)

static func badge(ui: Control, value: String, active: bool = false) -> PanelContainer:
 var node = inset(ui, 8)
 node.add_child(ui.label(value, 16, RED if active else WOOD))
 return node

static func button(ui: Control, caption: String, action: Callable, primary: bool = false, dimensions: Vector2 = Vector2(224, 60)) -> TextureButton:
 var node = ART_BUTTON.new()
 node.texture_normal = ui.settings_view_component._button_texture(primary)
 node.texture_hover = node.texture_normal
 node.texture_pressed = node.texture_normal
 node.custom_minimum_size = dimensions
 node.ignore_texture_size = true
 node.stretch_mode = TextureButton.STRETCH_SCALE
 node.set_caption(caption)
 var font_size = maxi(17, int(dimensions.y * 0.43))
 var face_width = minf(dimensions.x, dimensions.y * node.texture_normal.get_width() / node.texture_normal.get_height())
 var caption_font = node.caption_label.get_theme_font("font")
 while font_size > 17 and caption_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > face_width * 0.78:
  font_size -= 1
 node.caption_label.add_theme_font_size_override("font_size", font_size)
 node.pressed.connect(ui.settings.play_click)
 if action != ui.settings.play_click: node.pressed.connect(action)
 if not button_masks.has(primary):
  var mask = BitMap.new()
  mask.create_from_image_alpha(node.texture_normal.get_image(), 0.5)
  button_masks[primary] = mask
 node.texture_click_mask = button_masks[primary]
 return node

static func divider(ui: Control) -> HSeparator:
 return ui.settings_view_component._divider()

static func scroll_skin(ui: Control, scroll: ScrollContainer) -> void:
 var bar = scroll.get_v_scroll_bar()
 bar.custom_minimum_size.x = 12
 bar.add_theme_stylebox_override("scroll", ui.settings_view_component._style(Color("d7bc91"), Color("c6a56f"), 6, 1, 1))
 bar.add_theme_stylebox_override("grabber", ui.settings_view_component._style(GOLD, Color("a87434"), 6, 2, 1))
 bar.add_theme_stylebox_override("grabber_highlight", ui.settings_view_component._style(GOLD_LIGHT, GOLD, 6, 2, 1))
 bar.add_theme_stylebox_override("grabber_pressed", ui.settings_view_component._style(Color("bc863b"), WOOD, 6, 2, 1))

static func name_button(ui: Control, node: Button, route: String, upgraded: bool) -> void:
 var tint = _route_color(route)
 var normal = ui.settings_view_component._style(PAPER_LIGHT, tint, 9, 5, 1, 2)
 normal.border_width_left = 4
 node.add_theme_stylebox_override("normal", normal)
 node.add_theme_stylebox_override("hover", ui.settings_view_component._style(Color("fff4dd"), GOLD, 9, 5, 2, 3))
 node.add_theme_stylebox_override("pressed", ui.settings_view_component._style(Color("ddc394"), GOLD, 9, 5, 2))
 node.add_theme_color_override("font_color", RED if upgraded else WOOD)
 node.add_theme_color_override("font_hover_color", RED)
 node.add_theme_color_override("font_pressed_color", WOOD)

static func card(ui: Control, id: String, action: Callable, dimensions: Vector2 = Vector2(268, 310), locked: bool = false) -> Button:
 var c: Dictionary = ui.Data.card(id)
 var tint = _route_color(c.route)
 var node = Button.new()
 node.custom_minimum_size = dimensions
 node.disabled = locked
 node.focus_mode = Control.FOCUS_NONE
 node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 node.tooltip_text = c.name + "\n" + ui.Data.describe(c)
 node.add_theme_stylebox_override("normal", ui.settings_view_component._style(PAPER_LIGHT, GOLD, 15, 0, 3, 5))
 node.add_theme_stylebox_override("hover", ui.settings_view_component._style(Color("fff5df"), GOLD_LIGHT, 15, 0, 4, 6))
 node.add_theme_stylebox_override("pressed", ui.settings_view_component._style(Color("e4c99c"), GOLD, 15, 0, 3, 3))
 node.add_theme_stylebox_override("disabled", ui.settings_view_component._style(Color("dac9ac"), Color("b6a181"), 15, 0, 3, 2))
 node.pressed.connect(ui.settings.play_click)
 node.pressed.connect(action)
 var margin = MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 15)
 margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
 node.add_child(margin)
 var body = ui.column(10)
 body.mouse_filter = Control.MOUSE_FILTER_IGNORE
 margin.add_child(body)
 var header = ui.row(10)
 header.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var cost = PanelContainer.new()
 cost.custom_minimum_size = Vector2(43, 43)
 cost.add_theme_stylebox_override("panel", ui.settings_view_component._style(BLUE, GOLD_LIGHT, 20, 5, 3, 2))
 var cost_text = ui.label(ui.Data.cost_text(c), 25, PAPER_LIGHT)
 cost_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 cost.add_child(cost_text)
 header.add_child(cost)
 var name_label = ui.label(c.name, 23, RED if c.upgraded else WOOD)
 name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 header.add_child(name_label)
 body.add_child(header)
 var meta = ui.label(("通用" if c.route == "neutral" else ui.Data.ROUTES[c.route].name) + "  ·  " + c.kind + ("  ·  已升级" if c.upgraded else ""), 15, tint)
 body.add_child(meta)
 body.add_child(divider(ui))
 var description = RichTextLabel.new()
 description.text = ui.Data.describe(c)
 description.name = "CardDescription"
 description.custom_minimum_size.y = 96
 description.size_flags_vertical = Control.SIZE_EXPAND_FILL
 description.add_theme_font_override("normal_font", ui.READING_FONT)
 description.add_theme_font_size_override("normal_font_size", 17)
 description.add_theme_color_override("default_color", WOOD)
 description.mouse_filter = Control.MOUSE_FILTER_IGNORE
 description.scroll_active = true
 body.add_child(description)
 body.add_child(ui.label("已升级 · 不可重复锻造" if locked else ("单体 · 当前目标" if c.get("target", false) else "自身 / 全体效果"), 13, MUTED_INK))
 for child in node.get_children(): _passive(child)
 return node

static func _passive(node: Node) -> void:
 if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for child in node.get_children(): _passive(child)

static func help_layout(ui: Control, body: VBoxContainer, source: String) -> void:
 var panes = ui.row(18)
 panes.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var navigation = paper(ui, 14)
 navigation.custom_minimum_size.x = 245
 panes.add_child(navigation)
 var links = ui.column(9)
 navigation.add_child(links)
 links.add_child(heading(ui, "查阅目录", 23))
 links.add_child(divider(ui))
 var reading = paper(ui, 20)
 reading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panes.add_child(reading)
 var scroll = ScrollContainer.new()
 scroll.name = "HelpReadingScroll"
 scroll.custom_minimum_size.y = 575
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll_skin(ui, scroll)
 reading.add_child(scroll)
 var sections = ui.column(18)
 sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(sections)
 var section_index = 0
 for chunk in source.split("【", false):
  var end = chunk.find("】")
  if end < 0: continue
  var title = chunk.substr(0, end)
  var value = chunk.substr(end + 1).strip_edges()
  if section_index > 0: sections.add_child(divider(ui))
  var section = ui.column(10)
  section.name = "HelpSection_" + str(section_index)
  section.add_child(heading(ui, title, 27))
  section.add_child(ui.paragraph(value, 18, WOOD))
  sections.add_child(section)
  var link = button(ui, title, func(): scroll.scroll_vertical = int(section.position.y), false, Vector2(206, 42))
  link.name = "HelpLink_" + str(section_index)
  links.add_child(link)
  section_index += 1
 body.add_child(panes)
 body.add_child(ui.settings_view_component._shortcut_strip(ui))

static func _route_color(route: String) -> Color:
 match route:
  "fury": return RED
  "venom": return Color("3e7755")
  "bastion": return BLUE
  _: return Color("957035")
