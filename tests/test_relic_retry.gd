extends SceneTree
const Run = preload("res://Game/Scripts/Combat/CombatState.gd")
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
var checks = 0
var errors = 0

func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  errors += 1
  printerr("FAIL: ", title)

func fixture(route: String = "venom", relics: Array = []) -> RefCounted:
 var g = Run.new()
 g.new_run(route, 42)
 g.s.relics = relics
 g.start_battle()
 g.s.enemies = [Data.enemy("练习敌人", 1000, [Data.defend(0)]), Data.enemy("练习敌人2", 1000, [Data.defend(0)])]
 return g

func _initialize() -> void:
 test_gem()
 test_gear()
 test_charm()
 test_retry()
 print("RELIC / RETRY CHECKS: ", checks, " passed: ", checks - errors, " failed: ", errors)
 quit(0 if errors == 0 else 1)

func test_gem() -> void:
 for route in ["venom", "bastion", "fury"]:
  var g = fixture(route, [Data.ROUTES[route].relic, "fang"])
  check(g.s.strength == (3 if route == "fury" else 0), "gem strength matches route " + route)
  check(g.s.block == (7 if route == "bastion" else 0), "gem opening block stacks with starter " + route)
  g.poison_enemy(0, 1)
  g.poison_enemy(1, 1)
  check(g.s.enemies[0].poison == (6 if route == "venom" else 1) and g.s.enemies[1].poison == 1, "gem only first poison target " + route)
  g.begin_turn()
  check(g.s.block == (3 if route == "bastion" else 0), "gem block does not repeat each turn " + route)
 var poison = fixture("venom", ["fang"])
 poison.s.enemies[0].hp = 0
 poison.poison_enemy(0, 4)
 poison.poison_enemy(1, 4)
 check(poison.s.enemies[1].poison == 7, "dead target does not spend first poison")

func test_gear() -> void:
 var g = fixture("fury", ["shell"])
 g.s.strength = 100
 g.s.energy = 100
 g.capture_combat_events = true
 for i in range(1, 13):
  g.s.hand = ["guard"]
  check(g.play(0), "gear accepts card " + str(i))
  check(2000 - g.s.enemies[0].hp - g.s.enemies[1].hp == mini(i / 3, 3) * 6, "gear triggers only at 3/6/9; no strength bonus " + str(i))
 check(g.combat_events.size() == 3, "gear damage uses normal animation event queue")
 g.end_turn()
 g.s.energy = 20
 for i in range(3):
  g.s.hand = ["guard"]
  g.play(0)
 check(g.s.turn_cards_played == 3 and 2000 - g.s.enemies[0].hp - g.s.enemies[1].hp == 24, "new turn resets combo count")
 var before: int = g.s.turn_cards_played
 check(not g.play(9) and g.s.turn_cards_played == before, "rejected cards do not count")
 g = fixture("fury", ["shell"])
 g.s.turn_cards_played = 2
 g.s.hand = ["strike"]
 g.s.enemies[0].hp = 1
 g.play(0)
 check(g.s.enemies[1].hp == 994, "gear retargets after card kills original target")
 g.s.turn_cards_played = 5
 g.s.hand = ["bloodlust"]
 g.s.hp = 1
 g.s.block = 0
 var enemy_hp: int = g.s.enemies[1].hp
 g.play(0)
 check(g.s.phase == "defeat" and g.s.enemies[1].hp == enemy_hp, "lethal self damage prevents gear damage")
 g = fixture("venom", ["shell"])
 g.s.turn_cards_played = 2
 g.s.hand = ["guard"]
 g.save_run("user://gear-check.json")
 var loaded = Run.new()
 check(loaded.load_run("user://gear-check.json") and loaded.play(0) and 2000 - loaded.s.enemies[0].hp - loaded.s.enemies[1].hp == 6, "combo progress survives save and load")

