extends RefCounted
## Two persistent owned-card zones. Dragging transfers a specific copy, never deletes it.
const Data = preload("res://scripts/data.gd")
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
 var body = ui.open_modal("卡组管理  /  已拥有 %d 张" % (s.deck.size() + s.reserve.size()), Vector2(1280, 810))
 var editable: bool = ui.game.can_edit_deck()
 var instruction = "拖动卡牌到另一侧即可换牌，也可点击卡牌操作。出战 5–30 张；备用卡不会参与抽牌。"
 if not editable: instruction = "战斗与结算期间仅查看；在战后选牌、遗物或营火阶段可以拖动调整。"
 body.add_child(ui.paragraph(instruction, 17))
 if notice != "": body.add_child(ui.paragraph(notice, 16, ui.GOLD))
 var panes = ui.row(18)
 panes.size_flags_vertical = Control.SIZE_EXPAND_FILL
 for zone in ["deck", "reserve"]:
  var frame = ui.panel(ui.PANEL_LIGHT, ui.GREEN if zone == "deck" else ui.GOLD, 16)
  frame.name = "DeckZone" if zone == "deck" else "ReserveZone"
  frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  frame.custom_minimum_size.x = 590
  var content = ui.column(10)
  content.mouse_filter = Control.MOUSE_FILTER_PASS
  frame.add_child(content)
  var title = "出战卡组  %d / 30" % s.deck.size() if zone == "deck" else "备用卡库  %d 张" % s.reserve.size()
  content.add_child(ui.label(title, 25, ui.GREEN if zone == "deck" else ui.GOLD))
  content.add_child(ui.paragraph("只从这里的卡牌组成每场战斗的抽牌堆。" if zone == "deck" else "拖到这里保留卡牌；换入出战卡组后才能使用。", 14))
  var scroll = ScrollContainer.new()
  scroll.name = "DeckScroll" if zone == "deck" else "ReserveScroll"
  scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
  scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
  scroll.custom_minimum_size.y = 490
  scrolls[zone] = scroll
  var grid = GridContainer.new()
  grid.columns = 2
  grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  grid.add_theme_constant_override("h_separation", 12)
  grid.add_theme_constant_override("v_separation", 12)
  grid.mouse_filter = Control.MOUSE_FILTER_PASS
  for i in range(s[zone].size()):
   var id: String = s[zone][i]
   var tile: Button = ui.card_view(id, func(): inspect_card(zone, i), "拖动换牌" if editable else "只读")
   tile.name = ("DeckCard" if zone == "deck" else "ReserveCard") + str(i)
   tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   tile.custom_minimum_size = Vector2(250, 250)
   tile.set_drag_forwarding(
    func(_pos): return drag_card(tile, zone, i, id),
    func(_pos, data): return accepts(data, zone),
    func(_pos, data): drop_card(data, zone))
   grid.add_child(tile)
  if s[zone].is_empty():
   var empty = ui.paragraph("备用卡库为空。\n\n出战满 30 张后，新卡会自动放在这里。\n也可以将出战卡拖到这里暂存。", 18)
   empty.custom_minimum_size = Vector2(510, 330)
   grid.add_child(empty)
  scroll.add_child(grid)
  content.add_child(scroll)
  for target in [frame, content, scroll, grid]:
   target.set_drag_forwarding(Callable(), func(_pos, data): return accepts(data, zone), func(_pos, data): drop_card(data, zone))
  panes.add_child(frame)
  scroll.set_deferred("scroll_vertical", offsets[zone])
 body.add_child(panes)
 body.add_child(ui.paragraph("换牌免费且即时保存；重复卡按独立张数计算，升级状态随卡牌保留。满编时先拖出一张，再拖入新卡。", 15))

func remember_scroll() -> void:
 for zone in scrolls:
  if is_instance_valid(scrolls[zone]): offsets[zone] = scrolls[zone].scroll_vertical

func drag_card(tile: Control, zone: String, index: int, id: String) -> Variant:
 if not ui.game.can_edit_deck(): return null
 var destination = "reserve" if zone == "deck" else "deck"
 if not ui.game.can_move_card(zone, index, destination): return null
 var preview = ui.panel(ui.PANEL_LIGHT, ui.GOLD, 18)
 preview.add_child(ui.label(Data.card(id).name + "  →  " + ("备用卡库" if destination == "reserve" else "出战卡组"), 20, ui.GOLD))
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
 var body = ui.open_modal(c.name, Vector2(720, 550))
 body.add_child(ui.paragraph("%s · %d 能量\n\n%s" % [c.kind, c.cost, Data.describe(c)], 20, ui.TEXT))
 var destination = "reserve" if source == "deck" else "deck"
 if ui.game.can_edit_deck():
  var move_button = ui.button("移入备用卡库" if destination == "reserve" else "加入出战卡组", func(): transfer(source, index, destination, revision), true)
  move_button.disabled = not ui.game.can_move_card(source, index, destination)
  body.add_child(move_button)
  if move_button.disabled: body.add_child(ui.paragraph("出战卡组最多 30 张、至少 5 张，请先调整其他卡牌。", 16))
 body.add_child(ui.button("返回卡组管理", func(): show_screen(ui, "", true)))
