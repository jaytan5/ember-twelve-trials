extends Node
## Play individual hits on the current scene before publishing the prepared result.
signal event_started(event: Dictionary)
signal event_finished(event: Dictionary)
var speed_scale = 1.0

static func impact_tier(target: int, damage: int) -> int:
 if damage <= 0: return 0
 var small_limit = 15 if target < 0 else 20
 var large_limit = 40 if target < 0 else 50
 return 1 if damage < small_limit else (2 if damage <= large_limit else 3)

func duration(seconds: float) -> float:
 return seconds / maxf(0.01, speed_scale)

func play_events(ui: Control, events: Array, card_index: int = -1) -> void:
 if card_index >= 0:
  var hand = ui.find_child("HandCards", true, false)
  if is_instance_valid(hand) and card_index < hand.get_child_count():
   var card: Control = hand.get_child(card_index)
   var origin = card.position
   var cue = create_tween()
   cue.tween_property(card, "position", origin + Vector2(0, -7), duration(0.06))
   cue.parallel().tween_property(card, "modulate", Color(1.35, 1.22, 1.05), duration(0.06))
   cue.tween_property(card, "position", origin, duration(0.05))
   cue.parallel().tween_property(card, "modulate", Color.WHITE, duration(0.05))
   await cue.finished
 for event in events:
  await play_event(ui, event)

func play_event(ui: Control, event: Dictionary) -> void:
 var target: int = event.target
 var panel: Control = ui.find_child("HeroPanel" if target < 0 else "EnemyPanel%d" % target, true, false)
 if not is_instance_valid(panel): return
 var health: Control = ui.find_child("HeroHealth" if target < 0 else "EnemyHealth%d" % target, true, false)
 var tier = impact_tier(target, event.amount) if event.kind == "damage" else 0
 event_started.emit(event)
 var origin = panel.position
 var original_tint = panel.modulate
 var impact = create_tween()
 if tier > 0:
  var amplitude: float = [0.0, 3.0, 7.0, 12.0][tier]
  var step_time = duration(0.025 + tier * 0.008)
  for offset in [Vector2(-1, 0.25), Vector2(1, -0.2), Vector2(-0.55, 0.1), Vector2(0.35, 0), Vector2.ZERO]:
   impact.tween_property(panel, "position", origin + offset * amplitude, step_time)
  impact.parallel().tween_property(panel, "modulate", original_tint, step_time)
  panel.modulate = Color(1.4, 0.65, 0.65)
 else:
  var pulse = Color(0.7, 1.4, 0.95) if event.kind == "heal" else Color(0.75, 1.05, 1.4)
  impact.tween_property(panel, "modulate", pulse, duration(0.05))
  impact.tween_property(panel, "modulate", original_tint, duration(0.07))
 await impact.finished
 if not is_instance_valid(panel): return
 panel.position = origin
 panel.modulate = original_tint
 if event.before != event.after and is_instance_valid(health):
  var fill: ProgressBar = health.get_node("HealthFill")
  var caption: Label = health.get_node("HealthCaption")
  fill.value = event.before
  var change = create_tween()
  change.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  change.tween_method(func(value: float):
   fill.value = value
   caption.text = "%d / %d" % [roundi(value), int(fill.max_value)], float(event.before), float(event.after), duration(0.18))
  await change.finished
  if event.after <= 0 and target >= 0: panel.modulate = Color(0.55, 0.55, 0.55)
 event_finished.emit(event)
