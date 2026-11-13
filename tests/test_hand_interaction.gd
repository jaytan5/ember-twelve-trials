extends SceneTree
const Main = preload("res://main.tscn")
var ui
var errors = 0
var checks = 0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  errors += 1
  printerr("FAIL: ", title)

func settle() -> void:
 await create_timer(0.28).timeout
 var hand = ui.find_child("HandScroll", true, false) if is_instance_valid(ui) else null
 while is_instance_valid(hand) and hand.transitioning: await process_frame

func setup(ids: Array, energy: int = 10) -> Control:
 ui.game.new_run("venom", 831)
 ui.game.s.hand = ids.duplicate()
 ui.game.s.energy = energy
 ui.game.s.enemies = [ui.Data.enemy("合法目标", 1000, [ui.Data.defend(0)]), ui.Data.enemy("中毒目标", 1000, [ui.Data.defend(0)]), ui.Data.enemy("已倒下目标", 1000, [ui.Data.defend(0)])]
 ui.game.s.enemies[1].poison = 12
 ui.game.s.enemies[2].hp = 0
 ui.screen = "run"
 ui.render()
 await settle()
 return ui.find_child("HandScroll", true, false)

func motion(point: Vector2) -> void:
 var event = InputEventMouseMotion.new()
 event.position = point
 event.global_position = point
 root.push_input(event)

func mouse(point: Vector2, pressed: bool, button: int = MOUSE_BUTTON_LEFT) -> void:
 var event = InputEventMouseButton.new()
 event.position = point
 event.global_position = point
 event.button_index = button
 event.pressed = pressed
 root.push_input(event)

func point_for(hand: Control, index: int) -> Vector2:
 # 从真实可见槽位查找每张重叠卡牌的入口。
 for y in range(0, int(hand.size.y), 4):
  for x in range(0, int(hand.size.x), 4):
   var point = hand.global_position + Vector2(x, y)
   if hand.hit_card(point) == index: return point
 return Vector2(-1000, -1000)

