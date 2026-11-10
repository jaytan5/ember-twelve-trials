extends RefCounted
## Serializable game rules, deliberately independent of the presentation.
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
const DeckSystem = preload("res://Game/Scripts/CardSystem/DeckSystem.gd")
const CardEffects = preload("res://Game/Scripts/CardSystem/CardEffects.gd")
const EnemySystem = preload("res://Game/Scripts/EnemySystem/EnemySystem.gd")
const SaveSystem = preload("res://Game/Scripts/SaveSystem/SaveSystem.gd")
const RewardSystem = preload("res://Game/Scripts/LevelSystem/RewardSystem.gd")
const DECK_LIMIT = 30
const DECK_MIN = 15
const POTION_LIMIT = 2
var s: Dictionary = {}
var rng = RandomNumberGenerator.new()
var capture_combat_events = false
var combat_events: Array = []

func record_combat_event(target: int, before: int, after: int, kind: String) -> void:
 if capture_combat_events:
  combat_events.append({"target":target, "before":before, "after":after, "amount":absi(after - before), "kind":kind})

func new_run(route: String, seed_value: int = 0, difficulty: String = "easy") -> void:
 rng.randomize()
 if seed_value != 0: rng.seed = seed_value
 var r: Dictionary = Data.ROUTES[route]
 s = {"version":8, "route":route, "difficulty":difficulty if Data.DIFFICULTIES.has(difficulty) else "easy", "stage":1, "phase":"battle", "hp":r.hp, "max_hp":r.hp,
 "gold":65, "deck":Array(Data.CONFIG.initial_common).duplicate(),
 "relics":[r.relic], "potions":2, "wins":0, "played":0, "damage_total":0, "log":[],
 "reward_cards":[], "relic_choices":[], "shop_cards":[], "shop_sold":[], "shop_healed":false,
 "last_gold":0, "boss_reward_taken":false, "camp_used":false, "trophy":"", "reserve":[], "last_acquired_zone":"deck"}
 s.deck.append_array(r.cards)
 start_battle()

func note(message: String) -> void:
 s.log.append(message)
 while s.log.size() > 35: s.log.pop_front()

func shuffle_list(items: Array) -> void:
 DeckSystem.shuffle(items, rng)

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
 s.strength = relic_bonus("start_strength")
 s.thorns = relic_bonus("start_thorns")
 s.barrier = 0
 s.barrier_reflects = []
 s.lifesteal = 0
 s.next_lifesteal = 0
 s.low_hp_crit = 0
 s.low_hp_crit_threshold = 30
 s.next_strength = 0
 s.temporary_strength = 0
 s.coating = 0
 s.next_block = 0
 s.next_draw = 0
 s.next_energy = 0
 s.retain_cap = 0
 s.temp_thorns = 0
 s.recoverable_hp = 0
 s.keep_block = false
 s.first_poison = true
 s.fate_triggered = false
 s.turn_cards_played = 0
 s.turn = 0
 s.target = 0
 s.log = []
 note("第 %d 关 · %s" % [s.stage, Data.STAGE_NAMES[s.stage - 1]])
 begin_turn()
 capture_battle_checkpoint()

func capture_battle_checkpoint() -> void:
 s.erase("battle_checkpoint")
 var opening = s.duplicate(true)
 s.battle_checkpoint = {"state":opening, "rng_state":str(rng.state)}

func can_retry_battle() -> bool:
 return s.get("phase", "") == "defeat" and difficulty_info().allow_retry

func retry_battle() -> bool:
 if not can_retry_battle(): return false
 var checkpoint: Dictionary = s.get("battle_checkpoint", {})
 if not checkpoint.is_empty():
  s = checkpoint.state.duplicate(true)
  rng.state = int(checkpoint.rng_state)
  s.battle_checkpoint = checkpoint.duplicate(true)
 else:
  # Older saves have no opening snapshot. Keep owned resources and restart at full HP.
  s.hp = s.max_hp
  start_battle()
 return true

