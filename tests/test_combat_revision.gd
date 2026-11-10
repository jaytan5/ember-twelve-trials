extends SceneTree
const Run = preload("res://scripts/run_state.gd")
const Data = preload("res://scripts/data.gd")
var checks = 0
var failures = 0

func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  printerr("FAIL: ", title)

func fresh():
 var g = Run.new()
 g.new_run("fury", 104)
 g.s.enemies = [Data.enemy("目标一", 1000, [Data.defend(0)]), Data.enemy("目标二", 1000, [Data.defend(0)])]
 g.s.max_hp = 80
 g.s.hp = 80
 g.s.strength = 0
 g.s.energy = 30
 g.s.draw = []
 g.s.discard = []
 return g

func play(g, id: String) -> void:
 g.s.hand = [id]
 g.s.energy = 30
 check(g.play(0), "plays " + id)

func _init() -> void:
 test_lifesteal()
 test_strength()
 test_critical()
 test_attacks()
 test_debuffs()
 test_decks_and_saves()
 test_document_order()
 print("COMBAT REVISION CHECKS: ", checks, " passed: ", checks - failures, " failed: ", failures)
 quit(0 if failures == 0 else 1)

func test_lifesteal() -> void:
 var g = fresh()
 g.s.hp = 20
 play(g, "battle_trance")
 check(g.s.energy == 27 and g.s.lifesteal == 0 and g.s.next_lifesteal == 75, "lifesteal costs three and is delayed")
 g.hit_enemy(0, 8)
 check(g.s.hp == 20, "no lifesteal on casting turn")
 g.end_turn()
 check(g.s.lifesteal == 75 and g.s.next_lifesteal == 0, "lifesteal activates next turn")
 g.hit_enemy(0, 8)
 check(g.s.hp == 26, "eight actual damage heals six")
 g.s.enemies[0].block = 100
 g.hit_enemy(0, 8)
 check(g.s.hp == 26, "fully blocked damage does not heal")
 g.s.enemies[0].block = 5
 g.hit_enemy(0, 8)
 check(g.s.hp == 28, "three health damage heals two rounded down")
 g.s.enemies[0].hp = 3
 g.hit_enemy(0, 100)
 check(g.s.hp == 30, "overkill healing capped by remaining enemy health")
 g.hit_enemy(0, 100)
 check(g.s.hp == 30, "dead target cannot provide healing")
 g.s.enemies[1].poison = 8
 g.end_turn()
 check(g.s.hp == 36 and g.s.lifesteal == 0, "next-turn poison heals before effect expires")
 g.hit_enemy(1, 8, true)
 check(g.s.hp == 36, "lifesteal expires after one complete round")
 g = fresh()
 g.s.hp = 78
 g.s.lifesteal = 75
 g.hit_enemy(0, 100)
 check(g.s.hp == 80, "lifesteal respects maximum health")
 g.s.hp = 0
 g.hit_enemy(0, 8)
 check(g.s.hp == 0, "lifesteal cannot resurrect")
 g = fresh()
 g.s.hp = 20
 g.s.lifesteal = 75
 g.s.thorns = 8
 g.s.enemies[0].pattern = [Data.attack(4)]
 g.end_turn()
 check(g.s.hp == 22, "thorns heal six after taking four during active round")
 g = fresh()
 play(g, "battle_trance+")
 check(g.s.energy == 28 and g.s.next_lifesteal == 75, "upgraded lifesteal costs two, same ratio")

func test_strength() -> void:
 var g = fresh()
 g.s.strength = 2
 play(g, "warcry")
 check(g.s.strength == 2 and g.s.next_strength == 6 and g.s.block == 0, "warcry queues strength without armor or immediate buff")
 g.end_turn()
 check(g.s.strength == 8 and g.s.temporary_strength == 6, "warcry grants temporary strength next turn")
 play(g, "rage")
 g.end_turn()
 check(g.s.strength == 4 and g.s.temporary_strength == 0, "expires without removing permanent strength gained during buff")
 play(g, "warcry+")
 play(g, "warcry")
 g.end_turn()
 check(g.s.strength == 19 and g.s.temporary_strength == 15, "queued warcries stack; upgrade adds nine")
 play(g, "warcry")
 g.end_turn()
 check(g.s.strength == 10 and g.s.temporary_strength == 6, "consecutive queued rounds replace expiring portion")
 g.end_turn()
 check(g.s.strength == 4, "last temporary strength expires")

