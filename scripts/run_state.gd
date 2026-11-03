extends RefCounted
## Serializable game rules, deliberately independent of the presentation.
const Data = preload("res://scripts/data.gd")
const DECK_LIMIT = 30
const DECK_MIN = 5
var s: Dictionary = {}
var rng = RandomNumberGenerator.new()

func new_run(route: String, seed_value: int = 0, difficulty: String = "easy") -> void:
 rng.randomize()
 if seed_value != 0: rng.seed = seed_value
 var r: Dictionary = Data.ROUTES[route]
 s = {"version":4, "route":route, "difficulty":difficulty if Data.DIFFICULTIES.has(difficulty) else "easy", "stage":1, "phase":"battle", "hp":r.hp, "max_hp":r.hp,
 "gold":65, "deck":["strike", "strike", "strike", "guard", "guard", "guard", "focus"],
 "relics":[r.relic], "potions":2, "wins":0, "played":0, "damage_total":0, "log":[],
 "reward_cards":[], "relic_choices":[], "shop_cards":[], "shop_sold":[], "shop_healed":false, "shop_removed":false,
 "last_gold":0, "boss_reward_taken":false, "camp_used":false, "trophy":"", "reserve":[], "last_acquired_zone":"deck"}
 s.deck.append_array(r.cards)
 start_battle()

func note(message: String) -> void:
 s.log.append(message)
 while s.log.size() > 35: s.log.pop_front()

func shuffle_list(items: Array) -> void:
 for i in range(items.size() - 1, 0, -1):
  var j = rng.randi_range(0, i)
  var temp = items[i]
  items[i] = items[j]
  items[j] = temp

func has_relic(id: String) -> bool:
 return id in s.relics

func start_battle() -> void:
 if s.deck.size() < DECK_MIN or s.deck.size() > DECK_LIMIT: return
 s.phase = "battle"
 s.enemies = encounter_for(s.stage)
 s.draw = s.deck.duplicate()
 shuffle_list(s.draw)
 s.hand = []
 s.discard = []
 s.exhaust = []
 s.block = 0
 s.strength = (1 if has_relic("blade_core") else 0) + (2 if has_relic("fang") else 0)
 s.thorns = 4 if has_relic("spikes") else 0
 s.fury = 0
 s.fury_engine = 0
 s.coating = 0
 s.next_block = 0
 s.next_draw = 0
 s.next_energy = 0
 s.retain_cap = 0
 s.temp_thorns = 0
 s.recoverable_hp = 0
 s.keep_block = false
 s.first_poison = true
 s.turn = 0
 s.target = 0
 s.log = []
 note("第 %d 关 · %s" % [s.stage, Data.STAGE_NAMES[s.stage - 1]])
 begin_turn()

func begin_turn() -> void:
 if not s.keep_block: s.block = mini(s.block, s.retain_cap)
 s.keep_block = false
 s.temp_thorns = 0
 s.block += (3 if has_relic("iron_core") else 0) + (4 if has_relic("shell") else 0)
 s.block += s.next_block
 s.next_block = 0
 s.energy_max = 3 + (1 if has_relic("battery") else 0)
 s.energy = s.energy_max + s.next_energy
 s.next_energy = 0
 s.turn += 1
 draw_cards(5 + (1 if has_relic("book") else 0) + s.next_draw)
 s.next_draw = 0
 note("回合 %d：抽牌，恢复能量。" % s.turn)

func draw_cards(amount: int) -> void:
 for _i in range(amount):
  if s.hand.size() >= 10: return
  if s.draw.is_empty():
   if s.discard.is_empty(): return
   s.draw = s.discard.duplicate()
   s.discard.clear()
   shuffle_list(s.draw)
   note("弃牌堆洗入抽牌堆。")
  s.hand.append(s.draw.pop_back())

func select_target(index: int) -> void:
 if s.phase == "battle" and index >= 0 and index < s.enemies.size() and s.enemies[index].hp > 0:
  s.target = index

func living() -> Array:
 var result: Array = []
 for i in range(s.enemies.size()):
  if s.enemies[i].hp > 0: result.append(i)
 return result

