extends RefCounted
## All balance and content definitions live here. No artwork is required.

const DIFFICULTIES = {
 "easy":{"name":"简单", "show_intents":true, "hp_scale":1.0, "action_scale":1.0,
 "desc":"显示敌人下次的攻击伤害、连击次数、防御与蓄力；敌人数值为基础值。"},
 "normal":{"name":"中等", "show_intents":false, "hp_scale":1.0, "action_scale":1.0,
 "desc":"隐藏敌人下一步行动及伤害预告；敌人数值为基础值。"},
 "hard":{"name":"困难", "show_intents":false, "hp_scale":1.35, "action_scale":1.25,
 "desc":"隐藏行动预告；敌人生命 +35%，攻击、防御和蓄力数值 +25%（向上取整）。"}
}

const ROUTES = {
 "venom": {"name":"蚀毒", "tag":"叠毒侵蚀 / 毒层引爆", "color":"75cbb3", "hp":76,
 "desc":"叠毒与淬毒持续侵蚀，或消耗毒层引爆、回能。\n初始遗物：每场战斗首次施毒额外 +2 层。",
 "cards":["sting", "sting", "toxic_guard", "catalyst"], "relic":"venom_core"},
 "bastion": {"name":"铁壁", "tag":"护甲转伤 / 荆棘反击", "color":"85b5f5", "hp":88,
 "desc":"叠甲后盾击，或累积反伤、释放反击风暴。\n初始遗物：每个玩家回合开始获得 3 护甲。",
 "cards":["fortify", "fortify", "shield_bash", "hold"], "relic":"iron_core"},
 "fury": {"name":"狂刃", "tag":"力量连击 / 狂怒爆发", "color":"f08e85", "hp":82,
 "desc":"力量强化多段攻击；嗜战积攒狂怒，怒斩收尾。\n初始遗物：每场战斗开始获得 1 点力量。",
 "cards":["cleave", "cleave", "rage", "execute"], "relic":"blade_core"}
}