func test_critical() -> void:
 var g = fresh()
 g.s.hp = 19
 play(g, "rage_slash")
 check(g.s.low_hp_crit == 50 and g.s.enemies[0].hp == 1000 and g.s.exhaust == ["rage_slash"], "violent enforcement is a two-cost battle ability without attack")
 play(g, "rage_slash+")
 play(g, "rage_slash")
 check(g.s.low_hp_crit == 60, "critical rates take maximum rather than stack")
 g.s.low_hp_crit = 100
 g.s.hp = 36
 var rng_before: int = g.rng.state
 g.hit_enemy(0, 8)
 check(g.s.enemies[0].hp == 992 and g.rng.state == rng_before, "exactly forty-five percent does not crit or consume RNG")
 g.s.hp = 35
 g.hit_enemy(0, 8, true)
 check(g.s.enemies[0].hp == 976, "direct damage can crit below strict health threshold")
 g.s.enemies[0].block = 10
 g.hit_enemy(0, 8)
 check(g.s.enemies[0].hp == 970 and g.s.enemies[0].block == 0, "critical multiplier applies before armor")
 g = fresh()
 g.s.hp = 10
 g.s.low_hp_crit = 100
 g.s.lifesteal = 75
 g.hit_enemy(0, 8)
 g.hit_enemy(0, 8)
 check(g.s.hp == 34 and g.s.enemies[0].hp == 968, "both hits crit while below thirty percent before each hit")
 for chance in [50, 60]:
  g = fresh()
  g.s.hp = 19
  g.s.low_hp_crit = chance
  g.s.enemies[0].hp = 10000
  var criticals = 0
  for _i in range(200):
   var before: int = g.s.enemies[0].hp
   g.hit_enemy(0, 8)
   var dealt: int = before - g.s.enemies[0].hp
   check(dealt == 8 or dealt == 16, "critical has only single or double damage")
   if dealt == 16: criticals += 1
  check(criticals > 65 and criticals < 155, "seeded critical sample contains both outcomes at " + str(chance))

func test_attacks() -> void:
 for suffix in ["", "+"]:
  var g = fresh()
  g.s.hp = 49
  play(g, "blood_charge" + suffix)
  check(g.s.enemies[0].hp == (983 if suffix == "" else 980) and g.s.energy == 28, "lost health damage percentage and rounding " + suffix)
  g = fresh()
  play(g, "blood_charge" + suffix)
  check(g.s.enemies[0].hp == 1000, "full health has zero lost-health base damage")
  g = fresh()
  g.s.block = 99
  play(g, "execute" + suffix)
  check(g.s.hp == 70 and g.s.block == 99 and g.s.enemies[0].hp == (955 if suffix == "" else 945), "execute loses ten life after a nonlethal attack " + suffix)
  g = fresh()
  g.s.hp = 10
  play(g, "execute" + suffix)
  check(g.s.hp == 0 and g.s.phase == "defeat" and g.s.enemies[0].hp == (955 if suffix == "" else 945), "nonlethal execute attack resolves before lethal life loss")
  g = fresh()
  play(g, "bloodlust" + suffix)
  check(g.s.hp == (75 if suffix == "" else 72) and g.s.energy == (31 if suffix == "" else 32), "bloodlust energy and life cost " + suffix)
  for id in ["cleave", "triple", "whirlwind"]:
   g = fresh()
   var hits: int = {"cleave":2, "triple":3, "whirlwind":3}[id] + (1 if suffix == "+" else 0)
   var base_damage: int = {"cleave":4, "triple":6, "whirlwind":6}[id]
   g.s.strength = 2
   play(g, id + suffix)
   check(2000 - g.s.enemies[0].hp - g.s.enemies[1].hp == (base_damage + 2) * hits, "each upgraded multiattack adds one hit, same per-hit damage " + id + suffix)
 var g = fresh()
 g.s.enemies[0].hp = 1
 g.s.coating = 2
 g.s.target = 0
 play(g, "whirlwind+")
 check(g.s.enemies[1].hp <= 982 and g.s.enemies[1].poison == 2, "random hits retarget living enemies and coating applies once per surviving target")
 g = fresh()
 g.s.enemies[1].hp = 0
 play(g, "whirlwind")
 check(g.s.enemies[0].hp == 982, "all random hits can select the only living enemy")

