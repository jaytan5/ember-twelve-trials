extends Control
## 手牌仅管理表现；所有出牌仍通过 GameShell 的单次事务结算。
const CARD_SIZE = Vector2(190, 286)
const HOVER_SCALE = 1.2
const AVAILABILITY_SHADER = preload("res://Game/Scenes/Battle/HandAvailability.gdshader")
const ART_WINDOW_SHADER = preload("res://Game/Scenes/Card/CardArtWindow.gdshader")
var ui: Control
var cards: Control
var slots: Array[Dictionary] = []
var hovered = -1
var dragging = -1
var pointer = Vector2.ZERO
var grab_offset = Vector2.ZERO
var tweens: Dictionary = {}
var placeholder: Panel
var target_line: Line2D
var target_overlays: Dictionary = {}
var field_overlay: Panel
var transitioning = false
var arranging = false
var ready_for_input = false
var has_pointer = false

func setup(host: Control) -> void:
 ui = host
 name = "HandScroll"
 custom_minimum_size = Vector2(0, 304)
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 size_flags_vertical = Control.SIZE_EXPAND_FILL
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 clip_contents = false
 cards = Control.new()
 cards.name = "HandCards"
 cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
 cards.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(cards)
 if ui.game.s.hand.is_empty():
  var empty: Label = ui.label("手牌已用尽，可以结束回合。", 20, ui.MUTED)
  empty.position = Vector2(24, 130)
  add_child(empty)
 for i in range(ui.game.s.hand.size()):
  var card: Button = ui.card_view(ui.game.s.hand[i], func(): pass, str((i + 1) % 10))
  card.name = "HandCard%d" % i
  card.custom_minimum_size = CARD_SIZE
  card.size = CARD_SIZE
  passive(card)
  card.tooltip_text = ""
  cards.add_child(card)
  card.pivot_offset = CARD_SIZE * 0.5
  card.set_meta("hand_id", ui.game.s.hand[i])
 placeholder = Panel.new()
 placeholder.name = "DragPlaceholder"
 placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
 placeholder.add_theme_stylebox_override("panel", ui.box(Color(0.12, 0.18, 0.25, 0.35), Color(0.9, 0.72, 0.45, 0.4), 12, 0))
 placeholder.size = CARD_SIZE
 placeholder.pivot_offset = CARD_SIZE * 0.5
 placeholder.hide()
 add_child(placeholder)
 target_line = Line2D.new()
 target_line.name = "TargetGuide"
 target_line.width = 3.0
 target_line.default_color = Color(1.0, 0.82, 0.48, 0.7)
 target_line.antialiased = true
 target_line.z_index = 59
 add_child(target_line)
 resized.connect(func(): if ready_for_input: arrange(true))
 call_deferred("initialize_layout")

func passive(node: Node) -> void:
 if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for child in node.get_children(): passive(child)

func initialize_layout() -> void:
 if not is_inside_tree(): return
 arrange(false)
 ready_for_input = true
 update_availability()

func arrange(animated: bool) -> void:
 if arranging: return
 arranging = true
 slots.clear()
 var count = cards.get_child_count()
 var center = clampf(ui.size.x * 0.5 - global_position.x, CARD_SIZE.x * 0.6, size.x - CARD_SIZE.x * 0.6)
 var usable = minf(maxf(0, (minf(center, size.x - center) - CARD_SIZE.x * 0.5 - 40) * 2), 1000.0)
 var step = minf(CARD_SIZE.x + 12, usable / maxf(1.0, count - 1))
 for i in range(count):
  var card: Control = cards.get_child(i)
  card.size = Vector2(CARD_SIZE.x, maxf(CARD_SIZE.y, card.get_combined_minimum_size().y))
  card.pivot_offset = card.size * 0.5
  var unit = (i - (count - 1) * 0.5) / maxf(1.0, (count - 1) * 0.5)
  slots.append({"position":Vector2(center + (i - (count - 1) * 0.5) * step - card.size.x * 0.5, size.y - card.size.y - 34 + unit * unit * 22), "rotation":deg_to_rad(unit * minf(13, (count - 1) * 2.4))})
  if i != dragging: pose(i, animated)
 arranging = false

func pose(index: int, animated: bool = true) -> void:
 var card: Control = cards.get_child(index)
 var destination: Vector2 = slots[index].position
 var angle: float = slots[index].rotation
 var zoom = Vector2.ONE
 card.z_index = index + 1
 if index == hovered and dragging < 0:
  destination.y -= card.size.y * 0.25
  angle = 0
  zoom *= HOVER_SCALE
  card.z_index = 50
 elif hovered >= 0 and dragging < 0:
  var distance = absi(index - hovered)
  if distance <= 2: destination.x += signi(index - hovered) * (28.0 if distance == 1 else 10.0)
 if tweens.has(index): tweens[index].kill()
 if not animated:
  card.position = destination
  card.rotation = angle
  card.scale = zoom
  return
 var tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 tween.tween_property(card, "position", destination, 0.2)
 tween.tween_property(card, "rotation", angle, 0.2)
 tween.tween_property(card, "scale", zoom, 0.2)
 tweens[index] = tween

