extends Control
## 在 1024×1536 原画布上排版，整张卡等比缩放，外壳与插图独立叠放。
const Art = preload("res://Game/Scripts/CardSystem/CardArtCatalog.gd")
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
const BODY_FONT = preload("res://Game/Assets/Fonts/MiSans-Regular.ttf")
const TITLE_FONT = preload("res://Game/Assets/Fonts/方圆体-标题.tres")
const INK = Color("412a20")
var design: Control
var description: Label
var card_id: String

func setup(id: String, hint: String, locked: bool) -> void:
 card_id = id
 name = "CardArtwork"
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var c = Data.card(id)
 design = Control.new()
 design.name = "CardDesign"
 design.size = Vector2(1024, 1536)
 design.mouse_filter = Control.MOUSE_FILTER_IGNORE
 design.modulate = Color(0.73, 0.73, 0.73, 0.8) if locked else Color.WHITE
 add_child(design)
 var art = TextureRect.new()
 art.name = "CardIllustration"
 art.texture = Art.illustration(id)
 art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 art.position = Vector2(114, 340)
 art.size = Vector2(796, 454)
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var mask = ShaderMaterial.new()
 mask.shader = preload("res://Game/Scenes/Card/CardArtWindow.gdshader")
 art.material = mask
 design.add_child(art)
 var shell = TextureRect.new()
 shell.name = "CardShell"
 shell.texture = Art.shell(id)
 shell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 shell.size = design.size
 shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
 design.add_child(shell)
 var cost = text("CardCost", Data.cost_text(c), Rect2(120, 121, 166, 164), 132, Color("fff5dc"), TITLE_FONT)
 cost.add_theme_color_override("font_outline_color", Color("16506a"))
 cost.add_theme_constant_override("outline_size", 13)
 text("CardTitle", c.name, Rect2(348, 135, 390, 125), 75 if c.upgraded else 83, Color("9e3528") if c.upgraded else INK, TITLE_FONT)
 var metadata = c.kind + " · " + ("通用" if c.route == "neutral" else Data.ROUTES[c.route].name)
 text("CardKind", metadata, Rect2(150, 849, 724, 66), 50, Color("866345"))
 description = text("CardDescription", Data.describe(c, true), Rect2(153, 930, 718, 349), 72, INK)
 description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
 description.add_theme_constant_override("line_spacing", 0)
 var font_size = 72
 var paragraph = TextParagraph.new()
 paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
 while font_size >= 38:
  paragraph.clear()
  paragraph.width = 718
  paragraph.add_string(description.text, BODY_FONT, font_size)
  if paragraph.get_size().y <= 349: break
  font_size -= 2
 description.add_theme_font_size_override("font_size", font_size)
 var footer = hint
 if footer.is_empty(): footer = "已升级" if c.upgraded else ("随机敌人" if c.has("random_damage") else ("单体目标" if c.get("target", false) else "自身 / 全体"))
 text("CardHint", footer, Rect2(180, 1370, 664, 80), 54, Color("ffedc8"), TITLE_FONT)
 resized.connect(fit)
 fit()

func text(node_name: String, value: String, bounds: Rect2, font_size: int, color: Color, font: Font = BODY_FONT) -> Label:
 var label = Label.new()
 label.name = node_name
 label.text = value
 label.position = bounds.position
 label.size = bounds.size
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.add_theme_font_override("font", font)
 label.add_theme_font_size_override("font_size", font_size)
 label.add_theme_color_override("font_color", color)
 design.add_child(label)
 return label

func fit() -> void:
 if not is_instance_valid(design): return
 var ratio = minf(size.x / 1024.0, size.y / 1536.0)
 design.scale = Vector2.ONE * ratio
 design.position = (size - design.size * ratio) * 0.5