func hit_enemy(index: int, amount: int, direct: bool = false) -> void:
 var e: Dictionary = s.enemies[index]
 if e.hp <= 0: return
 var damage = maxi(0, amount)
 if not direct and e.vulnerable > 0: damage = int(ceil(damage * 1.5))
 if not direct:
  var absorbed = mini(e.block, damage)
  e.block -= absorbed
  damage -= absorbed
 var dealt = mini(e.hp, damage)
 e.hp -= dealt
 s.damage_total += dealt
 if e.hp <= 0: note("击败 %s！" % e.name)

func poison_enemy(index: int, amount: int) -> void:
 if s.enemies[index].hp <= 0: return
 if s.first_poison and has_relic("venom_core"):
  amount += 2
  s.first_poison = false
 s.enemies[index].poison += amount

func can_play(index: int) -> bool:
 if s.phase != "battle" or index < 0 or index >= s.hand.size(): return false
 var c = Data.card(s.hand[index])
 if s.energy < c.cost: return false
 if c.has("poison_cost"):
  if s.target < 0 or s.target >= s.enemies.size(): return false
  if s.enemies[s.target].hp <= 0 or s.enemies[s.target].poison < c.poison_cost: return false
 return not living().is_empty()

func play(index: int) -> bool:
 if not can_play(index): return false
 var id: String = s.hand[index]
 var c = Data.card(id)
 var targets = living()
 if targets.is_empty(): return false
 if s.target not in targets: s.target = targets[0]
 var target: int = s.target
 if c.has("poison_cost"): s.enemies[target].poison -= c.poison_cost
 s.energy -= c.cost
 s.hand.remove_at(index)
 if c.kind == "能力": s.exhaust.append(id)
 else: s.discard.append(id)
 s.played += 1
 note("打出 %s%s。" % [c.name, " → " + s.enemies[target].name if c.get("target", false) else ""])
 if c.has("self_damage"): s.hp = maxi(0, s.hp - c.self_damage)
 if s.hp <= 0:
  s.phase = "defeat"
  note("燃血耗尽了最后的生命。")
  return true
 if c.has("block"): s.block += c.block
 if c.has("strength"): s.strength += c.strength
 if c.has("thorns"): s.thorns += c.thorns
 if c.has("temp_thorns"): s.temp_thorns += c.temp_thorns
 if c.has("coating"): s.coating += c.coating
 if c.has("fury"): s.fury += c.fury
 if c.has("fury_engine"): s.fury_engine += c.fury_engine
 if c.has("next_block"): s.next_block += c.next_block
 if c.has("next_draw"): s.next_draw += c.next_draw
 if c.has("next_energy"): s.next_energy += c.next_energy
 if c.has("energy"): s.energy += c.energy
 if c.has("retain_cap"): s.retain_cap = maxi(s.retain_cap, c.retain_cap)
 if c.has("break_block"): s.enemies[target].block = 0
 if c.has("damage"):
  var damage: int = c.damage + s.strength + (s.block if c.get("block_damage", false) else 0)
  if c.has("fury_burst"):
   damage += s.fury * c.fury_burst
   s.fury = 0
  for _hit in range(c.get("hits", 1)): hit_enemy(target, damage)
 if c.has("all_damage"):
  for t in targets: hit_enemy(t, c.all_damage + s.strength + int(floor(s.block * c.get("block_ratio", 0.0))))
 if c.has("all_thorns_damage"):
  for t in targets: hit_enemy(t, total_thorns() * c.all_thorns_damage)
 if c.has("poison_burst"):
  var stacks: int = s.enemies[target].poison
  s.enemies[target].poison = 0
  hit_enemy(target, stacks * c.poison_burst, true)
  note("毒爆消耗 %d 层毒素。" % stacks)
 if c.has("poison"): poison_enemy(target, c.poison)
 if c.has("all_poison"):
  for t in targets: poison_enemy(t, c.all_poison)
 if c.has("multiply_poison"):
  s.enemies[target].poison += mini(s.enemies[target].poison * (c.multiply_poison - 1), c.poison_growth_cap)
 if c.has("weak"): s.enemies[target].weak += c.weak
 if c.has("vulnerable"): s.enemies[target].vulnerable += c.vulnerable
 if c.has("heal_recent"): heal_player(mini(c.heal_recent, s.recoverable_hp))
 if c.has("draw"): draw_cards(c.draw)
 if c.kind == "攻击":
  if s.coating > 0:
   var coated_targets: Array = targets if c.has("all_damage") else [target]
   for t in coated_targets: poison_enemy(t, s.coating)
  s.fury += s.fury_engine
 check_outcome()
 if s.phase == "battle" and s.enemies[s.target].hp <= 0: s.target = living()[0]
 return true