func enabled() -> bool:
 return ready_for_input and not transitioning and not ui.busy and not is_instance_valid(ui.modal) and ui.screen == "run" and ui.game.s.get("phase") == "battle"

func hit_card(point: Vector2) -> int:
 # 放大卡片优先命中，避免点击其可见牌面却选中下面的邻牌。
 if hovered >= 0:
  var card: Control = cards.get_child(hovered)
  if Rect2(Vector2.ZERO, card.size).has_point(card.get_global_transform_with_canvas().affine_inverse() * point): return hovered
 # 固定槽位为回弹和悬停提供稳定入口，避免动画移动导致反复切换。
 for i in range(slots.size() - 1, -1, -1):
  var local = point - global_position - slots[i].position - CARD_SIZE * 0.5
  local = local.rotated(-slots[i].rotation) + CARD_SIZE * 0.5
  if Rect2(Vector2.ZERO, CARD_SIZE).has_point(local): return i
 return -1

func set_hover(index: int) -> void:
 if hovered == index: return
 hovered = index
 for i in range(slots.size()): pose(i)

func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion or event is InputEventMouseButton:
  pointer = event.position
  has_pointer = true
 if not enabled():
  if dragging >= 0: cancel_drag()
  elif hovered >= 0: set_hover(-1)
  return
 if event is InputEventKey and dragging >= 0:
  if event.pressed and event.keycode == KEY_ESCAPE: cancel_drag()
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion:
  pointer = event.position
  if dragging >= 0:
   move_drag()
   get_viewport().set_input_as_handled()
  else: set_hover(hit_card(pointer))
 elif event is InputEventMouseButton:
  pointer = event.position
  if event.button_index == MOUSE_BUTTON_RIGHT and dragging >= 0:
   cancel_drag()
   get_viewport().set_input_as_handled()
  elif event.button_index == MOUSE_BUTTON_LEFT:
   if event.pressed:
    var index = hit_card(pointer)
    if index >= 0:
     begin_drag(index)
     get_viewport().set_input_as_handled()
   elif dragging >= 0:
    finish_drag()
    get_viewport().set_input_as_handled()

func begin_drag(index: int) -> void:
 dragging = index
 hovered = -1
 var card: Control = cards.get_child(index)
 if tweens.has(index): tweens[index].kill()
 grab_offset = Vector2(0, -card.size.y * 0.16)
 card.rotation = 0
 card.scale = Vector2.ONE * HOVER_SCALE
 card.z_index = 60
 placeholder.position = slots[index].position
 placeholder.rotation = slots[index].rotation
 placeholder.size = card.size
 placeholder.show()
 for i in range(slots.size()):
  if i != index: pose(i)
 move_drag()

func move_drag() -> void:
 var card: Control = cards.get_child(dragging)
 var center = pointer + grab_offset
 center.x = clampf(center.x, card.size.x * 0.6, ui.size.x - card.size.x * 0.6)
 center.y = clampf(center.y, card.size.y * 0.6, ui.size.y - card.size.y * 0.6)
 card.position = center - global_position - card.size * 0.5
 update_targets()

func legal_target(index: int, target: int) -> bool:
 return ui.game.can_play_on(index, target)

func drop_target(index: int, point: Vector2) -> int:
 for target in range(ui.game.s.enemies.size()):
  var enemy: Control = ui.find_child("EnemyPanel%d" % target, true, false)
  if is_instance_valid(enemy) and enemy.get_global_rect().has_point(point) and legal_target(index, target): return target
 return -1

func valid_drop(index: int, point: Vector2) -> bool:
 var data: Dictionary = ui.Data.card(ui.game.s.hand[index])
 if data.get("target", false): return drop_target(index, point) >= 0
 var field: Control = ui.find_child("Battlefield", true, false)
 return ui.game.can_play(index) and is_instance_valid(field) and field.get_global_rect().has_point(point)

func overlay_for(control: Control) -> Panel:
 var overlay = Panel.new()
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var style = ui.box(Color(1.0, 0.8, 0.35, 0.04), ui.GOLD, 12, 0)
 style.set_border_width_all(3)
 style.shadow_color = Color(1.0, 0.7, 0.2, 0.22)
 style.shadow_size = 10
 overlay.add_theme_stylebox_override("panel", style)
 control.add_child(overlay)
 return overlay

