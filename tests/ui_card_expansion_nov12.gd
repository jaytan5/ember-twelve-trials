extends SceneTree
const Main = preload("res://main.tscn")
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
var ui
var checks = 0
var failures = 0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  printerr("FAIL: ", title)

func settle() -> void:
 for _i in range(5): await process_frame

func check_card(node: Node, bounds: Rect2) -> void:
 if node is Label:
  check(node.get_global_rect().end.y <= bounds.end.y + 1, "card label fits: " + node.text)
 for child in node.get_children(): check_card(child, bounds)

func run() -> void:
 root.size = Vector2i(1600, 900)
 ui = Main.instantiate()
 root.add_child(ui)
 await settle()
 var groups = {
 "neutral":["stunning_blow", "wild_cast", "clockwork_bomb"],
 "fury":["hunt_mark", "desperate_strength", "warcry"],
 "bastion":["armor_sacrifice", "thorn_pierce"],
 "venom":["poison_trigger", "venom_pierce"]}
 for route in groups:
  for suffix in ["", "+"]:
   ui.game.new_run("fury" if route == "neutral" else route, 12112)
   ui.game.s.enemies = [Data.enemy("新卡测试目标", 1000, [Data.attack(10)]), Data.enemy("第二目标", 1000, [Data.defend(0)])]
   ui.game.s.enemies[0].stunned = 1
   ui.game.s.enemies[0].mark_crit = 20
   ui.game.s.enemies[0].mark_turns = 2
   ui.game.s.enemies[0].poison = 8
   ui.game.s.bombs = [{"target":0, "turn":2, "damage":21}]
   ui.game.s.turn_strength = 6
   ui.game.s.strength += 6
   ui.game.s.energy = 10
   ui.game.s.hand = []
   for id in groups[route]: ui.game.s.hand.append(id + suffix)
   ui.screen = "run"
   ui.on_menu = false
   ui.render()
   await settle()
   var cards = ui.find_child("HandCards", true, false)
   check(cards != null and cards.get_child_count() == groups[route].size(), "new hand renders: " + route + suffix)
   for card in cards.get_children(): check_card(card, card.get_global_rect())
   var status = ui.find_child("HeroStatuses", true, false)
   check(status.text.contains("发条炸弹") and status.text.contains("怒吼力量"), "timers and immediate strength visible")
   check(ui.find_child("EnemyIntent0", true, false).text == "眩晕 · 本次无法行动", "stun visible")
   if DisplayServer.get_name() != "headless":
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://test-results/nov12-new-cards-" + route + ("-upgraded" if suffix == "+" else "") + ".png")
   ui.show_catalog("fury" if route == "neutral" else route)
   await settle()
   ui.close_modal()
 print("NEW CARD UI CHECKS: ", checks, " passed: ", checks - failures, " failed: ", failures)
 ui.queue_free()
 await process_frame
 quit(0 if failures == 0 else 1)