func test_debuffs() -> void:
 var g = fresh()
 play(g, "expose")
 play(g, "expose+")
 play(g, "disarm")
 play(g, "disarm+")
 check(g.s.enemies[0].vulnerable == 2 and g.s.enemies[0].weak == 2, "debuff refresh keeps longer duration without stacking")
 check(g.attack_value(g.s.enemies[0], Data.attack(10)) == 7, "weak lowers attack by thirty percent")
 var before: int = g.s.enemies[0].hp
 g.hit_enemy(0, 10)
 check(g.s.enemies[0].hp == before - 13, "vulnerability raises normal damage by thirty percent")
 g.s.enemies[0].pattern = [Data.attack(10), Data.defend(0), Data.buff(0)]
 for _i in range(3):
  g.end_turn()
  var remaining = maxi(0, 1 - _i)
  check(g.s.enemies[0].vulnerable == remaining and g.s.enemies[0].weak == remaining, "debuffs decay after each enemy phase")
 play(g, "disarm+")
 play(g, "expose+")
 g.s.enemies[0].frozen = 1
 g.end_turn()
 check(g.s.enemies[0].vulnerable == 1 and g.s.enemies[0].weak == 1, "frozen round also consumes one round of debuffs")

func test_decks_and_saves() -> void:
 var g = fresh()
 g.enter_camp()
 while g.s.deck.size() > 15: check(g.move_card("deck", 0, "reserve"), "can remove to fifteen")
 var before = g.s.duplicate(true)
 check(not g.move_card("deck", 0, "reserve") and not g.has_method("remove_card") and g.s == before, "fifteen-card boundary blocks transfer; permanent removal is unavailable")
 g.s.deck.pop_back()
 g.next_stage()
 check(g.s.phase == "camp" and g.s.stage == 1, "invalid fourteen-card deck cannot enter battle")
 var path = "res://test-results/combat-revision-save.json"
 g = fresh()
 g.s.next_lifesteal = 75
 g.s.next_strength = 3
 g.s.temporary_strength = 4
 g.s.strength = 6
 g.s.low_hp_crit = 60
 g.s.hp = 10
 g.save_run(path)
 var copy = Run.new()
 check(copy.load_run(path) and copy.s == g.s, "new effects save and load without changing state")
 copy.end_turn()
 check(copy.s.strength == 5 and copy.s.temporary_strength == 3 and copy.s.lifesteal == 75, "loaded delayed effects activate and expire old strength correctly")
 check(copy.load_run(path), "restore state before RNG comparison")
 play(g, "whirlwind+")
 play(copy, "whirlwind+")
 check(copy.s == g.s and copy.rng.state == g.rng.state, "save reload preserves random targets and independent critical rolls")
 g = fresh()
 g.s.version = 5
 g.s.deck.resize(5)
 g.s.reserve = ["triple+", "cleave+"]
 g.s.fury = 15
 g.s.fury_engine = 2
 var hand = g.s.hand.duplicate()
 g.save_run(path)
 check(copy.load_run(path) and copy.s.deck.size() == 15 and copy.s.reserve.is_empty(), "legacy small deck equips reserves then grants basics")
 check(copy.s.deck.has("triple+") and copy.s.deck.has("cleave+") and copy.s.hand == hand and copy.s.draw.size() == 10, "legacy migration preserves upgrades and hand and adds new draw copies")
 check(not copy.s.has("fury") and not copy.s.has("fury_engine"), "removed rage states erased")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_document_order() -> void:
 for route in ["neutral", "venom", "bastion", "fury"]:
  var previous = -1
  for id in Data.sorted_card_ids(route):
   var cost: int = Data.card(id).cost
   if cost < 0: cost = 99
   check(cost >= previous, "document card costs sorted " + route)
   previous = cost
