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

static func describe(c: Dictionary) -> String:
 var parts: Array[String] = []
 if c.has("armor_damage"): parts.append("移除目标全部护甲，造成移除量 ×%s 的伤害（不受力量、易伤加成）" % str(c.armor_damage))
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
 if c.has("heal"): parts.append("恢复 %d 生命" % c.heal)
 if c.has("store_energy"): parts.append("消耗全部能量 X，下回合额外获得 X%s 能量" % ("+%d" % c.stored_bonus if c.has("stored_bonus") else ""))
 if c.has("freeze_all"): parts.append("冰冻全体敌人：跳过下一次行动，毒素照常结算")
 if c.has("barrier"): parts.append("抵挡下一次正伤害（多段仅挡一段）")
 if c.has("heal_recent"): parts.append("治疗上轮伤势 %d" % c.heal_recent)
 if c.has("weak"): parts.append("虚弱 %d 回合" % c.weak)
 if c.has("vulnerable"): parts.append("易伤 %d 回合" % c.vulnerable)
 if c.has("next_energy"): parts.append("下回合额外获得 %d 能量" % c.next_energy)
 if c.has("temp_thorns"): parts.append("反伤 +%d，持续至下回合开始" % c.temp_thorns)
 if c.has("energy"): parts.append("获得 %d 能量" % c.energy)
 if c.has("self_damage"): parts.append("失去 %d 生命" % c.self_damage)
 if c.has("retain_cap"): parts.append("本场每回合保留至多 %d 护甲" % c.retain_cap)
 if c.kind == "能力": parts.append("能力 · 生效后本场移出")
 elif c.get("exhaust", false): parts.append("消耗 · 使用后本场移出，下场恢复")
 return "\n".join(parts)

static func enemy(title: String, hp: int, pattern: Array, boss: bool = false) -> Dictionary:
 return {"name":title, "hp":hp, "max_hp":hp, "block":0, "poison":0, "weak":0, "vulnerable":0, "strength":0, "frozen":0, "step":0, "pattern":pattern, "boss":boss}

static func attack(amount: int, hits: int = 1) -> Dictionary:
 return {"type":"attack", "amount":amount, "hits":hits}

static func defend(amount: int) -> Dictionary:
 return {"type":"defend", "amount":amount}

static func buff(amount: int) -> Dictionary:
 return {"type":"buff", "amount":amount}

