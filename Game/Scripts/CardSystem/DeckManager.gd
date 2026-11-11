extends RefCounted
## Two persistent owned-card zones. Dragging transfers a specific copy, never deletes it.
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
const NameButton = preload("res://Game/Scenes/Card/CardNameButton.gd")
const ART = preload("res://Game/Scenes/UI/AdventureUI.gd")
var ui: Control
var revision = 0
var scrolls: Dictionary = {}
var offsets = {"deck":0, "reserve":0}

func show_screen(host: Control, notice: String = "", keep_scroll: bool = false) -> void:
 ui = host
 revision += 1
 if not keep_scroll: offsets = {"deck":0, "reserve":0}
 scrolls.clear()
 var s: Dictionary = ui.game.s
 var body = ART.begin(ui, "卡组管理", Vector2(1280, 800))
 var editable: bool = ui.game.can_edit_deck()
 var instruction = "悬停卡名查看详情；拖动或点击换牌。出战 15–30 张；备用卡不参与抽牌。"
 if ui.game.can_retry_battle(): instruction += "\n调整完成后关闭此窗口，点击重新开始本小关；将按新卡组重新抽牌。"
 if not editable: instruction = "悬停卡名查看详情。战斗期间仅查看；战后选牌、遗物或营火阶段可以调整。"
 var intro = ui.row(16)
 intro.add_child(ui.paragraph(instruction, 17, ART.PAPER))
 intro.add_child(ART.badge(ui, "已拥有 %d 张  ·  %s" % [s.deck.size() + s.reserve.size(), "可以调整" if editable else "仅查看"], editable))
 body.add_child(intro)
 if notice != "": body.add_child(ui.paragraph(notice, 16, ART.GOLD_LIGHT))
 var panes = ui.row(18)
 panes.size_flags_vertical = Control.SIZE_EXPAND_FILL
 for zone in ["deck", "reserve"]:
  var frame = ART.paper(ui, 16)
  frame.name = "DeckZone" if zone == "deck" else "ReserveZone"
  frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  frame.custom_minimum_size.x = 590
  var content = ui.column(10)
  content.mouse_filter = Control.MOUSE_FILTER_PASS
  frame.add_child(content)
  var title = "出战卡组  %d / 30" % s.deck.size() if zone == "deck" else "备用卡库  %d 张" % s.reserve.size()
  content.add_child(ART.heading(ui, title))
  content.add_child(ART.note(ui, "只从这里的卡牌组成每场战斗的抽牌堆。" if zone == "deck" else "拖到这里保留卡牌；换入出战卡组后才能使用。", 15))
  content.add_child(ART.divider(ui))
  var scroll = ScrollContainer.new()
  scroll.name = "DeckScroll" if zone == "deck" else "ReserveScroll"
  scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
  scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
  scroll.custom_minimum_size.y = 370
  ART.scroll_skin(ui, scroll)
  scrolls[zone] = scroll
  var grid = GridContainer.new()
  grid.columns = 3
  grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  grid.add_theme_constant_override("h_separation", 8)
  grid.add_theme_constant_override("v_separation", 3)
  grid.mouse_filter = Control.MOUSE_FILTER_PASS
  for i in range(s[zone].size()):
   var id: String = s[zone][i]
   var tile = NameButton.new()
   tile.host = ui
   tile.card_id = id
   tile.text = Data.card(id).name
   tile.tooltip_text = Data.describe(Data.card(id))
   tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
   tile.focus_mode = Control.FOCUS_NONE
   tile.add_theme_font_size_override("font_size", 18)
   var definition: Dictionary = Data.card(id)
   ART.name_button(ui, tile, definition.route, definition.upgraded)
   tile.pressed.connect(ui.settings.play_click)
   tile.pressed.connect(func(): inspect_card(zone, i))
   tile.name = ("DeckCard" if zone == "deck" else "ReserveCard") + str(i)
   tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   tile.custom_minimum_size = Vector2(160, 40)
   tile.set_drag_forwarding(
    func(_pos): return drag_card(tile, zone, i, id),
    func(_pos, data): return accepts(data, zone),
    func(_pos, data): drop_card(data, zone))
   grid.add_child(tile)
  if s[zone].is_empty():
   var empty = ART.note(ui, "备用卡库为空。\n\n出战满 30 张后，新卡会自动放在这里。\n也可以将出战卡拖到这里暂存。", 18)
   empty.custom_minimum_size = Vector2(510, 250)
   grid.add_child(empty)
  scroll.add_child(grid)
  content.add_child(scroll)
  for target in [frame, content, scroll, grid]:
   target.set_drag_forwarding(Callable(), func(_pos, data): return accepts(data, zone), func(_pos, data): drop_card(data, zone))
  panes.add_child(frame)
  scroll.set_deferred("scroll_vertical", offsets[zone])
 body.add_child(panes)
 var footer = ui.row(14)
 footer.add_child(ui.paragraph("换牌免费且即时保存；重复卡分别计数，升级状态随卡保留。\n满编时先拖出一张，再拖入新卡。", 15, ART.PAPER))
 var done = ART.button(ui, "完成整理", ui.close_modal, true, Vector2(216, 56))
 done.name = "FinishDeckManagement"
 footer.add_child(done)
 body.add_child(footer)

