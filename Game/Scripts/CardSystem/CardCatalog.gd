extends RefCounted
## Resource-backed catalog. Add .tres files to the appropriate resource folder.
const CONFIG = preload("res://Game/Data/Config/game_rules.tres")
const REWARD = preload("res://Game/Resources/Rewards/default.tres")
static var ROUTES: Dictionary = CONFIG.routes
static var DIFFICULTIES: Dictionary = CONFIG.difficulties
static var CHAPTERS: Array = CONFIG.chapters
static var CARDS: Dictionary = load_definitions("res://Game/Resources/Cards")
static var RELICS: Dictionary = load_definitions("res://Game/Resources/Relics")
static var STAGE_NAMES: Array = level_names()

static func load_definitions(folder: String) -> Dictionary:
 var result: Dictionary = {}
 var files = DirAccess.get_files_at(folder)
 files.sort()
 for filename in files:
  var clean = filename.trim_suffix(".remap")
  if not clean.ends_with(".tres"): continue
  var definition = load(folder.path_join(clean))
  assert(definition != null, "Invalid resource: " + clean)
  result[definition.id] = definition.to_dictionary()
 return result

static func level_names() -> Array:
 var result: Array = []
 for i in range(1, 13): result.append(load("res://Game/Resources/Levels/level_%02d.tres" % i).title)
 return result

static func encounter(stage: int) -> Array:
 return load("res://Game/Resources/Levels/level_%02d.tres" % clampi(stage, 1, 12)).create_enemies()

static func cost_text(c: Dictionary) -> String:
 return "X" if c.cost < 0 else str(c.cost)

static func sorted_card_ids(route: String) -> Array:
 var ids: Array = []
 for id in CARDS:
  if CARDS[id].route == route: ids.append(id)
 # X has a variable cost and is listed after all fixed costs.
 ids.sort_custom(func(a, b):
  var left: int = 99 if CARDS[a].cost < 0 else CARDS[a].cost
  var right: int = 99 if CARDS[b].cost < 0 else CARDS[b].cost
  return left < right if left != right else a < b)
 return ids

static func card_count(route: String) -> int:
 var total = 0
 for c in CARDS.values():
  if c.route == route: total += 1
 return total

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

