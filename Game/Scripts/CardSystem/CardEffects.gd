extends RefCounted
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")

static func play(run, index: int) -> bool:
 if not run.can_play(index): return false
 var id: String = run.s.hand[index]
 var c = Data.card(id)
 var targets = run.living()
 if targets.is_empty(): return false
 if run.s.target not in targets: run.s.target = targets[0]
 var target: int = run.s.target
 if c.has("poison_cost"): run.s.enemies[target].poison -= c.poison_cost
 var spent = run.energy_cost(c)
 run.s.energy -= spent
 if c.get("store_energy", false): run.s.next_energy += spent + int(c.get("stored_bonus", 0))
 run.s.hand.remove_at(index)
 if c.kind == "能力" or c.get("exhaust", false): run.s.exhaust.append(id)
 else: run.s.discard.append(id)
 run.s.played += 1
 run.s.turn_cards_played += 1
 run.note("打出 %s%s。" % [c.name, " → " + run.s.enemies[target].name if c.get("target", false) else ""])
 if c.has("self_damage"): run.take_player_damage(c.self_damage, true)
 if run.s.hp <= 0:
  run.s.phase = "defeat"
  run.note("自伤耗尽了最后的生命。")
  return true
 if c.has("block"): run.s.block += c.block
 
 if c.has("thorns"): run.s.thorns += c.thorns
 if c.has("temp_thorns"): run.s.temp_thorns += c.temp_thorns
 if c.has("coating"): run.s.coating += c.coating
 if c.has("next_lifesteal"): run.s.next_lifesteal = maxi(run.s.next_lifesteal, c.next_lifesteal)
 if c.has("low_hp_crit"):
  run.s.low_hp_crit = maxi(run.s.low_hp_crit, c.low_hp_crit)
  run.s.low_hp_crit_threshold = maxi(run.s.low_hp_crit_threshold, c.low_hp_crit_threshold)
 if c.has("next_strength"): run.s.next_strength += c.next_strength
 if c.has("next_block"): run.s.next_block += c.next_block
 if c.has("next_draw"): run.s.next_draw += c.next_draw
 if c.has("next_energy"): run.s.next_energy += c.next_energy
 if c.has("energy"): run.s.energy += c.energy
 if c.has("retain_cap"): run.s.retain_cap = maxi(run.s.retain_cap, c.retain_cap)
 if c.has("barrier"):
  run.s.barrier += c.barrier
  for _charge in range(c.barrier): run.s.barrier_reflects.append(int(c.get("barrier_reflect", 0)))
 if c.has("freeze_all"):
  for t in targets: run.s.enemies[t].frozen = maxi(run.s.enemies[t].get("frozen", 0), c.freeze_all)
 if c.has("armor_damage"):
  var removed: int = run.s.enemies[target].block
  run.s.enemies[target].block = 0
  run.hit_enemy(target, int(floor(removed * c.armor_damage)), true)
 if c.has("damage"):
  var damage: int = c.damage + run.s.strength + (run.s.block if c.get("block_damage", false) else 0)
  for _hit in range(c.get("hits", 1)): run.hit_enemy(target, damage)
 if c.has("lost_hp_damage"):
  var damage = int(floor((run.s.max_hp - run.s.hp) * c.lost_hp_damage / 100.0)) + run.s.strength
  run.hit_enemy(target, damage)
 if c.has("random_damage"):
  targets = []
  for _hit in range(c.hits):
   var available = run.living()
   if available.is_empty(): break
   var random_target: int = available[run.rng.randi_range(0, available.size() - 1)]
   if random_target not in targets: targets.append(random_target)
   run.hit_enemy(random_target, c.random_damage + run.s.strength)
 if c.has("all_damage"):
  for t in targets: run.hit_enemy(t, c.all_damage + run.s.strength + int(floor(run.s.block * c.get("block_ratio", 0.0))))
 if c.has("all_thorns_damage"):
  for t in targets: run.hit_enemy(t, run.total_thorns() * c.all_thorns_damage)
 if c.has("poison_burst"):
  var stacks: int = run.s.enemies[target].poison
  run.s.enemies[target].poison = 0
  run.hit_enemy(target, stacks * c.poison_burst, true)
  run.note("毒爆消耗 %d 层毒素。" % stacks)
 if c.has("poison"): run.poison_enemy(target, c.poison)
 if c.has("all_poison"):
  for t in targets: run.poison_enemy(t, c.all_poison)
 if c.has("multiply_poison"):
  run.s.enemies[target].poison += mini(run.s.enemies[target].poison * (c.multiply_poison - 1), c.poison_growth_cap)
 if c.has("weak"): run.s.enemies[target].weak = maxi(run.s.enemies[target].weak, c.weak)
 if c.has("vulnerable"): run.s.enemies[target].vulnerable = maxi(run.s.enemies[target].vulnerable, c.vulnerable)
 if c.has("strength"): run.s.strength += c.strength
 if c.has("heal"): run.heal_player(c.heal)
 if c.has("heal_recent"): run.heal_player(mini(c.heal_recent, run.s.recoverable_hp))
 if c.has("draw"): run.draw_cards(c.draw)
 if c.kind == "攻击":
  if run.s.coating > 0:
   var coated_targets: Array = targets if c.has("all_damage") or c.has("random_damage") else [target]
   for t in coated_targets: run.poison_enemy(t, run.s.coating)
 if c.has("self_damage_unless_kill") and run.s.enemies[target].hp > 0:
  run.take_player_damage(c.self_damage_unless_kill, true)
 run.resolve_combo_relic()
 run.check_outcome()
 if run.s.phase == "battle" and run.s.enemies[run.s.target].hp <= 0: run.s.target = run.living()[0]
 return true

