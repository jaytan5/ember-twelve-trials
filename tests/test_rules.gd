extends SceneTree
const Run = preload("res://scripts/run_state.gd")
const Data = preload("res://scripts/data.gd")
var failures = 0
var checks = 0

func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  printerr("FAIL: ", title)

func _init() -> void:
 for id in Data.CARDS:
  check(Data.describe(Data.card(id)) != Data.describe(Data.card(id + "+")) or Data.card(id + "+").cost < Data.card(id).cost, "upgrade improves effect or cost " + id)
 for route in Data.ROUTES:
  var g = Run.new()
  g.new_run(route, 42)
  check(g.s.deck.size() == 17 and g.s.hand.size() == 5 and g.s.energy == 3, "initial deck and turn " + route)
  check(g.s.hp == Data.ROUTES[route].hp, "route health")
 test_damage()
 test_flow()
 test_save()
 test_expanded_cards()
 test_balance_rules()
 test_deck_management()
 test_difficulties()
 test_revision_rules()
 for route in Data.ROUTES:
  var wins = 0
  var stages = 0
  for seed_value in range(1, 11):
   var g = simulate(route, seed_value)
   if g.s.phase == "victory": wins += 1
   stages += g.s.stage
  print("BALANCE ", route, ": ", wins, "/10 wins, average last stage ", stages / 10.0)
 print("RULE CHECKS: ", checks, " passed: ", checks - failures, " failed: ", failures)
 quit(0 if failures == 0 else 1)

func test_damage() -> void:
 var g = Run.new()
 g.new_run("venom", 11)
 g.s.hand = ["sting", "catalyst", "guard", "focus"]
 g.s.energy = 3
 check(g.play(0), "sting plays")
 check(g.s.enemies[0].poison == 5, "first poison relic")
 check(g.play(0) and g.s.enemies[0].poison == 10, "catalyst doubles poison")
 check(g.s.discard.has("catalyst") and g.s.exhaust.is_empty(), "catalyst is recyclable")
 var old_hp: int = g.s.enemies[0].hp
 g.s.enemies[0].block = 100
 g.end_turn()
 check(g.s.enemies[0].hp == old_hp - 10 and g.s.enemies[0].poison == 9, "poison direct tick and decay")
 g.new_run("bastion", 5)
 g.s.hand = ["fortify", "shield_bash", "hold"]
 g.s.energy = 4
 g.s.enemies[0].hp = 100
 g.s.enemies[0].max_hp = 100
 g.play(0)
 check(g.s.block == 13, "initial block plus fortify")
 g.play(0)
 check(g.s.enemies[0].hp == 85, "shield bash uses current block")
 g.play(0)
 g.end_turn()
 check(g.s.block == 15, "retention capped at twelve plus relic")
 g.end_turn()
 check(g.s.block == 15, "retention persists through enemy defense turn")
 g.end_turn()
 check(g.s.block == 9, "retained armor depletes against next attack")
 g.new_run("fury", 12)
 g.s.hand = ["cleave"]
 g.play(0)
 check(g.s.enemies[0].hp == 22, "strength adds to each hit")
 g.s.hand = ["strike"]
 g.s.energy = 0
 var before = g.s.duplicate(true)
 check(not g.play(0) and g.s == before, "unaffordable card does not mutate state")
 g.s.enemies[0].weak = 1
 g.s.enemies[0].vulnerable = 1
 g.s.energy = 1
 g.play(0)
 check(g.s.enemies[0].hp == 11, "thirty percent vulnerable rounds damage up")
 var hp: int = g.s.hp
 g.end_turn()
 check(g.s.hp == hp - 4 and g.s.enemies[0].weak == 0, "one-round weakness expires after enemy phase")
 g.s.hp = 1
 g.s.hand = ["bloodlust"]
 g.play(0)
 check(g.s.phase == "defeat", "self-damage defeat")
 g.new_run("venom", 3)
 g.s.enemies[0].hp = 1
 g.s.enemies[0].poison = 5
 hp = g.s.hp
 g.end_turn()
 check(g.s.phase == "reward" and g.s.hp == hp, "poison kill prevents enemy action")
 g.new_run("bastion", 2)
 g.s.enemies[0].hp = 1
 g.s.thorns = 4
 g.s.block = 20
 g.end_turn()
 check(g.s.phase == "reward", "thorns on blocked attack wins")
 g.new_run("fury", 2)
 g.s.draw.clear()
 g.s.discard = ["strike", "guard"]
 g.s.hand.clear()
 g.draw_cards(5)
 check(g.s.hand.size() == 2 and g.s.discard.is_empty(), "empty draw reshuffle")
 g.s.hand.resize(10)
 g.s.draw = ["strike"]
 g.draw_cards(1)
 check(g.s.hand.size() == 10 and g.s.draw.size() == 1, "ten card hand cap")

