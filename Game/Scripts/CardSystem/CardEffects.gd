extends RefCounted
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")

static func play(run, index: int) -> bool:
 if not run.can_play(index): return false
 var id: String = run.s.hand[index]
 run.s.hand.remove_at(index)
 resolve_card(run, id, false, {"remaining":64})
 return true

static func resolve_card(run, id: String, free: bool, budget: Dictionary) -> void:
 var c = Data.card(id)
 var targets = run.living()
 if run.s.phase != "battle" or targets.is_empty():
  run.s.discard.append(id)
  return
 if run.s.target not in targets: run.s.target = targets[0]
 var target: int = run.s.target
 if (c.has("poison_cost") and run.s.enemies[target].poison < c.poison_cost) or (c.get("requires_poison", false) and run.s.enemies[target].poison <= 0):
  run.s.discard.append(id)
  run.note("%s：目标毒素不足，自动使用失败，进入弃牌堆。" % c.name)
  return
 if c.has("poison_cost"): run.s.enemies[target].poison -= c.poison_cost
 var spent = run.energy_cost(c)
 if not free: run.s.energy -= spent
 if c.get("store_energy", false): run.s.next_energy += spent
 if c.kind == "能力" or c.get("exhaust", false): run.s.exhaust.append(id)
 else: run.s.discard.append(id)
 run.s.played += 1
 run.s.turn_cards_played += 1
 run.note("%s %s%s。" % ["自动使用" if free else "打出", c.name, " → " + run.s.enemies[target].name if c.get("target", false) else ""])
 if c.has("self_damage"): run.take_player_damage(c.self_damage, true)
 if run.s.hp <= 0:
  run.s.phase = "defeat"
  run.note("自伤耗尽了最后的生命。")
  return
 if c.has("block"): run.s.block += c.block
 
 if c.has("thorns"): run.s.thorns += c.thorns
 if c.has("temp_thorns"): run.s.temp_thorns += c.temp_thorns
 if c.has("coating"): run.s.coating += c.coating
 if c.has("next_lifesteal"): run.s.next_lifesteal = maxi(run.s.next_lifesteal, c.next_lifesteal)
 if c.has("low_hp_crit"):
  run.s.low_hp_crit = maxi(run.s.low_hp_crit, c.low_hp_crit)
  run.s.low_hp_crit_threshold = maxi(run.s.low_hp_crit_threshold, c.low_hp_crit_threshold)
 if c.has("next_strength"): run.s.next_strength += c.next_strength
 if c.has("turn_strength"):
  run.s.turn_strength += c.turn_strength
  run.s.strength += c.turn_strength
 if c.has("lost_hp_next_strength"):
  var gained = int(floor((run.s.max_hp - run.s.hp) * c.lost_hp_next_strength / 100.0))
  run.s.next_strength += gained
  run.note("背水之力：按当前伤势，下回合临时力量 +%d。" % gained)
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
 if c.has("stun"): run.s.enemies[target].stunned = maxi(run.s.enemies[target].get("stunned", 0), c.stun)
 if c.has("mark_crit"):
  run.s.enemies[target].mark_crit = maxi(run.s.enemies[target].get("mark_crit", 0), c.mark_crit)
  run.s.enemies[target].mark_turns = maxi(run.s.enemies[target].get("mark_turns", 0), c.mark_turns)
 if c.has("bomb_damage"):
  run.s.bombs.append({"target":target, "turn":run.s.turn + 1, "damage":c.bomb_damage})
  run.note("发条炸弹已锁定 %s，下回合结束时爆炸。" % run.s.enemies[target].name)
 if c.has("armor_damage"):
  var removed: int = run.s.enemies[target].block
  run.s.enemies[target].block = 0
  run.hit_enemy(target, int(floor(removed * c.armor_damage)), true, c.kind == "攻击")
 if c.has("consume_block_damage"):
  var armor: int = run.s.block
  run.s.block = 0
  run.hit_enemy(target, int(floor(armor * c.consume_block_damage / 100.0)) + run.s.strength, false, true)
 if c.has("damage"):
  var damage: int = c.damage + run.s.strength + (run.s.block if c.get("block_damage", false) else 0)
  damage += run.total_thorns() * int(c.get("thorns_attack", 0))
  if c.has("poison_damage_cap"): damage += mini(run.s.enemies[target].poison, c.poison_damage_cap)
  for _hit in range(c.get("hits", 1)): run.hit_enemy(target, damage, false, c.kind == "攻击")
 if c.has("lost_hp_damage"):
  var damage = int(floor((run.s.max_hp - run.s.hp) * c.lost_hp_damage / 100.0)) + run.s.strength
  run.hit_enemy(target, damage, false, c.kind == "攻击")
 if c.has("random_damage"):
  targets = []
  for _hit in range(c.hits):
   var available = run.living()
   if available.is_empty(): break
   var random_target: int = available[run.rng.randi_range(0, available.size() - 1)]
   if random_target not in targets: targets.append(random_target)
   run.hit_enemy(random_target, c.random_damage + run.s.strength, false, c.kind == "攻击")
 if c.has("all_damage"):
  for t in targets: run.hit_enemy(t, c.all_damage + run.s.strength + int(floor(run.s.block * c.get("block_ratio", 0.0))), false, c.kind == "攻击")
 if c.has("all_thorns_damage"):
  for t in targets: run.hit_enemy(t, run.total_thorns() * c.all_thorns_damage)
 if c.has("poison_burst"):
  var stacks: int = run.s.enemies[target].poison
  run.s.enemies[target].poison = 0
  run.hit_enemy(target, stacks * c.poison_burst, true)
  run.note("毒爆消耗 %d 层毒素。" % stacks)
 if c.get("trigger_poison", false):
  var stacks: int = run.s.enemies[target].poison
  run.hit_enemy(target, stacks, true)
  if not c.get("preserve_poison", false): run.s.enemies[target].poison = maxi(0, stacks - 1)
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
 if c.has("autoplay") and run.s.phase == "battle":
  # The resolving copy is still in play. Do not shuffle it into its own draws.
  var in_discard = c.kind != "能力" and not c.get("exhaust", false)
  if in_discard: run.s.discard.remove_at(run.s.discard.rfind(id))
  autoplay(run, c.autoplay, budget)
  if in_discard: run.s.discard.append(id)

static func autoplay(run, amount: int, budget: Dictionary) -> void:
 # Reserve the entire draw before resolving: draws in the first card cannot steal
 # the remaining automatic cards, and a full hand does not block automatic play.
 var pending: Array = []
 for _i in range(amount):
  if run.s.draw.is_empty():
   if run.s.discard.is_empty(): break
   run.s.draw = run.s.discard.duplicate()
   run.s.discard.clear()
   run.shuffle_list(run.s.draw)
  pending.append(run.s.draw.pop_back())
 for id in pending:
  if run.s.phase != "battle" or budget.remaining <= 0:
   run.s.discard.append(id)
   if budget.remaining <= 0: run.note("连续自动使用达到本次上限，剩余卡牌进入弃牌堆。")
   continue
  budget.remaining -= 1
  resolve_card(run, id, true, budget)