func capture(label_value: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://test-results/hand-" + label_value + ".png")

func drag(hand: Control, index: int, destination: Vector2) -> void:
 var point = point_for(hand, index)
 motion(point)
 mouse(point, true)
 motion(destination)

func run() -> void:
 root.size = Vector2i(1600, 900)
 ui = Main.instantiate()
 root.add_child(ui)
 await process_frame
 ui.battle_animator.speed_scale = 5.0
 var hand = await setup(["strike", "guard", "sting", "detonate", "quick"])
 check(hand.cards.get_child_count() == 5, "five cards in free-layout hand")
 check(hand.slots[0].rotation < 0 and hand.slots[2].rotation == 0 and hand.slots[4].rotation > 0, "fan angles face outward")
 var left: Vector2 = hand.slots[0].position
 var right: Vector2 = hand.slots[-1].position
 check(absf((left.x + right.x + hand.CARD_SIZE.x) * 0.5 + hand.global_position.x - ui.size.x * 0.5) < 1, "hand centered on screen")
 await capture("idle-five")
 var point = point_for(hand, 2)
 motion(point)
 await settle()
 var card: Control = hand.cards.get_child(2)
 check(hand.hovered == 2 and card.rotation == 0 and is_equal_approx(card.scale.x, 1.2) and card.z_index == 50, "real mouse hover lifts scales straightens and raises")
 check(absf(card.position.y - (hand.slots[2].position.y - card.size.y * 0.25)) < 1, "hover lifts by quarter card height")
 check(hand.cards.get_child(1).position.x < hand.slots[1].position.x and hand.cards.get_child(3).position.x > hand.slots[3].position.x, "neighbors yield space")
 await capture("hover")
 motion(Vector2(2, 2))
 await settle()
 check(card.position.distance_to(hand.slots[2].position) < 1 and card.scale == Vector2.ONE, "mouse exit smoothly restores slot")
 var before: Dictionary = ui.game.s.duplicate(true)
 var neighbor: Vector2 = hand.cards.get_child(1).position
 await drag(hand, 0, Vector2(15, 15))
 check(hand.dragging == 0 and hand.placeholder.visible and hand.cards.get_child(0).z_index == 60, "drag follows input with placeholder above other cards")
 check(hand.cards.get_child(1).position.distance_to(neighbor) < 1, "drag retains original hand spacing")
 check(hand.target_overlays.size() == 2 and not hand.target_overlays.has(2), "only living legal targets glow")
 mouse(Vector2(15, 15), false)
 await settle()
 check(ui.game.s == before and hand.dragging == -1 and not hand.placeholder.visible, "illegal drop preserves all state and returns")
 await drag(hand, 0, ui.find_child("EnemyPanel0", true, false).get_global_rect().get_center())
 check(hand.target_line.points.size() > 0, "soft curved target guide appears")
 await capture("targeted-drag")
 var key = InputEventKey.new()
 key.keycode = KEY_ESCAPE
 key.pressed = true
 root.push_input(key)
 await settle()
 check(hand.dragging == -1 and ui.game.s == before and ui.modal == null, "Escape cancels instead of opening menu or spending energy")
 await drag(hand, 0, Vector2(600, 280))
 mouse(Vector2(600, 280), true, MOUSE_BUTTON_RIGHT)
 await settle()
 check(ui.game.s == before and hand.dragging == -1, "right click cancels")
 var field: Control = ui.find_child("Battlefield", true, false)
 var empty_field = field.get_global_rect().position + Vector2(12, 12)
 await drag(hand, 0, empty_field)
 mouse(empty_field, false)
 await settle()
 check(ui.game.s == before, "single-target card rejects empty battlefield")
 var enemy_point = ui.find_child("EnemyPanel1", true, false).get_global_rect().get_center()
 await drag(hand, 0, enemy_point)
 mouse(enemy_point, false)
 check(ui.busy and ui.game.s == before, "release starts exactly one transaction before state commits")
 if ui.busy: await ui.combat_animation_finished
 check(ui.game.s.played == before.played + 1 and ui.game.s.energy == before.energy - 1 and ui.game.s.hand.size() == 4 and ui.game.s.enemies[1].hp < before.enemies[1].hp and ui.game.s.enemies[0].hp == before.enemies[0].hp, "success spends once removes once hits dropped enemy")
 hand = ui.find_child("HandScroll", true, false)
 check(hand.transitioning, "remaining hand uses animated transition")
 await settle()
 await capture("after-play")
 before = ui.game.s.duplicate(true)
 field = ui.find_child("Battlefield", true, false)
 empty_field = field.get_global_rect().position + Vector2(12, 12)
 await drag(hand, 0, empty_field)
 check(is_instance_valid(hand.field_overlay), "non-target card activates battlefield")
 mouse(empty_field, false)
 if ui.busy: await ui.combat_animation_finished
 check(ui.game.s.block > before.block and ui.game.s.hand.size() == before.hand.size() - 1, "self card plays on empty battlefield")
 await settle()
 hand = await setup(["guard"])
 enemy_point = ui.find_child("EnemyPanel1", true, false).get_global_rect().get_center()
 await drag(hand, 0, enemy_point)
 mouse(enemy_point, false)
 if ui.busy: await ui.combat_animation_finished
 check(ui.game.s.target == 0, "non-target card does not change locked enemy when dropped over another enemy")
 await settle()
 hand = await setup(["strike", "guard"], 0)
 card = hand.cards.get_child(0)
 check(card.modulate.r < 0.7 and card.material.get_shader_parameter("saturation") < 1.0, "unaffordable card dims and desaturates")
 var illustration: TextureRect = card.find_child("CardIllustration", true, false)
 check(not illustration.use_parent_material and illustration.material.get_shader_parameter("saturation") < 1.0, "hand illustration keeps its window mask and desaturates with the card")
 # Godot 4 already multiplies COLOR by the texture; sampling TEXTURE again squares the colors (too dark).
 for shader_path in ["res://Game/Scenes/Card/CardArtWindow.gdshader", "res://Game/Scenes/Battle/HandAvailability.gdshader"]:
  var code_lines: Array[String] = []
  for line in load(shader_path).code.split("\n"):
   if not line.strip_edges().begins_with("//"): code_lines.append(line)
  check(not "texture(TEXTURE" in "\n".join(code_lines), "card shader does not sample the texture twice: " + shader_path)
 before = ui.game.s.duplicate(true)
 enemy_point = ui.find_child("EnemyPanel0", true, false).get_global_rect().get_center()
 await drag(hand, 0, enemy_point)
 check(hand.target_overlays.is_empty() and hand.target_line.points.is_empty(), "unaffordable card activates no targets")
 mouse(enemy_point, false)
 await settle()
 check(ui.game.s == before, "insufficient energy never removes or spends")
 check("能量不足" in ui.find_child("StatusMessage", true, false).text, "insufficient energy explanation updates immediately")
 ui.game.s.energy = 3
 hand.update_availability()
 check(card.modulate == Color.WHITE and card.material.get_shader_parameter("saturation") == 1.0 and illustration.material.get_shader_parameter("saturation") == 1.0, "energy recovery restores appearance")
 await drag(hand, 0, enemy_point)
 ui.game.s.energy = 0
 before = ui.game.s.duplicate(true)
 mouse(enemy_point, false)
 await settle()
 check(ui.game.s == before, "release revalidates energy instead of trusting drag-start state")
 hand = await setup(["recycle", "strike"])
 before = ui.game.s.duplicate(true)
 await drag(hand, 0, Vector2(10, 10))
 check(not hand.target_overlays.has(0) and hand.target_overlays.has(1) and not hand.target_overlays.has(2), "poison prerequisite checks actual enemy without changing selected target")
 check(ui.game.s == before, "target preview is read-only")
 enemy_point = ui.find_child("EnemyPanel1", true, false).get_global_rect().get_center()
 motion(enemy_point)
 mouse(enemy_point, false)
 if ui.busy: await ui.combat_animation_finished
 check(ui.game.s.played == before.played + 1 and ui.game.s.enemies[1].poison == 8, "drop allows eligible enemy even if selected enemy is ineligible")
 await settle()
 hand = await setup(["guard", "guard", "guard", "guard", "guard", "guard", "guard", "guard", "guard", "guard"])
 for i in range(10):
  check(point_for(hand, i).x > 0, "ten-card hand clickable slot %d" % i)
 await capture("idle-ten")
 for i in range(10):
  motion(point_for(hand, i))
  await settle()
  check(hand.hovered == i, "each overlapping card is reachable after neighboring hover %d" % i)
  card = hand.cards.get_child(i)
  var visible_center: Vector2 = card.get_global_transform_with_canvas() * (card.size * 0.5)
  check(hand.hit_card(visible_center) == i, "visible enlarged card wins click over underlying neighbors %d" % i)
 motion(Vector2(1, 1))
 await settle()
 # New draw retains existing order and travels from deck to hand.
 hand = await setup(["insight", "guard"])
 before = ui.game.s.duplicate(true)
 field = ui.find_child("Battlefield", true, false)
 empty_field = field.get_global_rect().position + Vector2(12, 12)
 await drag(hand, 0, ui.find_child("EnemyPanel0", true, false).get_global_rect().get_center())
 mouse(ui.find_child("EnemyPanel0", true, false).get_global_rect().get_center(), false)
 if ui.busy: await ui.combat_animation_finished
 hand = ui.find_child("HandScroll", true, false)
 check(ui.game.s.hand.size() == 5 and ui.game.s.hand[0] == "guard", "draw effect appends new card after survivors")
 await process_frame
 check(hand.cards.get_child(1).scale.x < 1.0, "newly drawn card enters from pile at smaller size")
 await settle()
 for i in range(hand.cards.get_child_count()):
  check(hand.cards.get_child(i).position.distance_to(hand.slots[i].position) < 1, "entry finishes in final slot %d" % i)
 hand = await setup([])
 check(hand.cards.get_child_count() == 0 and hand.slots.is_empty(), "empty hand layout supported")
 hand = await setup(["guard"])
 check(hand.slots[0].rotation == 0, "single card upright")
 for dimensions in [Vector2i(1280, 720), Vector2i(1024, 768)]:
  root.size = dimensions
  await settle()
  check(absf(hand.global_position.x + hand.slots[0].position.x + hand.CARD_SIZE.x * 0.5 - ui.size.x * 0.5) < 1, "centered at window " + str(dimensions))
 await capture("scaled")
 print("HAND INTERACTION CHECKS: ", checks, " passed: ", checks-errors, " failed: ", errors)
 ui.queue_free()
 await process_frame
 quit(0 if errors == 0 else 1)