func total_thorns() -> int:
 return s.thorns + s.temp_thorns

func heal_player(amount: int) -> void:
 var restored = mini(amount, s.max_hp - s.hp)
 s.hp += restored
 # Any healing pays down the same recent wound budget, including potions.
 s.recoverable_hp = maxi(0, s.recoverable_hp - restored)

func attack_value(e: Dictionary, intent: Dictionary) -> int:
 var damage: int = intent.amount + e.strength
 if e.weak > 0: damage = int(floor(damage * 0.75))
 return maxi(0, damage)

func intent_for(e: Dictionary) -> Dictionary:
 return e.pattern[int(e.step) % e.pattern.size()]

func difficulty_info() -> Dictionary:
 return Data.DIFFICULTIES[s.get("difficulty", "easy")]

func shows_intents() -> bool:
 return difficulty_info().show_intents

func encounter_for(stage: int) -> Array:
 var enemies = Data.encounter(stage)
 var difficulty = difficulty_info()
 for e in enemies:
  e.max_hp = int(ceil(e.max_hp * difficulty.hp_scale))
  e.hp = e.max_hp
  for action in e.pattern:
   action.amount = int(ceil(action.amount * difficulty.action_scale))
 return enemies

func visible_intent_text(e: Dictionary) -> String:
 return intent_text(e) if shows_intents() else "行动未知"

func intent_text(e: Dictionary) -> String:
 var intent = intent_for(e)
 match intent.type:
  "attack":
   var damage = attack_value(e, intent)
   return "连续攻击 %d ×%d（共 %d）" % [damage, intent.hits, damage * intent.hits] if intent.hits > 1 else "单次攻击 %d 伤害" % damage
  "defend": return "防御 +%d 护甲" % intent.amount
  _: return "蓄力 +%d 力量" % intent.amount

func end_turn() -> void:
 if s.phase != "battle": return
 s.recoverable_hp = 0
 s.discard.append_array(s.hand)
 s.hand.clear()
 note("—— 敌方行动 ——")
 for i in range(s.enemies.size()):
  var e: Dictionary = s.enemies[i]
  if e.hp <= 0: continue
  e.block = 0
  if e.poison > 0:
   note("%s 受到 %d 毒素伤害。" % [e.name, e.poison])
   hit_enemy(i, e.poison, true)
   e.poison = maxi(0, e.poison - 1)
  if e.hp <= 0: continue
  var intent = intent_for(e)
  match intent.type:
   "attack":
    var damage = attack_value(e, intent)
    var total = 0
    for _h in range(intent.hits):
     if e.hp <= 0 or s.hp <= 0: break
     var absorbed = mini(s.block, damage)
     s.block -= absorbed
     var loss = mini(s.hp, damage - absorbed)
     s.hp -= loss
     s.recoverable_hp += loss
     total += loss
     if total_thorns() > 0: hit_enemy(i, total_thorns())
    note("%s 发动攻击，你失去 %d 生命。" % [e.name, total])
   "defend":
    e.block += intent.amount
    note("%s 获得 %d 护甲。" % [e.name, intent.amount])
   "buff":
    e.strength += intent.amount
    note("%s 的力量 +%d。" % [e.name, intent.amount])
  e.step += 1
  e.weak = maxi(0, e.weak - 1)
  e.vulnerable = maxi(0, e.vulnerable - 1)
  if s.hp <= 0: break
 check_outcome()
 if s.phase == "battle":
  if s.enemies[s.target].hp <= 0: s.target = living()[0]
  begin_turn()