# Card descriptions are generated from numerical definitions so upgrades stay accurate.
const CARDS = {
 "strike":{"name":"斩击","kind":"攻击","route":"neutral","cost":1,"damage":7,"target":true,"upgrade":{"damage":10}},
 "guard":{"name":"防守","kind":"技能","route":"neutral","cost":1,"block":6,"upgrade":{"block":9}},
 "focus":{"name":"战术调整","kind":"技能","route":"neutral","cost":1,"draw":2,"upgrade":{"draw":3}},
 "sting":{"name":"毒刃","kind":"攻击","route":"venom","cost":1,"damage":3,"poison":3,"target":true,"upgrade":{"damage":5,"poison":4}},
 "toxic_guard":{"name":"毒雾屏障","kind":"技能","route":"venom","cost":1,"block":5,"all_poison":1,"upgrade":{"block":7,"all_poison":2}},
 "catalyst":{"name":"催化","kind":"技能","route":"venom","cost":2,"multiply_poison":2,"poison_growth_cap":12,"target":true,"upgrade":{"poison_growth_cap":18}},
 "plague":{"name":"疫潮","kind":"技能","route":"venom","cost":3,"all_poison":8,"upgrade":{"all_poison":11}},
 "venom_dart":{"name":"蚀骨飞针","kind":"攻击","route":"venom","cost":0,"damage":1,"poison":1,"target":true,"upgrade":{"damage":2}},
 "leech":{"name":"汲取","kind":"攻击","route":"venom","cost":2,"damage":11,"heal_recent":4,"target":true,"upgrade":{"damage":15,"heal_recent":6}},
 "fortify":{"name":"重盾","kind":"技能","route":"bastion","cost":1,"block":10,"upgrade":{"block":13}},
 "shield_bash":{"name":"盾击","kind":"攻击","route":"bastion","cost":1,"block_damage":true,"damage":2,"target":true,"upgrade":{"damage":4}},
 "hold":{"name":"固守","kind":"能力","route":"bastion","cost":2,"block":8,"retain_cap":12,"exhaust":true,"upgrade":{"block":10,"retain_cap":16}},
 "rampart":{"name":"钢铁壁垒","kind":"技能","route":"bastion","cost":3,"block":30,"upgrade":{"block":38}},
 "counter":{"name":"反震","kind":"能力","route":"bastion","cost":1,"thorns":2,"exhaust":true,"upgrade":{"thorns":3}},
 "shield_draw":{"name":"整备","kind":"技能","route":"bastion","cost":1,"block":4,"draw":1,"upgrade":{"block":6}},
 "cleave":{"name":"双连斩","kind":"攻击","route":"fury","cost":1,"damage":3,"hits":2,"target":true,"upgrade":{"damage":4}},
 "rage":{"name":"战意","kind":"能力","route":"fury","cost":1,"strength":2,"exhaust":true,"upgrade":{"strength":3}},
 "execute":{"name":"破阵","kind":"攻击","route":"fury","cost":3,"damage":26,"target":true,"upgrade":{"damage":34}},
 "whirlwind":{"name":"旋风斩","kind":"攻击","route":"fury","cost":2,"all_damage":8,"upgrade":{"all_damage":11}},
 "bloodlust":{"name":"燃血","kind":"技能","route":"fury","cost":0,"self_damage":5,"energy":1,"upgrade":{"self_damage":4}},
 "triple":{"name":"疾风三连","kind":"攻击","route":"fury","cost":2,"damage":4,"hits":3,"target":true,"upgrade":{"damage":5}},
 "expose":{"name":"识破","kind":"攻击","route":"neutral","cost":1,"damage":4,"vulnerable":2,"target":true,"upgrade":{"damage":6}},
 "disarm":{"name":"卸力","kind":"技能","route":"neutral","cost":1,"block":3,"weak":2,"target":true,"upgrade":{"block":5}},
 "quick":{"name":"快斩","kind":"攻击","route":"neutral","cost":0,"damage":2,"target":true,"upgrade":{"damage":3}},
 "insight":{"name":"洞察","kind":"技能","route":"neutral","cost":2,"draw":4,"upgrade":{"draw":5}},
 "mend":{"name":"急救","kind":"技能","route":"neutral","cost":2,"block":4,"heal_recent":8,"upgrade":{"block":6,"heal_recent":11}},
 "sweep":{"name":"横扫","kind":"攻击","route":"neutral","cost":2,"all_damage":7,"upgrade":{"all_damage":10}},
 "tactical_strike":{"name":"试探斩","kind":"攻击","route":"neutral","cost":1,"damage":4,"draw":1,"target":true,"upgrade":{"damage":6}},
 "brace":{"name":"稳步推进","kind":"技能","route":"neutral","cost":1,"block":3,"draw":1,"upgrade":{"block":5}},
 "first_aid":{"name":"应急包扎","kind":"技能","route":"neutral","cost":1,"block":3,"heal_recent":3,"upgrade":{"block":4,"heal_recent":5}},
 "rally":{"name":"振作","kind":"技能","route":"neutral","cost":1,"next_energy":2,"upgrade":{"next_energy":3}},
 "feint":{"name":"佯攻","kind":"攻击","route":"neutral","cost":1,"damage":3,"weak":2,"target":true,"upgrade":{"damage":5}},
 "sunder":{"name":"碎甲击","kind":"攻击","route":"neutral","cost":3,"damage":24,"break_block":true,"target":true,"upgrade":{"damage":30}},
 "prepare":{"name":"未雨绸缪","kind":"技能","route":"neutral","cost":3,"block":16,"next_block":10,"next_draw":1,"upgrade":{"block":20,"next_block":14}},
 "detonate":{"name":"毒爆","kind":"技能","route":"venom","cost":3,"poison_burst":3,"target":true,"upgrade":{"poison_burst":4}},
 "recycle":{"name":"毒素回收","kind":"技能","route":"venom","cost":0,"poison_cost":4,"next_energy":1,"target":true,"upgrade":{"next_energy":2}},
 "corrosion":{"name":"腐蚀","kind":"技能","route":"venom","cost":1,"poison":3,"weak":1,"target":true,"upgrade":{"poison":4,"weak":2}},
 "coating":{"name":"淬毒","kind":"能力","route":"venom","cost":2,"coating":1,"exhaust":true,"upgrade":{"coating":2}},
 "thorn_armor":{"name":"棘甲","kind":"技能","route":"bastion","cost":1,"block":6,"temp_thorns":2,"upgrade":{"block":8,"temp_thorns":3}},
 "thorn_growth":{"name":"荆棘生长","kind":"能力","route":"bastion","cost":2,"block":6,"thorns":4,"exhaust":true,"upgrade":{"block":8,"thorns":5}},
 "thorn_storm":{"name":"反击风暴","kind":"技能","route":"bastion","cost":3,"all_thorns_damage":4,"upgrade":{"all_thorns_damage":5}},
 "shield_charge":{"name":"钢甲冲撞","kind":"攻击","route":"bastion","cost":2,"all_damage":3,"block_ratio":0.5,"upgrade":{"all_damage":5}},
 "battle_trance":{"name":"嗜战","kind":"能力","route":"fury","cost":2,"fury_engine":1,"exhaust":true,"upgrade":{"fury_engine":2}},
 "warcry":{"name":"怒吼","kind":"技能","route":"fury","cost":1,"block":4,"fury":2,"upgrade":{"block":6,"fury":3}},
 "rage_slash":{"name":"怒斩","kind":"攻击","route":"fury","cost":2,"damage":6,"fury_burst":3,"target":true,"upgrade":{"damage":9,"fury_burst":4}},
 "blood_charge":{"name":"血性冲锋","kind":"攻击","route":"fury","cost":1,"damage":5,"fury":1,"target":true,"upgrade":{"damage":7,"fury":2}}
}