func begin_turn() -> void:
 if not s.keep_block: s.block = mini(s.block, s.retain_cap)
 s.keep_block = false
 s.temp_thorns = 0
 s.block += relic_bonus("turn_block")
 if s.turn == 0: s.block += relic_bonus("start_block")
 s.block += s.next_block
 s.next_block = 0
 s.energy_max = 3 + relic_bonus("turn_energy")
 s.energy = s.energy_max + s.next_energy
 s.next_energy = 0
 s.turn += 1
 s.turn_cards_played = 0
 s.lifesteal = s.next_lifesteal
 s.next_lifesteal = 0
 s.strength -= s.temporary_strength
 s.temporary_strength = s.next_strength
 s.strength += s.temporary_strength
 s.next_strength = 0
 draw_cards((Data.CONFIG.initial_hand if s.turn == 1 else Data.CONFIG.turn_draw) + relic_bonus("turn_draw") + s.next_draw)
 s.next_draw = 0
 if not s.fate_triggered and s.hp > 0 and s.hp * 2 < s.max_hp and relic_bonus("low_hp_energy") > 0:
  s.fate_triggered = true
  draw_cards(relic_bonus("low_hp_draw"))
  s.energy += relic_bonus("low_hp_energy")
  note("逆命护符：抽取 2 张牌，获得 3 点能量（本场已触发）。")
 note("回合 %d：抽牌，恢复能量。" % s.turn)

func resolve_combo_relic() -> void:
 var damage = relic_bonus("combo_damage")
 if damage <= 0 or s.hp <= 0 or s.turn_cards_played <= 0 or s.turn_cards_played % 2 != 0 or s.turn_cards_played > 6: return
 var targets = living()
 if targets.is_empty(): return
 var target: int = targets[rng.randi_range(0, targets.size() - 1)]
 note("连击齿轮：第 %d 张牌，对 %s 造成 %d 点伤害。" % [s.turn_cards_played, s.enemies[target].name, damage])
 hit_enemy(target, damage)

func draw_cards(amount: int) -> void:
 DeckSystem.draw(s, amount, Data.CONFIG.hand_limit, rng)

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
 var before: int = e.hp
 var damage = maxi(0, amount)
 if damage > 0 and s.low_hp_crit > 0 and s.hp * 100 < s.max_hp * s.low_hp_crit_threshold and rng.randf() < s.low_hp_crit / 100.0:
  damage *= 2
  note("暴击！伤害翻倍。")
 if not direct and e.vulnerable > 0: damage = int(ceil(damage * 1.2))
 if not direct:
  var absorbed = mini(e.block, damage)
  e.block -= absorbed
  damage -= absorbed
 var dealt = mini(e.hp, damage)
 e.hp -= dealt
 s.damage_total += dealt
 if amount > 0: record_combat_event(index, before, e.hp, "damage" if dealt > 0 else "blocked")
 if dealt > 0 and s.lifesteal > 0 and s.hp > 0:
  var restored = mini(int(floor(dealt * s.lifesteal / 100.0)), s.max_hp - s.hp)
  heal_player(restored)
  if restored > 0: note("吸血恢复 %d 生命。" % restored)
 if e.hp <= 0: note("击败 %s！" % e.name)

func poison_enemy(index: int, amount: int) -> void:
 if s.enemies[index].hp <= 0: return
 if s.first_poison and relic_bonus("first_poison") > 0:
  amount += relic_bonus("first_poison")
  s.first_poison = false
 s.enemies[index].poison += amount

func can_play(index: int) -> bool:
 if s.phase != "battle" or index < 0 or index >= s.hand.size(): return false
 var c = Data.card(s.hand[index])
 if s.energy < energy_cost(c): return false
 if c.has("poison_cost"):
  if s.target < 0 or s.target >= s.enemies.size(): return false
  if s.enemies[s.target].hp <= 0 or s.enemies[s.target].poison < c.poison_cost: return false
 return not living().is_empty()

func play(index: int) -> bool:
 return CardEffects.play(self, index)

func total_thorns() -> int:
 return s.thorns + s.temp_thorns

func heal_player(amount: int) -> void:
 var before: int = s.hp
 var restored = mini(amount, s.max_hp - s.hp)
 s.hp += restored
 if restored > 0: record_combat_event(-1, before, s.hp, "heal")
 # Any healing pays down the same recent wound budget, including potions.
 s.recoverable_hp = maxi(0, s.recoverable_hp - restored)

func attack_value(e: Dictionary, intent: Dictionary) -> int:
 var damage: int = intent.amount + e.strength
 if e.weak > 0: damage = int(floor(damage * 0.7))
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
 if e.get("frozen", 0) > 0: return "冰冻 · 本次无法行动"
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
  # Unplayed cards remain in hand across turns.
 note("—— 敌方行动 ——")
 EnemySystem.resolve_turn(self)
 check_outcome()
 if s.phase == "battle":
  if s.enemies[s.target].hp <= 0: s.target = living()[0]
  begin_turn()