func check_outcome() -> void:
 if s.phase != "battle": return
 if s.hp <= 0:
  s.phase = "defeat"
  note("冒险结束。可以重新选择路线再来一局。")
 elif living().is_empty():
  s.wins += 1
  var boss: bool = int(s.stage) % 3 == 0
  s.last_gold = (80 if boss else 30) + (20 if has_relic("coin") else 0)
  s.gold += s.last_gold
  if has_relic("flask"): s.hp = mini(s.max_hp, s.hp + 8)
  if boss: s.hp = mini(s.max_hp, s.hp + 15)
  s.reward_cards = roll_cards(3, boss)
  s.boss_reward_taken = false
  s.relic_choices = roll_relics() if boss else []
  s.phase = "victory" if s.stage == 12 else "reward"
  if s.stage == 12: s.trophy = "余烬王冠"
  note("战斗胜利！获得 %d 金币。" % s.last_gold)

func roll_cards(count: int, upgraded: bool = false) -> Array:
 var pool: Array = []
 for id in Data.CARDS:
  if id in ["strike", "guard"]: continue
  if Data.CARDS[id].route == s.route or Data.CARDS[id].route == "neutral": pool.append(id)
 shuffle_list(pool)
 var result: Array = []
 # Guarantee one route card, then offer different cards.
 for id in pool:
  if Data.CARDS[id].route == s.route:
   result.append(id + ("+" if upgraded else ""))
   pool.erase(id)
   break
 for id in pool:
  if result.size() >= count: break
  result.append(id + ("+" if upgraded else ""))
 return result

func roll_relics() -> Array:
 var pool: Array = []
 for id in Data.RELICS:
  if id not in s.relics and not id.ends_with("_core"): pool.append(id)
 shuffle_list(pool)
 return pool.slice(0, 3)

func take_card(index: int) -> void:
 if s.phase != "reward": return
 if index >= 0 and index < s.reward_cards.size(): acquire_card(s.reward_cards[index])
 if int(s.stage) % 3 == 0 and not s.boss_reward_taken:
  s.phase = "relic"
 else: enter_camp()

func take_relic(index: int) -> void:
 if s.phase != "relic" or index < 0 or index >= s.relic_choices.size(): return
 var id: String = s.relic_choices[index]
 s.relics.append(id)
 if id == "heart":
  s.max_hp += 18
  s.hp = mini(s.max_hp, s.hp + 18)
 s.boss_reward_taken = true
 enter_camp()

func enter_camp() -> void:
 s.phase = "camp"
 s.camp_used = false
 s.shop_cards = roll_cards(3)
 s.shop_sold = []
 s.shop_healed = false
 s.shop_removed = false

func rest() -> void:
 if s.phase != "camp" or s.camp_used: return
 var amount = int(ceil(s.max_hp * 0.25))
 s.hp = mini(s.max_hp, s.hp + amount)
 s.camp_used = true
 note("营火休整：恢复 %d 生命。" % amount)

func upgrade_card(index: int) -> bool:
 if s.phase != "camp" or s.camp_used or index < 0 or index >= s.deck.size(): return false
 if s.deck[index].ends_with("+"): return false
 s.deck[index] += "+"
 s.camp_used = true
 note("营火锻造：升级 %s。" % Data.card(s.deck[index]).name)
 return true

func buy_card(index: int) -> bool:
 if s.phase != "camp" or index < 0 or index >= s.shop_cards.size() or index in s.shop_sold or s.gold < 45: return false
 s.gold -= 45
 acquire_card(s.shop_cards[index])
 s.shop_sold.append(index)
 return true

func buy_heal() -> bool:
 if s.phase != "camp" or s.gold < 30 or s.shop_healed or s.hp >= s.max_hp: return false
 s.gold -= 30
 s.hp = mini(s.max_hp, s.hp + 24)
 s.shop_healed = true
 return true

func buy_potion() -> bool:
 if s.phase != "camp" or s.gold < 25 or s.potions >= 3: return false
 s.gold -= 25
 s.potions += 1
 return true

func remove_card(index: int) -> bool:
 if s.phase != "camp" or s.gold < 40 or s.shop_removed or s.deck.size() <= 5 or index < 0 or index >= s.deck.size(): return false
 s.gold -= 40
 s.deck.remove_at(index)
 s.shop_removed = true
 return true

func use_potion() -> bool:
 if s.phase != "battle" or s.potions <= 0 or s.hp >= s.max_hp: return false
 s.potions -= 1
 heal_player(20)
 note("使用治疗药水，恢复 20 生命。")
 return true

