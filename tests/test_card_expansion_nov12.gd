extends SceneTree
const Run = preload("res://Game/Scripts/Combat/CombatState.gd")
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
var checks = 0
var failures = 0

func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  printerr("FAIL: ", title)

func fresh():
 var g = Run.new()
 g.new_run("fury", 12112)
 g.s.relics = []
 g.s.hp = 100
 g.s.max_hp = 100
 g.s.strength = 0
 g.s.block = 0
 g.s.energy = 30
 g.s.hand = []
 g.s.draw = []
 g.s.discard = []
 g.s.enemies = [Data.enemy("甲", 1000, [Data.attack(10)]), Data.enemy("乙", 1000, [Data.defend(0)])]
 return g

func play(g, id: String) -> void:
 g.s.hand = [id]
 check(g.play(0), "play " + id)

func _init() -> void:
 check(Data.CARDS.size() == 56 and Data.card_count("neutral") == 20, "56 base cards; 20 neutral")
 for route in ["fury", "bastion", "venom"]: check(Data.card_count(route) == 12, "12 cards for " + route)
 test_stun()
 test_autoplay()
 test_bombs()
 test_mark()
 test_strength()
 test_route_attacks()
 test_saves()
 print("NOV12 CARD CHECKS: ", checks, " passed: ", checks - failures, " failed: ", failures)
 quit(0 if failures == 0 else 1)

func test_stun() -> void:
 var g = fresh()
 g.s.enemies[0].poison = 3
 play(g, "stunning_blow")
 check(g.s.energy == 28 and g.s.enemies[0].stunned == 1 and g.s.enemies[1].stunned == 0, "two-cost single-target stun")
 check(g.visible_intent_text(g.s.enemies[0]) == "眩晕 · 本次无法行动", "stun visible even when intents hidden")
 play(g, "stunning_blow+")
 check(g.s.energy == 27 and g.s.enemies[0].stunned == 1, "upgraded stun costs one and does not stack")
 g.s.enemies[0].frozen = 1
 g.end_turn()
 check(g.s.hp == 100 and g.s.enemies[0].hp == 997 and g.s.enemies[0].poison == 2 and g.s.enemies[0].step == 0, "stun skips action, keeps poison and action order")
 check(g.s.enemies[0].stunned == 0 and g.s.enemies[0].frozen == 0, "freeze and stun expire together without double skip")
 g.end_turn()
 check(g.s.hp == 90 and g.s.enemies[0].step == 1, "enemy resumes next phase")

func test_autoplay() -> void:
 var g = fresh()
 g.s.energy = 3
 g.s.draw = ["strike", "guard", "execute"]
 play(g, "wild_cast")
 check(g.s.energy == 0 and g.s.enemies[0].hp == 948 and g.s.block == 6 and g.s.hp == 90, "three cards play freely in draw order, retaining self-harm")
 check(g.s.hand.is_empty() and g.s.discard.size() == 4 and g.s.played == 4, "automatic cards recycle and count as played")
 g = fresh()
 g.s.energy = 3
 g.s.hand = ["wild_cast+"]
 for _i in range(9): g.s.hand.append("guard")
 g.s.draw = ["quick", "quick", "guard", "strike", "focus", "rage"]
 check(g.play(0), "upgraded autoplay with nine retained hand cards")
 check(g.s.played == 5 and g.s.hand.size() == 10 and g.s.strength == 2 and g.s.block == 6 and g.s.enemies[0].hp == 991, "reserve four auto cards before draw effects, ignore hand cap for auto resolution")
 g = fresh()
 g.s.draw = ["rage", "mend", "guard"]
 play(g, "wild_cast")
 check(g.s.exhaust.has("rage") and g.s.exhaust.has("mend") and g.s.discard.has("guard"), "automatic abilities and emergency heal still exhaust")
 g = fresh()
 g.s.draw = ["guard", "strike", "execute"]
 g.s.enemies[0].hp = 45
 play(g, "wild_cast")
 check(g.s.hp == 100 and g.s.enemies[1].hp == 993 and g.s.target == 1, "automatic attacks retarget after exact kill without self-harm")
 g = fresh()
 g.s.hp = 5
 g.s.draw = ["strike", "guard", "bloodlust"]
 play(g, "wild_cast")
 check(g.s.phase == "defeat" and g.s.block == 0 and g.s.enemies[0].hp == 1000 and g.s.discard.size() == 4, "automatic lethal self-harm stops chain and preserves remaining cards")
 g = fresh()
 g.s.enemies[0].hp = 7
 g.s.enemies[1].hp = 0
 g.s.draw = ["bloodlust", "guard", "strike"]
 play(g, "wild_cast")
 check(g.s.phase == "reward" and g.s.hp == 100 and g.s.block == 0 and g.s.discard.size() == 4, "victory stops remaining automatic cards and awards once")
 g = fresh()
 g.s.draw = ["strike", "recycle", "poison_trigger"]
 play(g, "wild_cast")
 check(g.s.played == 2 and g.s.enemies[0].hp == 993 and g.s.discard.size() == 4, "automatic poison requirements fail safely without consuming a play")
 g = fresh()
 g.s.energy = 5
 g.s.draw = ["guard", "strike", "stockpile+"]
 play(g, "wild_cast")
 check(g.s.energy == 3 and g.s.next_energy == 2, "free X uses current energy as X without spending it; upgraded refund remains immediate")
 g = fresh()
 play(g, "wild_cast")
 check(g.s.played == 1 and g.s.discard == ["wild_cast"], "resolving copy cannot shuffle into its own automatic draw")
 g = fresh()
 for _i in range(80): g.s.draw.append("wild_cast")
 play(g, "wild_cast")
 check(g.s.played == 65 and g.s.draw.size() + g.s.discard.size() == 81, "long automatic chains are bounded and conserve every copy")
 g = fresh()
 g.s.relics = ["shell"]
 g.s.draw = ["guard", "guard", "guard"]
 play(g, "wild_cast")
 check(g.s.turn_cards_played == 4 and g.s.enemies[0].hp + g.s.enemies[1].hp == 1988, "automatic plays trigger combo relic at cards two and four exactly once")