const RELICS = {
 "venom_core":{"name":"青蛇牙", "desc":"每场战斗首次施毒时，额外施加 2 层毒素。"},
 "iron_core":{"name":"守城徽记", "desc":"每个玩家回合开始时获得 3 护甲。"},
 "blade_core":{"name":"赤刃印记", "desc":"每场战斗开始时获得 1 力量。"},
 "battery":{"name":"余烬之心", "desc":"每回合能量 +1。"},
 "book":{"name":"先知手记", "desc":"每回合抽牌 +1。"},
 "shell":{"name":"古龙鳞", "desc":"每个玩家回合开始时获得 4 护甲。"},
 "fang":{"name":"血色獠牙", "desc":"每场战斗开始时获得 2 力量。"},
 "flask":{"name":"不竭药瓶", "desc":"每场战斗胜利后恢复 8 生命。"},
 "heart":{"name":"生命琥珀", "desc":"获得时最大生命 +18，并恢复 18 生命。"},
 "spikes":{"name":"荆棘王冠", "desc":"每场战斗开始时获得 4 反伤。"},
 "coin":{"name":"旅商金章", "desc":"每场战斗胜利额外获得 20 金币。"}
}

const STAGE_NAMES = ["迷雾入口", "枯木哨站", "腐根守望者", "断铁矿道", "遗忘兵营", "铁狱监军", "血砂营地", "赤刃祭坛", "血誓将军", "余烬回廊", "王座前庭", "余烬之王"]
const CHAPTERS = ["青苔边境", "失落铁城", "血砂荒原", "余烬王座"]

static func card(raw_id: String) -> Dictionary:
 var upgraded = raw_id.ends_with("+")
 var id = raw_id.trim_suffix("+")
 var c: Dictionary = CARDS[id].duplicate(true)
 c["id"] = raw_id
 c["upgraded"] = upgraded
 if upgraded:
  c.name += "+"
  for key in c.upgrade: c[key] = c.upgrade[key]
 return c