func test_flow() -> void:
 var g = Run.new()
 g.new_run("venom", 1)
 for stage in range(1, 13):
  check(g.s.stage == stage and g.s.phase == "battle", "stage entered %d" % stage)
  check(g.s.enemies[0].boss == (stage % 3 == 0), "boss cadence")
  for e in g.s.enemies: e.hp = 0
  g.check_outcome()
  check(g.s.last_gold == (80 if stage % 3 == 0 else 30) + (20 if g.has_relic("coin") else 0), "victory reward including relic bonus")
  var reward_gold: int = g.s.gold
  g.check_outcome()
  check(g.s.gold == reward_gold, "victory reward granted only once")
  if stage == 12:
   check(g.s.phase == "victory" and g.s.wins == 12 and g.s.trophy == "余烬王冠", "final victory and trophy")
   break
  check(g.s.phase == "reward", "reward phase")
  if stage % 3 == 0:
   check(g.s.reward_cards.all(func(id): return id.ends_with("+")), "boss upgraded rewards")
  var old_size: int = g.s.deck.size() + g.s.reserve.size()
  g.take_card(0)
  check(g.s.deck.size() + g.s.reserve.size() == old_size + 1, "reward card added to equipped deck or reserve")
  if stage % 3 == 0:
   check(g.s.phase == "relic" and g.s.relic_choices.size() == 3, "boss relic phase")
   var old_relics: int = g.s.relics.size()
   g.take_relic(0)
   check(g.s.relics.size() == old_relics + 1, "relic obtained")
  check(g.s.phase == "camp", "camp entered")
  g.s.gold = 300
  check(g.buy_card(0) and not g.buy_card(0), "shop item bought once")
  check(g.s.gold == 255, "shop cost")
  g.s.hp = 10
  check(g.buy_heal() and g.s.hp == 34 and not g.buy_heal(), "heal once")
  g.s.potions = 1
  check(g.buy_potion() and not g.buy_potion(), "potion capacity")
  check(not g.has_method("remove_card"), "permanent card removal is unavailable")
  if stage == 1:
   check(g.upgrade_card(0) and g.s.deck[0].ends_with("+"), "upgrade")
   var hp: int = g.s.hp
   g.rest()
   check(g.s.hp == hp, "rest and upgrade exclusive")
  else:
   g.rest()
   check(not g.upgrade_card(1), "upgrade and rest exclusive")
  g.next_stage()

func test_save() -> void:
 var g = Run.new()
 g.new_run("venom", 8)
 g.s.hp = 20
 check(g.use_potion() and g.s.hp == 40 and g.s.potions == 1, "potion effect")
 var path = "res://test-results/rules-save.json"
 check(g.save_run(path) == OK, "save file")
 var copy = Run.new()
 check(copy.load_run(path), "load file")
 check(JSON.stringify(copy.s) == JSON.stringify(g.s), "full save round trip")
 copy.end_turn()
 check(copy.s.turn == 2, "loaded battle resumes")
 check(not copy.load_run("res://missing-save.json"), "missing save handled")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

# A simple non-cheating heuristic bot uses only visible intent and current hand.
func simulate(route: String, seed_value: int):
 var g = Run.new()
 g.new_run(route, seed_value)
 var safety = 0
 while g.s.phase not in ["victory", "defeat"] and safety < 1500:
  safety += 1
  match g.s.phase:
   "battle":
    if g.s.hp <= g.s.max_hp - 22: g.use_potion()
    var ids = g.living()
    ids.sort_custom(func(a, b): return g.s.enemies[a].hp < g.s.enemies[b].hp)
    g.select_target(ids[0])
    var best = -1
    var best_score = 0.0
    for i in range(g.s.hand.size()):
     var c = Data.card(g.s.hand[i])
     if not g.can_play(i): continue
     var score = score_card(g, c)
     if score > best_score:
      best_score = score
      best = i
    if best >= 0: g.play(best)
    else: g.end_turn()
   "reward":
    var best = -1
    var best_score = 0.0
    for i in range(g.s.reward_cards.size()):
     var id: String = g.s.reward_cards[i]
     var score = draft_score(g, id)
     if score > best_score:
      best = i
      best_score = score
    g.take_card(best)
   "relic":
    var best = 0
    var ranks = ["battery", "book", "shell", "fang", "flask", "heart", "spikes", "coin"]
    for i in range(g.s.relic_choices.size()):
     if ranks.find(g.s.relic_choices[i]) < ranks.find(g.s.relic_choices[best]): best = i
    g.take_relic(best)
   "camp":
    if g.s.hp < g.s.max_hp * 0.75: g.rest()
    else:
     var upgraded = false
     for i in range(g.s.deck.size()):
      if not g.s.deck[i].ends_with("+") and Data.card(g.s.deck[i]).route == route:
       g.upgrade_card(i)
       upgraded = true
       break
     if not upgraded: g.rest()
    if g.s.hp < g.s.max_hp - 20: g.buy_heal()
    if g.s.potions < 2: g.buy_potion()
    if g.s.gold >= 40:
     var idx = g.s.deck.find("strike")
     if idx >= 0: g.move_card("deck", idx, "reserve")
    for i in range(g.s.shop_cards.size()):
     if draft_score(g, g.s.shop_cards[i]) > 8 and g.s.deck.size() < 18: g.buy_card(i)
    g.next_stage()
 check(safety < 1500, "simulation terminates " + route)
 return g