func test_bombs() -> void:
 var g = fresh()
 play(g, "clockwork_bomb")
 check(g.s.energy == 28 and g.s.bombs.size() == 1 and g.s.exhaust == ["clockwork_bomb"] and g.s.enemies[0].hp == 1000, "bomb costs two, exhausts as ability, no immediate damage")
 g.end_turn()
 check(g.s.turn == 2 and g.s.enemies[0].hp == 1000 and g.s.bombs.size() == 1, "bomb does not explode on casting turn")
 g.end_turn()
 check(g.s.enemies[0].hp == 979 and g.s.bombs.is_empty(), "bomb explodes for 21 at following player turn end")
 g.end_turn()
 check(g.s.enemies[0].hp == 979, "bomb only explodes once")
 g = fresh()
 g.s.enemies[0].pattern = [Data.defend(0)]
 g.s.enemies[0].hp = 28
 g.s.enemies[1].hp = 0
 play(g, "clockwork_bomb+")
 g.end_turn()
 g.s.enemies[0].pattern = [Data.attack(200)]
 g.end_turn()
 check(g.s.phase == "reward" and g.s.hp == 100, "upgraded 28-damage bomb kills before lethal enemy action")
 g = fresh()
 play(g, "clockwork_bomb")
 g.s.enemies[0].hp = 0
 g.s.target = 1
 g.end_turn()
 g.end_turn()
 check(g.s.enemies[1].hp == 979, "bomb retargets a surviving enemy when marked target dies")
 g.start_battle()
 check(g.s.bombs.is_empty(), "bombs reset between battles")

func test_mark() -> void:
 var g = fresh()
 play(g, "hunt_mark")
 check(g.s.energy == 29 and g.attack_crit_chance(0) == 20 and g.attack_crit_chance(1) == 0 and g.attack_crit_chance(0, false) == 0, "mark adds 20 percentage points only to attacks on marked target")
 play(g, "hunt_mark+")
 check(g.attack_crit_chance(0) == 30 and g.s.enemies[0].mark_turns == 2, "upgraded mark refreshes two turns at maximum rate")
 g.s.hp = 20
 g.s.low_hp_crit = 60
 check(g.attack_crit_chance(0) == 90 and g.attack_crit_chance(0, false) == 60, "mark adds to low-health critical chance but not poison or thorns")
 g.s.low_hp_crit = 90
 check(g.attack_crit_chance(0) == 100, "combined chance caps at 100 percent")
 var before: int = g.s.enemies[0].hp
 g.s.hand = ["cleave"]
 check(g.play(0) and g.s.enemies[0].hp == before - 16, "each attack hit uses combined critical chance")
 g.s.low_hp_crit = 0
 before = g.s.enemies[0].hp
 var state: int = g.rng.state
 g.hit_enemy(0, 10, true)
 check(g.s.enemies[0].hp == before - 10 and g.rng.state == state, "mark alone never rolls a critical for non-attack damage")
 g.s.enemies[0].stunned = 1
 g.end_turn()
 check(g.s.enemies[0].mark_turns == 1, "mark duration decays even when target stunned")
 g.end_turn()
 check(g.s.enemies[0].mark_turns == 0 and g.s.enemies[0].mark_crit == 0, "mark ends after two enemy phases")