static func describe(c: Dictionary) -> String:
 var parts: Array[String] = []
 if c.has("break_block"): parts.append("先移除目标全部护甲")
 if c.has("poison_cost"): parts.append("需消耗目标 %d 层毒素" % c.poison_cost)
 if c.has("block_damage"): parts.append("造成当前护甲 +%d 伤害" % c.damage)
 elif c.has("damage"):
  parts.append("造成 %d 伤害%s" % [c.damage, " ×%d" % c.hits if c.has("hits") else ""])
 if c.has("all_damage"):
  if c.has("block_ratio"): parts.append("全体受到护甲的 50%% +%d 伤害" % c.all_damage)
  else: parts.append("对全体造成 %d 伤害" % c.all_damage)
 if c.has("block"): parts.append("获得 %d 护甲" % c.block)
 if c.has("poison"): parts.append("施加 %d 层毒素" % c.poison)
 if c.has("all_poison"): parts.append("全体施加 %d 层毒素" % c.all_poison)
 if c.has("multiply_poison"): parts.append("毒素翻倍，最多新增 %d 层" % c.poison_growth_cap)
 if c.has("poison_burst"): parts.append("清空目标毒素\n造成层数 ×%d 穿甲伤害" % c.poison_burst)
 if c.has("coating"): parts.append("本场淬毒 +%d\n每张攻击后施加毒素" % c.coating)
 if c.has("all_thorns_damage"): parts.append("全体受到反伤值 ×%d 伤害\n不消耗反伤" % c.all_thorns_damage)
 if c.has("fury_engine"): parts.append("本场嗜战 +%d\n每张攻击后获得狂怒" % c.fury_engine)
 if c.has("fury"): parts.append("获得 %d 狂怒" % c.fury)
 if c.has("fury_burst"): parts.append("清空狂怒，每层额外 +%d 伤害" % c.fury_burst)
 if c.has("next_block"): parts.append("下回合开始获得 %d 护甲" % c.next_block)
 if c.has("next_draw"): parts.append("下回合额外抽 %d 张牌" % c.next_draw)
 if c.has("strength"): parts.append("本场战斗力量 +%d" % c.strength)
 if c.has("thorns"): parts.append("本场战斗反伤 +%d" % c.thorns)
 if c.has("draw"): parts.append("抽 %d 张牌" % c.draw)
 if c.has("heal_recent"): parts.append("治疗上轮伤势 %d" % c.heal_recent)
 if c.has("weak"): parts.append("虚弱 %d 回合" % c.weak)
 if c.has("vulnerable"): parts.append("易伤 %d 回合" % c.vulnerable)
 if c.has("next_energy"): parts.append("下回合额外获得 %d 能量" % c.next_energy)
 if c.has("temp_thorns"): parts.append("反伤 +%d，持续至下回合开始" % c.temp_thorns)
 if c.has("energy"): parts.append("获得 %d 能量" % c.energy)
 if c.has("self_damage"): parts.append("失去 %d 生命" % c.self_damage)
 if c.has("retain_cap"): parts.append("本场每回合保留至多 %d 护甲" % c.retain_cap)
 if c.kind == "能力": parts.append("能力 · 生效后本场移出")
 return "\n".join(parts)

static func enemy(title: String, hp: int, pattern: Array, boss: bool = false) -> Dictionary:
 return {"name":title, "hp":hp, "max_hp":hp, "block":0, "poison":0, "weak":0, "vulnerable":0, "strength":0, "step":0, "pattern":pattern, "boss":boss}

static func attack(amount: int, hits: int = 1) -> Dictionary:
 return {"type":"attack", "amount":amount, "hits":hits}

static func defend(amount: int) -> Dictionary:
 return {"type":"defend", "amount":amount}

static func buff(amount: int) -> Dictionary:
 return {"type":"buff", "amount":amount}

static func encounter(stage: int) -> Array:
 match stage:
  1: return [enemy("苔原游荡者", 32, [attack(6), defend(7), attack(9)])]
  2: return [enemy("荆棘斥候", 28, [attack(5), attack(7)]), enemy("孢子幼体", 22, [defend(6), attack(6)])]
  3: return [enemy("腐根守望者", 105, [attack(10), defend(14), attack(6, 2), buff(2)], true)]
  4: return [enemy("矿道看守", 52, [defend(10), attack(12), attack(7, 2)])]
  5: return [enemy("铁城卫兵", 42, [attack(9), defend(12)]), enemy("巡夜弩手", 34, [defend(5), attack(5, 2)])]
  6: return [enemy("铁狱监军", 150, [defend(20), attack(16), buff(3), attack(7, 3)], true)]
  7: return [enemy("血砂掠夺者", 72, [attack(13), buff(2), attack(6, 3)])]
  8: return [enemy("赤刃祭司", 48, [buff(2), attack(11)]), enemy("血誓卫士", 60, [attack(10), defend(14), attack(15)])]
  9: return [enemy("血誓将军", 195, [attack(8, 2), buff(3), attack(25), defend(18)], true)]
  10: return [enemy("余烬近卫", 78, [defend(14), attack(17)]), enemy("灰烬猎手", 52, [attack(6, 2), buff(2)])]
  11: return [enemy("王座左卫", 75, [attack(14), defend(16)]), enemy("王座右卫", 75, [defend(16), attack(7, 3)])]
  _: return [enemy("余烬之王", 260, [attack(8, 3), defend(26), buff(4), attack(32), attack(11, 3)], true)]