func draft_score(g, id: String) -> float:
 var base = id.trim_suffix("+")
 var preference = {"venom":["sting", "plague", "catalyst", "toxic_guard", "leech", "coating", "detonate"], "bastion":["shield_bash", "hold", "fortify", "shield_draw", "rampart", "counter", "thorn_growth", "thorn_storm", "shield_charge"], "fury":["rage", "cleave", "triple", "whirlwind", "execute", "battle_trance", "rage_slash", "warcry"]}
 var rank = preference[g.s.route].find(base)
 var value = 12.0 - rank if rank >= 0 else (7.0 if base in ["mend", "disarm", "expose"] else 0.0)
 if id.ends_with("+"): value += 2
 if g.s.deck.count(id) >= 2: value -= 8
 if g.s.deck.size() >= 19: value -= 12
 return value

func score_card(g, c: Dictionary) -> float:
 var e: Dictionary = g.s.enemies[g.s.target]
 var threat = 0
 for enemy in g.s.enemies:
  if enemy.hp > enemy.poison:
   var intent = g.intent_for(enemy)
   if intent.type == "attack": threat += g.attack_value(enemy, intent) * intent.hits
 var score = 0.0
 if c.has("damage"):
  var damage = (c.damage + g.s.strength + (g.s.block if c.get("block_damage", false) else 0)) * c.get("hits", 1)
  score += mini(damage, e.hp + e.block) * 1.0
  if damage >= e.hp + e.block: score += 10
 if c.has("all_damage"): score += (c.all_damage + g.s.strength + int(g.s.block * c.get("block_ratio", 0))) * g.living().size()
 if c.has("poison"): score += mini(c.poison * 2.2, e.hp)
 if c.has("all_poison"): score += c.all_poison * g.living().size() * 2.1
 if c.has("multiply_poison"): score += minf(mini(e.poison * (c.multiply_poison - 1), c.poison_growth_cap) * 2.0, e.hp * 1.2)
 if c.has("block"): score += mini(c.block, maxi(0, threat - g.s.block)) * 1.7 + (c.block * 0.4 if g.s.route == "bastion" else 0)
 if c.has("retain_cap"): score += maxi(0, c.retain_cap - g.s.retain_cap) * 2.0
 if c.has("strength"): score += c.strength * 8
 if c.has("thorns"): score += c.thorns * 6
 if c.has("heal"): score += mini(c.heal, g.s.max_hp - g.s.hp) * 2.2
 if c.has("armor_damage"): score += e.block * c.armor_damage
 if c.has("barrier"): score += minf(threat, 15)
 if c.has("freeze_all"): score += threat * 1.5
 if c.has("store_energy"): score += 0.1 if g.s.energy > 0 else -10
 if c.has("heal_recent"): score += mini(c.heal_recent, g.s.recoverable_hp) * 2.2
 if c.has("weak"): score += threat * 0.5
 if c.has("vulnerable"): score += 5
 if c.has("draw"): score += c.draw * (5 if g.s.energy > c.cost else 0.5)
 if c.has("energy"): score += 10 if g.s.hand.size() > 2 and g.s.hp > 8 else -100
 if c.has("temp_thorns"): score += c.temp_thorns * (2 if threat > 0 else 0)
 if c.has("all_thorns_damage"): score += g.total_thorns() * c.all_thorns_damage * g.living().size()
 if c.has("poison_burst"): score += mini(e.poison * c.poison_burst, e.hp) - mini(e.poison * 1.5, e.hp)
 if c.has("coating"): score += c.coating * 8
 if c.has("next_lifesteal"): score += 8 if g.s.hp < g.s.max_hp * 0.7 else 1
 if c.has("next_strength"): score += c.next_strength * 3
 if c.has("turn_strength"): score += c.turn_strength * 3
 if c.has("low_hp_crit"): score += 8 if g.s.low_hp_crit < c.low_hp_crit else -100
 if c.has("random_damage"): score += (c.random_damage + g.s.strength) * c.hits
 if c.has("lost_hp_damage"): score += (g.s.max_hp - g.s.hp) * c.lost_hp_damage / 100.0 + g.s.strength
 if c.has("self_damage") and g.s.hp <= c.self_damage: score = -1000
 if c.has("next_energy"): score += c.next_energy * 3 - (c.get("poison_cost", 0) * 1.5)
 if c.has("next_block"): score += c.next_block * 0.5
 if c.has("next_draw"): score += c.next_draw * 2
 return score / maxf(1, c.cost) - 0.1

func durable_run(route: String = "venom"):
 var g = Run.new()
 g.new_run(route, 77)
 g.s.enemies = [Data.enemy("测试目标", 1000, [Data.attack(6)]), Data.enemy("第二目标", 1000, [Data.defend(0)])]
 g.s.energy = 20
 return g