func remember_scroll() -> void:
 for zone in scrolls:
  if is_instance_valid(scrolls[zone]): offsets[zone] = scrolls[zone].scroll_vertical

func drag_card(tile: Control, zone: String, index: int, id: String) -> Variant:
 if not ui.game.can_edit_deck(): return null
 var destination = "reserve" if zone == "deck" else "deck"
 if not ui.game.can_move_card(zone, index, destination): return null
 var preview = ART.paper(ui, 14, true)
 preview.add_child(ui.label(Data.card(id).name + "  →  " + ("备用卡库" if destination == "reserve" else "出战卡组"), 20, ART.WOOD))
 tile.set_drag_preview(preview)
 return {"kind":"owned_card", "revision":revision, "source":zone, "index":index, "id":id}

func accepts(data: Variant, destination: String) -> bool:
 if not data is Dictionary or data.get("kind", "") != "owned_card" or data.get("revision", -1) != revision: return false
 var source: String = data.get("source", "")
 var index: int = data.get("index", -1)
 if not ui.game.can_move_card(source, index, destination): return false
 return ui.game.s[source][index] == data.get("id", "")

func drop_card(data: Variant, destination: String) -> void:
 if not accepts(data, destination): return
 # Rebuild only after Godot has finished processing the drop event.
 call_deferred("transfer", data.source, int(data.index), destination, revision)

func transfer(source: String, index: int, destination: String, expected_revision: int) -> void:
 if expected_revision != revision or not is_instance_valid(ui.modal): return
 var title: String = Data.card(ui.game.s[source][index]).name
 remember_scroll()
 if ui.game.move_card(source, index, destination):
  ui.message = "%s已移入%s。" % [title, "出战卡组" if destination == "deck" else "备用卡库"]
  ui.commit()
  show_screen(ui, ui.message, true)

func inspect_card(source: String, index: int) -> void:
 remember_scroll()
 var id: String = ui.game.s[source][index]
 var c = Data.card(id)
 var body = ART.begin(ui, "卡牌详情", Vector2(800, 570))
 var paper = ART.paper(ui)
 paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_child(paper)
 var details = ui.column(14)
 paper.add_child(details)
 details.add_child(ART.heading(ui, c.name, 29))
 details.add_child(ART.note(ui, "%s  ·  %s 能量" % [c.kind, Data.cost_text(c)], 18))
 details.add_child(ART.divider(ui))
 details.add_child(ui.paragraph(Data.describe(c), 20, ART.WOOD))
 var destination = "reserve" if source == "deck" else "deck"
 if ui.game.can_edit_deck():
  var move_button = ART.button(ui, "移入备用卡库" if destination == "reserve" else "加入出战卡组", func(): transfer(source, index, destination, revision), true)
  move_button.disabled = not ui.game.can_move_card(source, index, destination)
  body.add_child(move_button)
  if move_button.disabled: body.add_child(ui.paragraph("出战卡组最多 30 张、至少 15 张，请先调整其他卡牌。", 16, ART.PAPER))
 body.add_child(ART.button(ui, "返回卡组管理", func(): show_screen(ui, "", true)))