func test_charm() -> void:
 var g = fixture("venom", ["spikes"])
 g.s.max_hp = 100
 g.s.hp = 30
 g.s.hand = []
 g.begin_turn()
 check(not g.s.fate_triggered and g.s.energy == 3 and g.s.hand.size() == 2, "exactly thirty percent does not trigger charm")
 g.s.hp = 29
 g.s.hand = []
 g.begin_turn()
 check(g.s.fate_triggered and g.s.energy == 6 and g.s.hand.size() == 4, "below thirty percent gives two extra cards and three energy")
 g.save_run("user://charm-check.json")
 var loaded = Run.new()
 loaded.load_run("user://charm-check.json")
 loaded.s.hand = []
 loaded.begin_turn()
 check(loaded.s.energy == 3 and loaded.s.hand.size() == 2, "charm once per battle including after reload")
 loaded.start_battle()
 check(loaded.s.fate_triggered and loaded.s.hand.size() == 7 and loaded.s.energy == 6, "new battle resets charm and supports low HP opening")
 g = fixture("venom", ["spikes"])
 g.s.max_hp = 100
 g.s.hp = 25
 g.heal_player(20)
 g.begin_turn()
 check(not g.s.fate_triggered, "recovery before next turn avoids charm trigger")
 g.s.hp = 29
 g.s.hand = Array(g.s.deck.slice(0, 10))
 g.begin_turn()
 check(g.s.hand.size() == 10 and g.s.energy == 6 and g.s.fate_triggered, "charm respects hand cap but still grants energy")

func test_retry() -> void:
 for difficulty in ["easy", "normal", "hard", "legendary"]:
  var g = Run.new()
  g.new_run("fury", 782, difficulty)
  g.s.stage = 4
  g.s.hp = 37
  g.s.potions = 2
  g.s.gold = 95
  g.s.relics.append_array(["fang", "shell", "spikes"])
  g.start_battle()
  var original: Dictionary = g.s.duplicate(true)
  var original_rng: int = g.rng.state
  check(not g.retry_battle(), "cannot retry live battle " + difficulty)
  g.s.hp = 0
  g.s.potions = 0
  g.s.hand.clear()
  g.s.gold = 1
  g.rng.randi()
  g.check_outcome()
  g.save_run("user://retry-check.json")
  var loaded = Run.new()
  check(loaded.load_run("user://retry-check.json"), "defeat checkpoint loads " + difficulty)
  if difficulty == "legendary":
   var defeated = loaded.s.duplicate(true)
   check(not loaded.can_retry_battle() and not loaded.retry_battle() and loaded.s == defeated, "legendary forbids retry in rules layer")
  else:
   check(loaded.can_retry_battle() and loaded.retry_battle(), "first three modes allow retry " + difficulty)
   check(loaded.s == original and loaded.rng.state == original_rng, "retry restores complete opening and RNG " + difficulty)
   loaded.s.hp = 0
   loaded.check_outcome()
   check(loaded.retry_battle() and loaded.s == original, "repeat retry restores same checkpoint " + difficulty)
   loaded.enter_camp()
   loaded.s.hp = 50
   loaded.next_stage()
   loaded.s.hp = 0
   loaded.check_outcome()
   check(loaded.retry_battle() and loaded.s.stage == 5 and loaded.s.hp == 50, "next stage replaces checkpoint " + difficulty)
 var legacy = fixture()
 legacy.s.erase("battle_checkpoint")
 legacy.s.erase("turn_cards_played")
 legacy.s.erase("fate_triggered")
 legacy.s.version = 6
 legacy.s.hp = 0
 legacy.check_outcome()
 legacy.save_run("user://legacy-retry-check.json")
 var migrated = Run.new()
 check(migrated.load_run("user://legacy-retry-check.json") and migrated.s.version == 7, "v6 migration initializes new relic state")
 check(migrated.retry_battle() and migrated.s.hp == migrated.s.max_hp and migrated.s.phase == "battle", "legacy defeat lacking snapshot can restart stage")