func test_expanded_cards() -> void:
 var counts = {"neutral":0, "venom":0, "bastion":0, "fury":0}
 for id in Data.CARDS:
  counts[Data.CARDS[id].route] += 1
  for suffix in ["", "+"]:
   var probe = durable_run()
   probe.s.hand = [id + suffix]
   probe.s.enemies[0].poison = 10
   probe.s.thorns = 4
   check(probe.play(0), "all card variants execute: " + id + suffix)
 check(counts == {"neutral":20, "venom":12, "bastion":12, "fury":12}, "exact 20/12/12/12 card counts")
 var g = durable_run()
 g.s.hand = ["detonate"]
 g.s.enemies[0].poison = 7
 g.s.enemies[0].block = 100
 g.s.enemies[0].vulnerable = 2
 g.play(0)
 check(g.s.enemies[0].hp == 979 and g.s.enemies[0].block == 100 and g.s.enemies[0].poison == 0, "poison detonation consumes stacks, bypasses armor, ignores vulnerable")
 g = durable_run()
 g.s.hand = ["recycle"]
 g.s.enemies[0].poison = 3
 var before = g.s.duplicate(true)
 check(not g.can_play(0) and not g.play(0) and g.s == before, "poison cost rejects without mutation")
 g.s.enemies[0].poison = 4
 g.play(0)
 check(g.s.enemies[0].poison == 0 and g.s.energy == 20 and g.s.next_energy == 1 and g.s.hand.is_empty(), "recycle pays poison for delayed energy without draw")
 g = durable_run()
 g.s.hand = ["coating", "cleave", "sweep"]
 g.play(0)
 g.play(0)
 check(g.s.enemies[0].poison == 3, "coating triggers once per multihit card with initial venom relic")
 g.play(0)
 check(g.s.enemies[0].poison == 4 and g.s.enemies[1].poison == 1, "coating affects each AOE target once")
 g = durable_run("bastion")
 g.s.hand = ["thorn_armor", "thorn_growth", "thorn_storm"]
 g.play(0)
 check(g.s.block == 9 and g.s.thorns == 0 and g.s.temp_thorns == 2, "thorn armor gives armor and temporary thorns")
 g.play(0)
 g.play(0)
 check(g.s.thorns == 4 and g.total_thorns() == 6 and g.s.enemies[0].hp == 976 and g.s.enemies[1].hp == 976, "thorn storm scales and preserves thorns")
 g.end_turn()
 check(g.s.enemies[0].hp == 970 and g.s.thorns == 4 and g.s.temp_thorns == 0, "combined thorns retaliate then temporary expires")
 g = durable_run("bastion")
 g.s.block = 11
 g.s.hand = ["shield_charge"]
 g.play(0)
 check(g.s.enemies[0].hp == 992 and g.s.enemies[1].hp == 992 and g.s.block == 11, "half-armor AOE rounds down without consuming armor")
 g = durable_run("fury")
 g.s.hand = ["battle_trance", "warcry", "rage_slash"]
 for _i in range(3): g.play(0)
 check(g.s.next_lifesteal == 75 and g.s.turn_strength == 6 and g.s.next_strength == 0 and g.s.low_hp_crit == 50, "route abilities queue lifesteal and grant current-turn strength")
 g.start_battle()
 check(g.s.lifesteal == 0 and g.s.next_lifesteal == 0 and g.s.low_hp_crit == 0 and g.s.next_strength == 0, "route statuses reset between encounters")
 g = durable_run()
 g.s.hand = ["sunder"]
 g.s.enemies[0].block = 90
 g.play(0)
 check(g.s.enemies[0].hp == 910 and g.s.enemies[0].block == 0, "sunder strips armor before hitting")
 # New cards are available in offers and never leak another route's cards.
 var offered: Dictionary = {}
 for route in Data.ROUTES:
  g = durable_run(route)
  for _roll in range(120):
   for id in g.roll_cards(3):
    offered[id] = true
    check(Data.card(id).route in [route, "neutral"], "reward route isolation")
 for id in Data.CARDS:
  if id not in ["strike", "guard"]: check(offered.has(id), "card reachable in reward pool: " + id)