func next_stage() -> void:
 if s.phase != "camp": return
 if s.deck.size() < DECK_MIN or s.deck.size() > DECK_LIMIT: return
 s.stage += 1
 start_battle()

func acquire_card(id: String) -> void:
 s.last_acquired_zone = "deck" if s.deck.size() < DECK_LIMIT else "reserve"
 s[s.last_acquired_zone].append(id)

func can_edit_deck() -> bool:
 return s.get("phase", "") in ["camp", "reward", "relic"]

func can_move_card(source: String, index: int, destination: String) -> bool:
 if not can_edit_deck() or source not in ["deck", "reserve"] or destination not in ["deck", "reserve"] or source == destination: return false
 if index < 0 or index >= s[source].size(): return false
 if destination == "deck" and s.deck.size() >= DECK_LIMIT: return false
 if source == "deck" and s.deck.size() <= DECK_MIN: return false
 return true

func move_card(source: String, index: int, destination: String) -> bool:
 if not can_move_card(source, index, destination): return false
 var id: String = s[source][index]
 s[source].remove_at(index)
 s[destination].append(id)
 return true

func save_run(path: String = "user://run_save.json") -> Error:
 var file = FileAccess.open(path, FileAccess.WRITE)
 if file == null: return FileAccess.get_open_error()
 file.store_string(JSON.stringify(s))
 return OK

func load_run(path: String = "user://run_save.json") -> bool:
 if not FileAccess.file_exists(path): return false
 var parsed = normalize_numbers(JSON.parse_string(FileAccess.get_file_as_string(path)))
 if not parsed is Dictionary: return false
 if parsed.get("version", 0) not in [1, 2, 3, 4]: return false
 if not parsed.has("difficulty"): parsed.difficulty = "easy"
 if not Data.DIFFICULTIES.has(parsed.difficulty): return false
 for key in ["route", "stage", "phase", "hp", "max_hp", "deck", "relics", "enemies", "hand", "draw", "discard", "exhaust", "log", "gold"]:
  if not parsed.has(key): return false
 if not Data.ROUTES.has(parsed.route) or parsed.stage < 1 or parsed.stage > 12: return false
 if parsed.phase not in ["battle", "reward", "relic", "camp", "victory", "defeat"]: return false
 if not parsed.has("reserve"): parsed.reserve = []
 if not parsed.reserve is Array: return false
 for id in parsed.deck + parsed.reserve + parsed.hand + parsed.draw + parsed.discard + parsed.exhaust:
  if not id is String or not Data.CARDS.has(id.trim_suffix("+")): return false
 # JSON stores numbers as floats. Indices and serialized shop identifiers must be integers.
 for key in ["stage", "hp", "max_hp", "gold", "potions", "wins", "played", "damage_total", "block", "strength", "thorns", "turn", "target", "energy", "energy_max", "last_gold"]:
  if parsed.has(key): parsed[key] = int(parsed[key])
 for i in range(parsed.get("shop_sold", []).size()): parsed.shop_sold[i] = int(parsed.shop_sold[i])
 s = parsed
 # Preserve old saves and the current battle's already-shuffled piles.
 # Oversized legacy decks are capped for all future battles, without deleting cards.
 while s.deck.size() > DECK_LIMIT: s.reserve.push_front(s.deck.pop_back())
 for key in ["fury", "fury_engine", "coating", "next_block", "next_draw", "next_energy", "retain_cap", "temp_thorns", "recoverable_hp"]:
  if not s.has(key): s[key] = 0
 # Former one-use skills become recyclable; preserve every copy and upgrade.
 for i in range(s.exhaust.size() - 1, -1, -1):
  if Data.card(s.exhaust[i]).kind != "能力":
   s.discard.append(s.exhaust[i])
   s.exhaust.remove_at(i)
 if not s.has("last_acquired_zone"): s.last_acquired_zone = "deck"
 s.version = 4
 rng.randomize()
 return true

func normalize_numbers(value: Variant) -> Variant:
 # This schema uses whole numbers only; JSON decodes every number as a float.
 if value is float: return int(value)
 if value is Array:
  for i in range(value.size()): value[i] = normalize_numbers(value[i])
 elif value is Dictionary:
  for key in value: value[key] = normalize_numbers(value[key])
 return value
