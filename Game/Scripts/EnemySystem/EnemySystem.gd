extends RefCounted

static func resolve_turn(run) -> void:
 for i in range(run.s.enemies.size()):
  var e: Dictionary = run.s.enemies[i]
  if e.hp <= 0: continue
  e.block = 0
  if e.poison > 0:
   run.note("%s 受到 %d 毒素伤害。" % [e.name, e.poison])
   run.hit_enemy(i, e.poison, true)
   e.poison = maxi(0, e.poison - 1)
  if e.hp <= 0: continue
  if e.get("frozen", 0) > 0:
   e.frozen -= 1
   run.note("%s 被冰冻，跳过本次行动。" % e.name)
   continue
  var intent = run.intent_for(e)
  match intent.type:
   "attack":
    var damage = run.attack_value(e, intent)
    var total = 0
    for _h in range(intent.hits):
     if e.hp <= 0 or run.s.hp <= 0: break
     var loss = run.take_player_damage(damage)
     run.s.recoverable_hp += loss
     total += loss
     if run.total_thorns() > 0: run.hit_enemy(i, run.total_thorns())
    run.note("%s 发动攻击，你失去 %d 生命。" % [e.name, total])
   "defend":
    e.block += intent.amount
    run.record_combat_event(i, e.hp, e.hp, "guard")
    run.note("%s 获得 %d 护甲。" % [e.name, intent.amount])
   "buff":
    e.strength += intent.amount
    run.record_combat_event(i, e.hp, e.hp, "buff")
    run.note("%s 的力量 +%d。" % [e.name, intent.amount])
  e.step += 1
  if run.s.hp <= 0: break