func test_balance_rules() -> void:
 var costs = {"neutral":[], "venom":[], "bastion":[], "fury":[]}
 for id in Data.CARDS:
  var c = Data.card(id)
  costs[c.route].append(c.cost)
  for suffix in ["", "+"]:
   var g = durable_run()
   g.s.hand = [id + suffix]
   g.s.enemies[0].poison = 20
   # Keep draws away from the card being checked.
   g.s.draw = []
   for _i in range(12): g.s.draw.append("strike")
   g.play(0)
   if c.kind == "能力" or c.get("exhaust", false): check(g.s.exhaust == [id + suffix], "only abilities activate: " + id + suffix)
   else: check(g.s.exhaust.is_empty() and g.s.discard.has(id + suffix), "all ordinary cards recycle: " + id + suffix)
  check(c.kind == "能力" or not c.get("exhaust", false) or id == "mend", "only emergency heal is a consumable skill")
  if c.cost == 0:
   check(not c.has("draw") and (not c.has("energy") or c.get("self_damage", 0) > 0), "free cards cannot fuel costless draw energy loops")
 for route in costs: check(3 in costs[route], "every pool has three-cost cards: " + route)
 check(2 in costs.neutral, "neutral has two-cost cards")
 var g = durable_run("bastion")
 g.s.hand = ["hold", "hold+", "hold"]
 g.play(0)
 g.play(0)
 g.play(0)
 check(g.s.retain_cap == 16, "multiple holds use maximum rather than stack")
 g.s.block = 50
 g.end_turn()
 check(g.s.block == 19, "retention caps remainder before relic")
 g.s.enemies[0].pattern = [Data.attack(30)]
 g.end_turn()
 check(g.s.block == 3 and g.s.retain_cap == 16, "retention does not recreate armor spent on attacks")
 g.start_battle()
 check(g.s.retain_cap == 0, "retention resets next battle")
 g = durable_run()
 g.s.hand = ["stockpile", "recycle+"]
 g.s.energy = 2
 g.s.enemies[0].poison = 4
 g.play(0)
 g.play(0)
 check(g.s.energy == 0 and g.s.next_energy == 4, "delayed energy stacks without immediate grant")
 g.end_turn()
 check(g.s.energy == 7 and g.s.next_energy == 0, "delayed energy granted once")
 g.end_turn()
 check(g.s.energy == 3, "delayed energy expires")
 g = durable_run()
 g.s.hand = ["catalyst", "catalyst+"]
 g.s.enemies[0].poison = 30
 g.play(0)
 check(g.s.enemies[0].poison == 42, "catalyst caps added stacks")
 g.play(0)
 check(g.s.enemies[0].poison == 60, "upgraded catalyst growth capped at eighteen")
 g = durable_run()
 g.s.hp = 30
 g.end_turn()
 check(g.s.hp == 24 and g.s.recoverable_hp == 6, "actual enemy health damage forms wound budget")
 g.s.energy = 20
 g.s.hand = ["leech"]
 g.play(0)
 check(g.s.hp == 28 and g.s.recoverable_hp == 2, "leech still obeys recent wound budget")
 g.s.hand = ["mend"]
 g.play(0)
 check(g.s.hp == 48 and g.s.recoverable_hp == 0, "emergency heal restores old wounds")
 g.s.block = 0
 g.end_turn()
 g.s.enemies[0].pattern = [Data.defend(0)]
 g.end_turn()
 check(g.s.recoverable_hp == 0, "unused wounds expire at next enemy phase")
 g.s.enemies[0].pattern = [Data.attack(4, 3)]
 g.s.block = 5
 g.end_turn()
 check(g.s.recoverable_hp == 7, "multihit wound budget sums only unblocked health loss")
 # Migrate old ordinary exhausted cards, preserving duplicate upgrades and active abilities.
 var path = "res://test-results/balance-save.json"
 for version in [1, 2, 3]:
  g = durable_run()
  g.s.version = version
  g.s.exhaust = ["focus+", "mend", "focus+", "coating"]
  for key in ["next_energy", "retain_cap", "temp_thorns", "recoverable_hp"]: g.s.erase(key)
  g.s.keep_block = true
  g.s.block = 20
  g.save_run(path)
  var copy = Run.new()
  check(copy.load_run(path) and copy.s.version == 8, "balance save migration version %d" % version)
  check(copy.s.exhaust == ["mend", "coating"] and copy.s.discard.count("focus+") == 2, "migration preserves copies and activates only abilities")
  copy.end_turn()
  check(copy.s.block == 14 and not copy.s.keep_block, "legacy one-turn hold honored once")
  copy.end_turn()
  check(copy.s.block == 0, "legacy hold does not become indefinite")
 g = durable_run("bastion")
 g.s.retain_cap = 16
 g.s.temp_thorns = 3
 g.s.recoverable_hp = 7
 g.s.next_energy = 2
 g.save_run(path)
 var restored = Run.new()
 check(restored.load_run(path) and JSON.stringify(restored.s) == JSON.stringify(g.s), "all new battle statuses survive save round trip")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_deck_management() -> void:
 var g = durable_run()
 check(not g.move_card("deck", 0, "reserve"), "battle deck edits forbidden")
 g.enter_camp()
 while g.s.deck.size() < 30: g.acquire_card("guard")
 g.s.gold = 100
 g.s.shop_cards = ["detonate+"]
 check(g.buy_card(0) and g.s.deck.size() == 30 and g.s.reserve == ["detonate+"] and g.s.gold == 55, "shop overflow retained in reserve")
 check(not g.move_card("reserve", 0, "deck"), "cannot exceed 30")
 check(g.move_card("deck", 0, "reserve") and g.s.deck.size() == 29, "drag out to reserve")
 check(g.move_card("reserve", 0, "deck") and g.s.deck[-1] == "detonate+" and g.s.deck.size() == 30, "drag upgraded card into freed slot")
 var owned = g.s.deck.duplicate() + g.s.reserve.duplicate()
 owned.sort()
 for _i in range(10):
  g.move_card("deck", 0, "reserve")
  g.move_card("reserve", 0, "deck")
 var after = g.s.deck.duplicate() + g.s.reserve.duplicate()
 after.sort()
 check(owned == after, "swapping duplicate copies preserves full multiset")
 var before = g.s.duplicate(true)
 check(not g.move_card("hand", 0, "reserve") and not g.move_card("deck", -1, "reserve") and not g.move_card("deck", 0, "deck") and g.s == before, "invalid moves leave state intact")
 var path = "res://test-results/deck-save.json"
 g.save_run(path)
 var copy = Run.new()
 check(copy.load_run(path) and copy.s.deck == g.s.deck and copy.s.reserve == g.s.reserve, "both zones persist with upgrades")
 g.s.phase = "reward"
 g.s.reward_cards = ["sting+"]
 g.take_card(0)
 check(g.s.deck.size() == 30 and g.s.reserve.has("sting+"), "reward overflow retained")
 g.next_stage()
 var piles = g.s.hand + g.s.draw
 piles.sort()
 var active = g.s.deck.duplicate()
 active.sort()
 check(piles == active and piles.size() == 30, "only equipped 30 cards enter next battle")
 g.enter_camp()
 while g.s.deck.size() > 15: g.move_card("deck", 0, "reserve")
 check(not g.move_card("deck", 0, "reserve") and g.s.deck.size() == 15, "minimum deck enforced")
 # Legacy save: no new keys and more than 30 owned cards; keep in-progress battle.
 g = durable_run()
 var original_hand = g.s.hand.duplicate()
 while g.s.deck.size() < 34: g.s.deck.append("strike+")
 g.s.version = 1
 for key in ["reserve", "fury", "fury_engine", "coating", "next_block", "next_draw", "last_acquired_zone", "difficulty"]: g.s.erase(key)
 g.save_run(path)
 check(copy.load_run(path) and copy.s.version == 8 and copy.s.deck.size() == 30 and copy.s.reserve.size() == 4, "legacy oversized deck migrates without losing copies")
 check(copy.s.hand == original_hand and not copy.s.has("fury") and copy.s.coating == 0, "legacy current combat preserved")
 copy.end_turn()
 check(copy.s.phase == "battle", "legacy battle resumes")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_difficulties() -> void:
 var g = Run.new()
 for difficulty in ["easy", "normal", "hard", "legendary"]:
  g.new_run("venom", 55, difficulty)
  check(g.s.difficulty == difficulty and g.shows_intents() == (difficulty == "easy"), "difficulty and preview policy: " + difficulty)
  for stage in range(1, 13):
   var base = Data.encounter(stage)
   var scaled = g.encounter_for(stage)
   for i in range(base.size()):
    var original: Dictionary = base[i]
    var enemy: Dictionary = scaled[i]
    var hp_scale = 1.35 if difficulty in ["hard", "legendary"] else 1.0
    var action_scale = 1.25 if difficulty in ["hard", "legendary"] else 1.0
    check(enemy.hp == int(ceil(original.hp * hp_scale)) and enemy.max_hp == enemy.hp, "enemy health scale floor %d %s" % [stage, difficulty])
    for j in range(original.pattern.size()):
     check(enemy.pattern[j].amount == int(ceil(original.pattern[j].amount * action_scale)), "attack defense buff scaling")
     check(enemy.pattern[j].type == original.pattern[j].type and enemy.pattern[j].get("hits", 1) == original.pattern[j].get("hits", 1), "pattern and hit count preserved")
   check(Data.encounter(stage) == base, "scaling does not mutate base encounter")
  var enemy = Data.enemy("意图测试", 100, [Data.attack(6, 2), Data.defend(9), Data.buff(2)])
  enemy.strength = 2
  enemy.weak = 1
  if difficulty == "easy":
   check(g.visible_intent_text(enemy) == "连续攻击 5 ×2（共 10）", "easy preview accounts for strength weak and multihit")
   enemy.step = 1
   check(g.visible_intent_text(enemy) == "防御 +9 护甲", "easy defense preview")
   enemy.step = 2
   check(g.visible_intent_text(enemy) == "蓄力 +2 力量", "easy buff preview")
  else:
   for step in range(3):
    enemy.step = step
    check(g.visible_intent_text(enemy) == "行动未知", "hidden action text identical for all actions")
  var hp: int = g.s.hp
  g.end_turn()
  check(g.s.hp == hp - (8 if difficulty in ["hard", "legendary"] else 6), "actual attack uses scaled value")
  check(g.s.log.any(func(line): return "发动攻击" in line), "completed enemy actions remain in battle log")
  g.s.stage = 3
  g.start_battle()
  var boss_hp: int = g.s.enemies[0].hp
  g.start_battle()
  check(g.s.enemies[0].hp == boss_hp, "battle rebuild does not compound scaling")
  var path = "res://test-results/difficulty-save.json"
  g.s.enemies[0].hp -= 7
  g.save_run(path)
  var loaded = Run.new()
  check(loaded.load_run(path) and loaded.s.difficulty == difficulty and loaded.s.enemies == g.s.enemies, "difficulty and ongoing scaled enemies round trip")
  if difficulty == "easy":
   for legacy_version in [1, 2]:
    var legacy = g.s.duplicate(true)
    legacy.version = legacy_version
    legacy.erase("difficulty")
    var file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string(JSON.stringify(legacy))
    file.close()
    check(loaded.load_run(path) and loaded.s.difficulty == "easy" and loaded.s.enemies == legacy.enemies, "old saves keep visible intents and current values")
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_revision_rules() -> void:
 var expected_common = ["strike", "strike", "strike", "guard", "guard", "quick", "quick", "sweep", "focus", "focus", "insight", "erudition"]
 for route in Data.ROUTES:
  var initial = Run.new()
  initial.new_run(route, 1)
  check(initial.s.deck.slice(0, 12) == expected_common and initial.s.deck.size() == 17, "exact common starter list " + route)
  check(initial.s.hand.size() == 5 and initial.s.draw.size() == 12, "opening hand and remaining deck " + route)
  check(initial.s.deck.slice(12).all(func(id): return Data.card(id).route == route), "five route-exclusive starters " + route)
 for id in ["first_aid", "rally", "feint", "prepare"]: check(not Data.CARDS.has(id), "removed card absent " + id)
 var g = durable_run("fury")
 g.s.hand = ["strike", "guard", "focus", "quick", "sweep"]
 g.s.draw = ["rage", "cleave", "execute", "warcry", "strike", "guard"]
 g.s.discard = []
 var retained = g.s.hand.duplicate()
 g.end_turn()
 check(g.s.hand.slice(0, 5) == retained and g.s.hand.size() == 7 and g.s.discard.is_empty(), "retain hand and draw exactly two")
 g.end_turn()
 check(g.s.hand.size() == 9, "second retained turn draws two")
 g.end_turn()
 check(g.s.hand.size() == 10 and g.s.draw.size() == 1, "only draw to limit without burning overflow")
 g.end_turn()
 check(g.s.hand.size() == 10 and g.s.draw.size() == 1, "full hand leaves draw pile untouched")
 g.s.hand = ["guard"]
 g.s.draw = ["strike"]
 g.s.discard = ["quick", "sweep"]
 g.draw_cards(4)
 check(g.s.hand.size() == 4 and g.s.hand[0] == "guard" and g.s.hand[1] == "strike" and g.s.draw.is_empty() and g.s.discard.is_empty(), "draw across shuffle without duplicating retained cards")
 g = durable_run("fury")
 g.s.strength = 0
 g.s.hand = ["expose", "disarm", "quick", "brace"]
 g.s.hp = 20
 g.play(0)
 check(g.s.enemies[0].hp == 999 and g.s.enemies[0].vulnerable == 1, "expose deals one before vulnerability")
 g.play(0)
 check(g.s.hp == 23 and g.s.block == 0 and g.s.enemies[0].weak == 1, "disarm directly heals three and applies weakness")
 g.s.enemies[0].vulnerable = 0
 g.play(0)
 check(g.s.enemies[0].hp == 997, "quick two one-damage hits")
 var hand_size: int = g.s.hand.size()
 g.play(0)
 check(g.s.enemies[0].poison == 2 and g.s.hand.size() == hand_size, "brace poisons target and draws one")
 g = durable_run("fury")
 g.s.strength = 0
 g.s.hp = 20
 g.s.hand = ["polymath"]
 g.play(0)
 check(g.s.enemies[0].hp == 998 and g.s.block == 2 and g.s.hp == 23 and g.s.strength == 1 and g.s.enemies[0].poison == 2, "polymath resolves all five effects with strength after damage")
 g.s.hand = ["mend"]
 g.play(0)
 check(g.s.hp == 43 and g.s.exhaust == ["mend"] and not g.s.discard.has("mend"), "mend heals twenty and exhausts")
 g.s.draw = []
 g.draw_cards(8)
 check(not g.s.hand.has("mend"), "mend cannot reappear on reshuffle")
 g.s.deck = ["mend", "strike", "guard", "focus", "quick"]
 while g.s.deck.size() < 15: g.s.deck.append("strike")
 g.start_battle()
 check((g.s.hand + g.s.draw).has("mend") and g.s.exhaust.is_empty(), "consumable returns next encounter")
 g = durable_run("fury")
 g.s.strength = 50
 g.s.enemies[0].vulnerable = 3
 g.s.enemies[0].block = 17
 g.s.hand = ["sunder", "sunder"]
 g.play(0)
 check(g.s.enemies[0].hp == 983 and g.s.enemies[0].block == 0, "sunder exact removed armor without strength/vulnerable")
 g.play(0)
 check(g.s.enemies[0].hp == 983, "zero armor produces zero damage")
 g.s.enemies[0].block = 17
 g.s.hand = ["sunder+"]
 g.play(0)
 check(g.s.enemies[0].hp == 958, "upgraded armor damage rounds 17 times 1.5 down to 25")
 g = durable_run("fury")
 g.s.energy = 4
 g.s.hand = ["stockpile"]
 g.play(0)
 check(g.s.energy == 0 and g.s.next_energy == 4, "X spends all available energy")
 g.end_turn()
 check(g.s.energy == 7 and g.s.next_energy == 0, "stored energy granted next turn")
 g.end_turn()
 check(g.s.energy == 3, "stored energy granted once")
 g.s.energy = 0
 g.s.hand = ["stockpile"]
 check(g.play(0) and g.s.next_energy == 0 and g.s.energy == 0, "X zero allowed without free base energy")
 g.s.hand = ["stockpile+"]
 check(g.play(0) and g.s.next_energy == 0 and g.s.energy == 1, "upgraded X zero returns one immediately without next-turn bonus")
 g.s.energy = 4
 g.s.hand = ["stockpile+"]
 check(g.play(0) and g.s.next_energy == 4 and g.s.energy == 1, "upgraded X stores original energy and immediately returns one")
 g.s.hand = ["guard"]
 check(g.play(0) and g.s.energy == 0, "returned energy is spendable during the casting turn")
 g.end_turn()
 check(g.s.energy == 7 and g.s.next_energy == 0, "upgraded X grants only stored X next turn")
 g.end_turn()
 check(g.s.energy == 3, "upgraded stored energy does not repeat")
 g = durable_run("fury")
 g.s.hand = ["blizzard", "blizzard"]
 g.s.enemies[0].poison = 3
 var hp: int = g.s.hp
 g.play(0)
 g.play(0)
 check(g.s.enemies.all(func(e): return e.frozen == 1), "freeze affects every living enemy without stacking turns")
 g.end_turn()
 check(g.s.hp == hp and g.s.enemies[0].hp == 997 and g.s.enemies[0].poison == 2 and g.s.enemies[0].step == 0, "frozen enemy takes poison but skips its action")
 check(g.s.enemies.all(func(e): return e.frozen == 0), "freeze expires on skipped phase")
 g.end_turn()
 check(g.s.hp == hp - 6 and g.s.enemies[0].step == 1, "enemy resumes the same pending action")
 g = durable_run("fury")
 g.s.enemies[0].pattern = [Data.attack(4, 3)]
 g.s.hand = ["aegis"]
 g.play(0)
 hp = g.s.hp
 g.end_turn()
 check(g.s.hp == hp - 8 and g.s.barrier == 0, "barrier cancels one multihit segment")
 g.s.energy = 3
 g.s.hand = ["aegis", "aegis"]
 g.play(0)
 g.play(0)
 check(g.s.barrier == 2, "barrier stacks charges")
 check(g.take_player_damage(0) == 0 and g.s.barrier == 2, "zero damage does not consume barrier")
 g.s.enemies[0].pattern = [Data.defend(0)]
 g.end_turn()
 check(g.s.barrier == 2, "unused barrier persists across turns")
 g.s.block = 10
 hp = g.s.hp
 check(g.take_player_damage(6) == 0 and g.s.block == 10 and g.s.hp == hp and g.s.barrier == 1, "barrier prevents hit before armor is spent")
 g.s.energy = 3
 g.s.hand = ["bloodlust"]
 g.play(0)
 check(g.s.hp == hp and g.s.barrier == 0 and g.s.energy == 4, "barrier also intercepts positive self damage")
 g.start_battle()
 check(g.s.barrier == 0, "barrier resets between battles")
 g = durable_run("fury")
 g.s.hand = ["erudition"]
 g.s.draw = []
 for _i in range(12): g.s.draw.append("strike")
 g.play(0)
 check(g.s.hand.size() == 6 and g.s.draw.size() == 6, "erudition draws six")
 g.s.hand = ["erudition", "guard", "guard", "guard", "guard", "guard", "guard", "guard", "guard", "guard"]
 g.play(0)
 check(g.s.hand.size() == 10 and g.s.draw.size() == 5, "erudition respects ten-card cap")
 # Stable RNG state prevents save/reload from rerolling later rewards.
 var save_path = "res://test-results/revision-save.json"
 g.s.barrier = 2
 g.s.barrier_reflects = [0, 0]
 g.s.enemies[0].frozen = 1
 g.s.next_energy = 5
 g.save_run(save_path)
 var restored = Run.new()
 check(restored.load_run(save_path) and restored.s == g.s, "all new states survive save/load")
 check(restored.roll_cards(3) == g.roll_cards(3), "RNG state survives save/load")
 g.s.version = 4
 g.s.deck = ["first_aid+", "rally", "feint", "prepare+", "strike"]
 g.s.hand = ["first_aid+", "rally", "feint", "prepare+", "strike", "guard", "quick", "sweep", "focus", "insight", "strike", "guard"]
 g.s.reward_cards = ["first_aid", "rally+", "prepare"]
 g.s.shop_cards = ["feint+", "prepare", "rally"]
 g.save_run(save_path)
 check(restored.load_run(save_path), "old save with deleted cards migrates")
 check(restored.s.deck.slice(0, 5) == ["disarm+", "stockpile", "expose", "aegis+", "strike"] and restored.s.deck.size() == 15, "old owned cards map to replacements retaining upgrades and minimum")
 check(restored.s.hand.size() == 10 and restored.s.draw.size() == g.s.draw.size() + 12, "legacy hand overflow and supplemented cards preserved in draw pile")
 check(restored.s.reward_cards == ["disarm", "stockpile+", "aegis"] and restored.s.shop_cards == ["expose+", "aegis", "stockpile"], "legacy offers also migrate")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
