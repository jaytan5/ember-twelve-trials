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

func fresh():
 var g = Run.new()
 g.new_run("fury", 11010)
 g.s.relics = []
 g.s.max_hp = 100
 g.s.hp = 100
 g.s.strength = 0
 g.s.block = 0
 g.s.enemies = [Data.enemy("Attacker", 1000, [Data.attack(11, 3)]), Data.enemy("Other", 1000, [Data.defend(0)])]
 return g

func play(g, id: String) -> void:
 g.s.hand = [id]
 g.s.energy = 100
 check(g.play(0), "play " + id)

func _init() -> void:
 test_reflection()
 test_durations()
 test_thresholds()
 test_execute()
 test_supply_and_migration()
 print("NOV10 BALANCE CHECKS: ", checks, " passed: ", checks-errors, " failed: ", errors)
 quit(0 if errors == 0 else 1)

func test_reflection() -> void:
 var g = fresh()
 play(g, "aegis+")
 check(g.s.block == 0, "upgraded aegis replaces former armor bonus")
 g.end_turn()
 check(g.s.hp == 78 and g.s.enemies[0].hp == 995 and g.s.enemies[1].hp == 1000, "one multihit segment blocked; half rounded down reflects only to attacker")
 check(g.s.barrier == 0 and g.s.barrier_reflects.is_empty(), "single reflecting charge consumed")
 g = fresh()
 play(g, "aegis")
 play(g, "aegis+")
 check(g.take_player_damage(0, false, 0) == 0 and g.s.barrier == 2, "zero damage consumes no charge")
 g.take_player_damage(10, false, 0)
 check(g.s.enemies[0].hp == 1000 and g.s.barrier == 1, "ordinary charge does not inherit upgraded reflection")
 g.take_player_damage(10, false, 0)
 check(g.s.enemies[0].hp == 995 and g.s.barrier_reflects.is_empty(), "next upgraded charge keeps its own reflection")
 g = fresh()
 g.s.enemies[0].hp = 5
 play(g, "aegis+")
 g.end_turn()
 check(g.s.hp == 100 and g.s.enemies[0].hp == 0, "reflection kill interrupts remaining enemy attack segments")
 g = fresh()
 play(g, "aegis+")
 g.take_player_damage(10, true)
 check(g.s.hp == 100 and g.s.enemies[0].hp == 1000, "self damage has no attacker and cannot reflect to arbitrary target")

func test_durations() -> void:
 for suffix in ["", "+"]:
  var duration = 1 if suffix == "" else 2
  var g = fresh()
  play(g, "disarm" + suffix)
  play(g, "expose" + suffix)
  check(g.s.enemies[0].weak == duration and g.s.enemies[0].vulnerable == duration, "both duration variants " + suffix)
  g.end_turn()
  check(g.s.hp == 79 and g.s.enemies[0].weak == duration-1 and g.s.enemies[0].vulnerable == duration-1, "weak affects all segments then both statuses lose one round " + suffix)
  g.s.enemies[0].frozen = 1
  g.end_turn()
  check(g.s.enemies[0].weak == 0 and g.s.enemies[0].vulnerable == 0, "frozen round consumes final duration " + suffix)

func test_thresholds() -> void:
 for suffix in ["", "+"]:
  var g = fresh()
  var threshold = 30 if suffix == "" else 45
  play(g, "rage_slash" + suffix)
  check(g.s.low_hp_crit_threshold == threshold, "ability stores threshold " + suffix)
  g.s.low_hp_crit = 100
  g.s.hp = threshold
  var before: int = g.rng.state
  g.hit_enemy(0, 10)
  check(g.s.enemies[0].hp == 990 and g.rng.state == before, "exact threshold does not crit or roll RNG " + suffix)
  g.s.hp = threshold-1
  g.hit_enemy(0, 10)
  check(g.s.enemies[0].hp == 970, "strictly below threshold crits " + suffix)
  g.heal_player(10)
  g.hit_enemy(0, 10)
  check(g.s.enemies[0].hp == 960, "healing above threshold disables next hit crit " + suffix)

func test_execute() -> void:
 for suffix in ["", "+"]:
  var damage = 45 if suffix == "" else 55
  var g = fresh()
  g.s.hp = 10
  g.s.enemies[0].hp = damage
  play(g, "execute" + suffix)
  check(g.s.hp == 10 and g.s.enemies[0].hp == 0 and g.s.phase == "battle", "exact kill waives life loss even at ten HP " + suffix)
  g = fresh()
  g.s.hp = 10
  play(g, "execute" + suffix)
  check(g.s.hp == 0 and g.s.phase == "defeat" and g.s.enemies[0].hp == 1000-damage, "nonkill attacks first then can defeat player " + suffix)
  g = fresh()
  g.s.enemies[0].hp = damage
  g.s.enemies[0].block = 100
  play(g, "execute" + suffix)
  check(g.s.hp == 90 and g.s.enemies[0].hp == damage, "armor preventing kill does not waive life loss " + suffix)

func test_supply_and_migration() -> void:
 var g = fresh()
 g.enter_camp()
 g.s.potions = 1
 check(g.buy_potion() and g.s.potions == 2, "buy second potion")
 var before = g.s.duplicate(true)
 check(not g.buy_potion() and g.s == before, "capacity prevents third potion without charging gold")
 check(not g.has_method("remove_card"), "permanent deletion is absent from rules")
 g = fresh()
 play(g, "aegis+")
 play(g, "expose+")
 play(g, "rage_slash+")
 var path = "user://nov10-migration.json"
 g.save_run(path)
 var copy = Run.new()
 check(copy.load_run(path) and copy.s == g.s, "save roundtrip preserves reflection queue, two-round status and crit threshold")
 g.s.version = 7
 g.s.potions = 3
 g.s.erase("low_hp_crit_threshold")
 g.s.erase("barrier_reflects")
 g.s.battle_checkpoint.state.version = 7
 g.s.battle_checkpoint.state.potions = 3
 g.save_run(path)
 check(copy.load_run(path) and copy.s.version == 8 and copy.s.potions == 2 and copy.s.low_hp_crit_threshold == 45, "legacy save caps potions and migrates active upgraded ability")
 check(copy.s.enemies[0].vulnerable == 1 and copy.s.barrier_reflects == [0], "legacy indefinite status becomes one round and old barrier remains nonreflecting")
 copy.s.phase = "defeat"
 check(copy.retry_battle() and copy.s.potions == 2, "legacy checkpoint cannot restore third potion")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