func check_outcome() -> void:
 if s.phase != "battle": return
 if s.hp <= 0:
  s.phase = "defeat"
  note("战败。可以重新开始本小关，或重新选择路线。" if difficulty_info().allow_retry else "传奇冒险结束。只能从第一关重新开始。")
 elif living().is_empty():
  s.wins += 1
  var boss: bool = int(s.stage) % 3 == 0
  s.last_gold = (Data.REWARD.boss_gold if boss else Data.REWARD.normal_gold) + relic_bonus("victory_gold")
  s.gold += s.last_gold
  var hp_before_reward: int = s.hp
  s.hp = mini(s.max_hp, s.hp + relic_bonus("victory_heal"))
  if boss: s.hp = mini(s.max_hp, s.hp + Data.REWARD.boss_heal)
  if s.hp > hp_before_reward: record_combat_event(-1, hp_before_reward, s.hp, "heal")
  s.reward_cards = roll_cards(Data.REWARD.choices, boss)
  s.boss_reward_taken = false
  s.relic_choices = roll_relics() if boss else []
  s.phase = "victory" if s.stage == 12 else "reward"
  if s.stage == 12: s.trophy = "余烬王冠"
  note("战斗胜利！获得 %d 金币。" % s.last_gold)

func roll_cards(count: int, upgraded: bool = false) -> Array:
 return RewardSystem.roll_cards(self, count, upgraded)

func roll_relics() -> Array:
 var pool: Array = []
 for id in Data.RELICS:
  if id not in s.relics and not Data.RELICS[id].starter: pool.append(id)
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
 var extra_hp = int(Data.RELICS[id].effects.get("max_hp", 0))
 s.max_hp += extra_hp
 s.hp = mini(s.max_hp, s.hp + extra_hp)
 s.boss_reward_taken = true
 enter_camp()

func enter_camp() -> void:
 s.phase = "camp"
 s.camp_used = false
 s.shop_cards = roll_cards(Data.REWARD.choices)
 s.shop_sold = []
 s.shop_healed = false

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
 if s.phase != "camp" or index < 0 or index >= s.shop_cards.size() or index in s.shop_sold or s.gold < Data.REWARD.shop_price: return false
 s.gold -= Data.REWARD.shop_price
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
 if s.phase != "camp" or s.gold < 25 or s.potions >= POTION_LIMIT: return false
 s.gold -= 25
 s.potions += 1
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
 var storage = SaveSystem.new()
 storage.s = s
 storage.rng.state = rng.state
 return storage.save_run(path)

func load_run(path: String = "user://run_save.json") -> bool:
 var storage = SaveSystem.new()
 if not storage.load_run(path): return false
 s = storage.s
 rng.state = storage.rng.state
 return true

func normalize_numbers(value: Variant) -> Variant:
 return SaveSystem.new().normalize_numbers(value)

func relic_bonus(effect: String) -> int:
 var amount = 0
 for id in s.relics:
  var effects: Dictionary = Data.RELICS[id].effects
  amount += int(effects.get(effect, 0))
  amount += int(effects.get("route_bonuses", {}).get(s.route, {}).get(effect, 0))
 return amount

func energy_cost(c: Dictionary) -> int:
 return s.energy if c.cost < 0 else c.cost

func take_player_damage(amount: int, bypass_armor: bool = false, attacker: int = -1) -> int:
 if amount <= 0: return 0
 var before: int = s.hp
 if s.barrier > 0:
  s.barrier -= 1
  var reflect = int(s.barrier_reflects.pop_front()) if not s.barrier_reflects.is_empty() else 0
  note("金钟罩抵挡了 %d 点伤害。" % amount)
  record_combat_event(-1, before, before, "blocked")
  if reflect > 0 and attacker >= 0 and attacker < s.enemies.size() and s.enemies[attacker].hp > 0:
   var reflected = int(floor(amount * reflect / 100.0))
   note("金钟罩反弹 %d 点伤害。" % reflected)
   hit_enemy(attacker, reflected)
  return 0
 var absorbed = 0 if bypass_armor else mini(s.block, amount)
 s.block -= absorbed
 var loss = mini(s.hp, amount - absorbed)
 s.hp -= loss
 record_combat_event(-1, before, s.hp, "damage" if loss > 0 else "blocked")
 return loss