func test_strength() -> void:
 for suffix in ["", "+"]:
  var g = fresh()
  g.s.hp = 39
  play(g, "desperate_strength" + suffix)
  var gained = 9 if suffix == "" else 12
  check(g.s.strength == 0 and g.s.next_strength == gained, "lost-health strength queues snapshot rounded down " + suffix)
  g.heal_player(61)
  g.s.enemies[0].stunned = 1
  g.end_turn()
  check(g.s.strength == gained and g.s.temporary_strength == gained and g.s.next_strength == 0, "healing does not alter queued strength " + suffix)
  play(g, "warcry+")
  play(g, "rage")
  check(g.s.strength == gained + 11, "warcry stacks immediately with delayed and permanent strength " + suffix)
  g.end_turn()
  check(g.s.strength == 2 and g.s.turn_strength == 0 and g.s.temporary_strength == 0, "both temporary buffs expire without erasing permanent strength " + suffix)
 var g = fresh()
 play(g, "desperate_strength")
 check(g.s.next_strength == 0, "full health queues zero strength")

func test_route_attacks() -> void:
 for suffix in ["", "+"]:
  var g = fresh()
  g.s.block = 11
  g.s.strength = 2
  play(g, "armor_sacrifice" + suffix)
  check(g.s.block == 0 and g.s.enemies[0].hp == (976 if suffix == "" else 971), "armor consumed before multiplier, rounded down, strength added " + suffix)
  g = fresh()
  g.s.thorns = 3
  g.s.temp_thorns = 2
  g.s.strength = 2
  play(g, "thorn_pierce" + suffix)
  check(g.s.enemies[0].hp == (984 if suffix == "" else 977) and g.total_thorns() == 5, "thorn attack scales combined thorns without consuming them " + suffix)
  g = fresh()
  g.s.enemies[0].poison = 8
  g.s.enemies[0].block = 100
  play(g, "poison_trigger" + suffix)
  check(g.s.enemies[0].hp == 992 and g.s.enemies[0].block == 100 and g.s.enemies[0].poison == (7 if suffix == "" else 8), "immediate poison bypasses armor; upgrade preserves layers " + suffix)
  g = fresh()
  g.s.enemies[0].poison = 30
  g.s.strength = 2
  play(g, "venom_pierce" + suffix)
  check(g.s.enemies[0].hp == (985 if suffix == "" else 978) and g.s.enemies[0].poison == 30, "poison attack has layer cap and does not consume poison " + suffix)
 var g = fresh()
 g.s.hand = ["poison_trigger"]
 var before = g.s.duplicate(true)
 check(not g.play(0) and g.s == before, "cannot spend card or energy triggering zero poison")

func test_saves() -> void:
 var g = fresh()
 play(g, "clockwork_bomb")
 play(g, "hunt_mark+")
 play(g, "stunning_blow")
 g.s.hp = 41
 play(g, "desperate_strength+")
 play(g, "warcry")
 var path = "user://nov12-cards-roundtrip.json"
 check(g.save_run(path) == OK, "save expanded states")
 var copy = Run.new()
 check(copy.load_run(path) and copy.s == g.s and copy.rng.state == g.rng.state, "expanded states roundtrip including timers and RNG")
 for _i in range(2):
  g.end_turn()
  copy.end_turn()
 check(copy.s == g.s and copy.rng.state == g.rng.state, "loaded stun, bomb, mark and strength resolve identically")
 g = fresh()
 for state in [g.s, g.s.battle_checkpoint.state]:
  state.erase("bombs")
  state.erase("turn_strength")
  for enemy in state.enemies:
   for key in ["stunned", "mark_crit", "mark_turns"]: enemy.erase(key)
 g.save_run(path)
 check(copy.load_run(path) and copy.s.bombs.is_empty() and copy.s.turn_strength == 0 and copy.s.enemies[0].stunned == 0, "old saves initialize new states")
 check(copy.s.battle_checkpoint.state.bombs.is_empty() and copy.s.battle_checkpoint.state.enemies[0].mark_turns == 0, "old retry snapshots initialize new states")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