static func describe(c: Dictionary, compact: bool = false) -> String:
 var parts: Array[String] = []
 if c.has("armor_damage"): parts.append("移除目标全部护甲，造成移除量 ×%s 的伤害（不受力量、易伤加成）" % str(c.armor_damage))
 if c.has("poison_cost"): parts.append("需消耗目标 %d 层毒素" % c.poison_cost)
 if c.has("consume_block_damage"): parts.append("消耗全部护甲\n造成消耗量 ×%s 的伤害（另加力量）" % str(c.consume_block_damage / 100.0))
 if c.has("thorns_attack"): parts.append("造成 %d + 当前反伤 ×%d 伤害（另加力量）" % [c.damage, c.thorns_attack])
 elif c.has("poison_damage_cap"): parts.append("造成 %d + 目标毒素层数的伤害\n毒素加成最多 %d；不消耗毒素" % [c.damage, c.poison_damage_cap])
 elif c.has("block_damage"): parts.append("造成当前护甲 +%d 伤害" % c.damage)
 elif c.has("damage"):
  parts.append("造成 %d 伤害%s" % [c.damage, " ×%d" % c.hits if c.has("hits") else ""])
 if c.has("lost_hp_damage"): parts.append("造成当前已损失生命的 %d%% 伤害（向下取整，另加力量）" % c.lost_hp_damage)
 if c.has("random_damage"): parts.append("随机攻击 %d 次，每次 %d 伤害\n每段独立选择存活敌人" % [c.hits, c.random_damage])
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
 if c.has("next_lifesteal"): parts.append("下回合所有对敌伤害附带 %d%% 吸血\n按实际生命伤害恢复自身生命" % c.next_lifesteal)
 if c.has("low_hp_crit"): parts.append("本场生命低于 %d%% 时\n每段对敌伤害有 %d%% 几率造成 2 倍伤害" % [c.low_hp_crit_threshold, c.low_hp_crit])
 if c.has("next_strength"): parts.append("下回合力量 +%d\n仅持续下回合" % c.next_strength)
 if c.has("turn_strength"): parts.append("本回合力量 +%d\n回合结束时移除" % c.turn_strength)
 if c.has("lost_hp_next_strength"): parts.append("下回合力量增加当前已损失生命的 %d%%\n出牌时计算，向下取整；仅持续下回合" % c.lost_hp_next_strength)
 if c.has("mark_crit"): parts.append("标记目标 %d 回合\n对其使用攻击牌时暴击率 +%d%%；暴击造成双倍伤害" % [c.mark_turns, c.mark_crit])
 if c.has("stun"): parts.append("眩晕目标：下一次敌方行动无法行动\n毒素照常结算，重复施加不叠加")
 if c.has("autoplay"): parts.append("从抽牌堆取 %d 张牌，依次免费使用\n不足时洗入弃牌堆补足" % c.autoplay)
 if c.has("bomb_damage"): parts.append("下回合玩家回合结束、敌人行动前\n对目标造成 %d 伤害；目标死亡则转向存活敌人" % c.bomb_damage)
 if c.get("trigger_poison", false): parts.append("立即触发目标一次毒素伤害\n%s" % ("毒素层数不减少" if c.get("preserve_poison", false) else "结算后毒素减少 1 层"))
 if c.has("next_block"): parts.append("下回合开始获得 %d 护甲" % c.next_block)
 if c.has("next_draw"): parts.append("下回合额外抽 %d 张牌" % c.next_draw)
 if c.has("strength"): parts.append("本场战斗力量 +%d" % c.strength)
 if c.has("thorns"): parts.append("本场战斗反伤 +%d" % c.thorns)
 if c.has("draw"): parts.append("抽 %d 张牌" % c.draw)
 if c.has("heal"): parts.append("恢复 %d 生命" % c.heal)
 if c.has("store_energy"): parts.append("消耗全部能量 X，下回合额外获得 X 能量")
 if c.has("freeze_all"): parts.append("冰冻全体敌人：跳过下一次行动，毒素照常结算")
 if c.has("barrier"): parts.append("抵挡下一次正伤害（多段仅挡一段）")
 if c.has("barrier_reflect"): parts.append("并反弹此次伤害的 %d%%" % c.barrier_reflect)
 if c.has("heal_recent"): parts.append("治疗上轮伤势 %d" % c.heal_recent)
 if c.has("weak"): parts.append("施加虚弱：攻击伤害 -30%%，持续 %d 回合" % c.weak)
 if c.has("vulnerable"): parts.append("施加易伤：受到普通伤害 +30%%，持续 %d 回合" % c.vulnerable)
 if c.id.trim_suffix("+") == "rage_slash": parts.append("唯一：限1张" if compact else "唯一：卡组限 1 张；拥有后不再出现在选牌和商店")
 if c.has("next_energy"): parts.append("下回合额外获得 %d 能量" % c.next_energy)
 if c.has("temp_thorns"): parts.append("反伤 +%d，持续至下回合开始" % c.temp_thorns)
 if c.has("energy"): parts.append(("本回合额外获得 %d 点能量" if c.get("store_energy", false) else "获得 %d 能量") % c.energy)
 if c.has("self_damage"): parts.append("失去 %d 生命" % c.self_damage)
 if c.has("self_damage_unless_kill"): parts.append("若未击杀目标，失去 %d 生命" % c.self_damage_unless_kill)
 if c.has("retain_cap"): parts.append("本场每回合保留至多 %d 护甲" % c.retain_cap)
 if c.kind == "能力": parts.append("能力 · 生效后本场移出")
 elif c.get("exhaust", false): parts.append("消耗 · 使用后本场移出，下场恢复")
 return "\n".join(parts)

static func enemy(title: String, hp: int, pattern: Array, boss: bool = false) -> Dictionary:
 return {"name":title, "hp":hp, "max_hp":hp, "block":0, "poison":0, "weak":0, "vulnerable":0, "strength":0, "frozen":0, "stunned":0, "mark_crit":0, "mark_turns":0, "step":0, "pattern":pattern, "boss":boss}

static func attack(amount: int, hits: int = 1) -> Dictionary:
 return {"type":"attack", "amount":amount, "hits":hits}

static func defend(amount: int) -> Dictionary:
 return {"type":"defend", "amount":amount}

static func buff(amount: int) -> Dictionary:
 return {"type":"buff", "amount":amount}