func update_targets() -> void:
 clear_targets()
 var data: Dictionary = ui.Data.card(ui.game.s.hand[dragging])
 if data.get("target", false):
  for target in range(ui.game.s.enemies.size()):
   if legal_target(dragging, target):
    var enemy: Control = ui.find_child("EnemyPanel%d" % target, true, false)
    target_overlays[target] = overlay_for(enemy)
  var target = drop_target(dragging, pointer)
  if target >= 0:
   var enemy: Control = ui.find_child("EnemyPanel%d" % target, true, false)
   var card: Control = cards.get_child(dragging)
   var start = card.get_global_transform() * Vector2(card.size.x, card.size.y * 0.5) - global_position
   var end = enemy.get_global_rect().get_center() - global_position
   var points = PackedVector2Array()
   var bend = Vector2(maxf(start.x, end.x) + 100, minf(start.y, end.y) - 70)
   for i in range(25):
    var t = i / 24.0
    points.append((1-t)*(1-t)*start + 2*(1-t)*t*bend + t*t*end)
   target_line.points = points
 else:
  var field: Control = ui.find_child("Battlefield", true, false)
  if ui.game.can_play(dragging): field_overlay = overlay_for(field)

func clear_targets() -> void:
 target_line.clear_points()
 for overlay in target_overlays.values():
  if is_instance_valid(overlay): overlay.free()
 target_overlays.clear()
 if is_instance_valid(field_overlay): field_overlay.free()

func cancel_drag() -> void:
 var previous = dragging
 dragging = -1
 hovered = -1
 placeholder.hide()
 clear_targets()
 for i in range(slots.size()): pose(i)
 if previous >= 0: feedback("已取消出牌。")

func feedback(value: String) -> void:
 ui.message = value
 var caption: Label = ui.find_child("StatusMessage", true, false)
 if is_instance_valid(caption): caption.text = value

func finish_drag() -> void:
 var index = dragging
 var legal = valid_drop(index, pointer)
 var target = drop_target(index, pointer) if ui.Data.card(ui.game.s.hand[index]).get("target", false) else -1
 if not legal:
  cancel_drag()
  feedback("能量不足，卡牌已返回手牌。" if ui.game.s.energy < ui.game.energy_cost(ui.Data.card(ui.game.s.hand[index])) else "落点或目标不合法，卡牌已返回手牌。")
  return
 dragging = -1
 placeholder.hide()
 clear_targets()
 ui.settings.play_click()
 ui.play_card(index, target)

func update_availability() -> void:
 for i in range(cards.get_child_count()):
  var data: Dictionary = ui.Data.card(ui.game.s.hand[i])
  var affordable: bool = ui.game.s.energy >= ui.game.energy_cost(data)
  var card: Control = cards.get_child(i)
  card.modulate = Color.WHITE if affordable else Color(0.57, 0.57, 0.6)
  var saturation = 1.0 if affordable else 0.35
  var material_value = ShaderMaterial.new()
  material_value.shader = AVAILABILITY_SHADER
  material_value.set_shader_parameter("saturation", saturation)
  card.material = material_value
  card.use_parent_material = false
  inherit_material(card, saturation)

func inherit_material(node: Node, saturation: float) -> void:
 for child in node.get_children():
  if child is CanvasItem:
   # The illustration keeps its rounded-window mask and applies the same desaturation itself.
   if child.material is ShaderMaterial and child.material.shader == ART_WINDOW_SHADER:
    child.material.set_shader_parameter("saturation", saturation)
   else:
    child.use_parent_material = true
  inherit_material(child, saturation)

func snapshot(excluding: int = -1) -> Array:
 var result: Array = []
 for i in range(cards.get_child_count()):
  if i == excluding: continue
  var card: Control = cards.get_child(i)
  result.append({"id":card.get_meta("hand_id"), "position":card.global_position, "rotation":card.rotation, "scale":card.scale})
 return result

func animate_entry(previous: Array) -> void:
 transitioning = true
 await get_tree().process_frame
 if not is_inside_tree(): return
 initialize_layout()
 var pile: Control = ui.find_child("DrawPile", true, false)
 var from = pile.get_global_rect().get_center() - global_position if is_instance_valid(pile) else Vector2(size.x, 0)
 for i in range(cards.get_child_count()):
  var card: Control = cards.get_child(i)
  if i < previous.size() and previous[i].id == card.get_meta("hand_id"):
   card.position = previous[i].position - global_position
   card.rotation = previous[i].rotation
   card.scale = previous[i].scale
  else:
   card.position = from - card.size * 0.5
   card.scale = Vector2.ONE * 0.3
   card.rotation = -0.25
  pose(i)
 await get_tree().create_timer(0.23).timeout
 transitioning = false
 if enabled() and has_pointer: set_hover(hit_card(pointer))

func fly_out(index: int) -> void:
 transitioning = true
 hovered = -1
 var card: Control = cards.get_child(index)
 if tweens.has(index): tweens[index].kill()
 card.z_index = 60
 var tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
 tween.tween_property(card, "position", card.position + Vector2(0, -110), ui.battle_animator.duration(0.18))
 tween.tween_property(card, "modulate:a", 0.0, ui.battle_animator.duration(0.18))
 tween.tween_property(card, "scale", Vector2.ONE * 0.8, ui.battle_animator.duration(0.18))
 await tween.finished

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and dragging >= 0: cancel_drag()
