extends SceneTree
## Generate the design reference from the actual runtime configuration.
const Data = preload("res://scripts/data.gd")
const Run = preload("res://scripts/run_state.gd")

func action_text(action: Dictionary, strength: int = 0) -> String:
 match action.type:
  "attack":
   var amount: int = action.amount + strength
   return "攻击 %d" % amount if action.hits == 1 else "连击 %d×%d（共%d）" % [amount, action.hits, amount * action.hits]
  "defend": return "护甲 +%d" % action.amount
  _: return "力量 +%d" % action.amount

func pattern_text(enemy: Dictionary, include_growth: bool = false) -> String:
 var result: Array[String] = []
 var strength = 0
 for action in enemy.pattern:
  result.append(action_text(action, strength))
  if include_growth and action.type == "buff": strength += action.amount
 return " → ".join(result)

func _init() -> void:
 var counts = {"neutral":0, "venom":0, "bastion":0, "fury":0}
 for card in Data.CARDS.values(): counts[card.route] += 1
 if counts != {"neutral":17, "venom":10, "bastion":10, "fury":10}:
  printerr("Unexpected card counts: ", counts)
  quit(1)
  return
 var easy = Run.new()
 var hard = Run.new()
 easy.new_run("venom", 1, "easy")
 hard.new_run("venom", 1, "hard")
 var doc = "# 余烬十二关｜完整卡牌与怪物设定\n\n整理日期：2026-11-03。内容以当前 `Game/Resources/`、`Game/Data/Config/game_rules.tres` 和 `Game/Scripts/` 为准，表格直接读取游戏配置生成。共 **47 种基础卡、47 种升级版、17 种敌人（含 4 位 Boss）、12 个战斗关卡、3 档难度**。\n\n"
 doc += "## 1. 基本流程与玩家规则\n\n12 关顺序推进，第 3、6、9、12 关为 Boss。玩家先行动，以卡牌消耗能量；结束回合后，存活敌人按关卡表中的排列依次行动。敌人不用卡牌，每轮执行自身行动循环中的下一项。生命跨关保留，护甲与战斗状态下场重置。\n\n每回合默认3能量。首回合抽5张，后续回合抽2张，手牌最多10张；回合结束保留剩余手牌，未用能量不累积。抽牌堆空时洗入弃牌堆。出战卡组 5–30 张，额外拥有的卡可留在备用卡库；战斗外可以免费拖动换牌。初始拥有 65 金币、2 瓶治疗药水，每瓶恢复 20 生命，不耗能量。\n\n"
 doc += "## 2. 路线、起始卡组与核心玩法\n\n所有路线共用初始卡：斩击×3、防守×2、快斩×2、横扫×1、战术调整×2、洞察×1、博学×1，再加5张路线牌，总计17张。\n\n| 路线 | 初始生命 | 路线初始牌 | 初始遗物 | 两套核心玩法 |\n| --- | ---: | --- | --- | --- |\n"
 var builds = {"venom":"叠毒与淬毒持续伤害；消耗毒层引爆、回能", "bastion":"护甲转单体/群体伤害；反伤累积与主动反击风暴", "fury":"力量强化多段攻击；嗜战积攒狂怒、怒斩爆发"}
 for route in Data.ROUTES:
  var r: Dictionary = Data.ROUTES[route]
  var names: Array[String] = []
  for id in r.cards: names.append(Data.card(id).name)
  var relic: Dictionary = Data.RELICS[r.relic]
  doc += "| %s | %d | %s | %s：%s | %s |\n" % [r.name, r.hp, "、".join(names), relic.name, relic.desc, builds[route]]
 doc += "\n蚀毒的常用配合：淬毒→毒刃/多张攻击叠毒→催化→选择持续结算或毒爆；毒素回收消耗4层毒，提供下回合能量，不抽牌。铁壁的配合：重盾/固守→盾击或钢甲冲撞；反震/棘甲/荆棘生长→反击风暴。狂刃的配合：战意→双连斩/疾风三连；嗜战→攻击积攒狂怒，配合怒吼与血性冲锋，最后怒斩收尾。\n\n"
 doc += "## 3. 全部卡牌\n\n下表为基础效果，不含力量、易伤和遗物加成。除标注全体或自身效果外，伤害与负面状态作用于当前选中的单体敌人。所有卡只能升级一次，升级费用不变。**能力牌**生效后本场移入「已激活」，下场恢复；急救使用后也本场移出；其他攻击和技能进入弃牌堆循环使用。力量、永久反伤、淬毒、嗜战可叠加；固守保留上限取最高值，不相加。\n\n"
 for route in ["neutral", "venom", "bastion", "fury"]:
  doc += "### " + ("通用" if route == "neutral" else Data.ROUTES[route].name) + "（%d 种）\n\n" % counts[route]
  doc += "| 卡牌 | 类型 | 能量 | 基础效果 | 升级后效果 |\n| --- | --- | ---: | --- | --- |\n"
  for id in Data.CARDS:
   var c = Data.card(id)
   if c.route != route: continue
   doc += "| %s | %s | %s | %s | %s |\n" % [c.name, c.kind, Data.cost_text(c), Data.describe(c).replace("\n", "；"), Data.describe(Data.card(id + "+")).replace("\n", "；")]
  doc += "\n"
 doc += "冰冻让全体存活敌人跳过下一次行动，毒素照常结算，行动循环不前进；重复冰冻刷新而不叠加回合。金钟罩抵挡一次正伤害（包括自伤），先于护甲扣除，多段攻击只挡一段，可叠加次数、跨回合保留，下场清零。厚积薄发消耗全部当前能量，额外能量仅在下回合发放一次。碎甲击按移除护甲量造成伤害，不受力量或易伤影响；升级版为移除量的1.5倍，向下取整。全才先伤害，后获得力量。\n\n"
 doc += "## 4. 状态、伤害与结算细节\n\n| 机制 | 当前实现 |\n| --- | --- |\n"
 doc += "| 护甲 | 抵挡普通伤害，按每段攻击依次扣除；玩家通常在下个玩家回合开始清空，敌人在自己的行动开始清空。固守生效后，本场每回合保留剩余护甲至上限（基础12、升级16），多张取最高值，再获得遗物和延迟护甲。 |\n"
 doc += "| 力量 | 每点力量给每段攻击伤害 +1，包含盾击与钢甲冲撞；不增强毒素、毒爆、反伤或反击风暴。双方力量都可叠加。 |\n"
 doc += "| 毒素 | 该敌人行动前受到等于层数的伤害，无视护甲，随后减少 1 层。毒死的敌人不行动；不会触发反伤。 |\n"
 doc += "| 淬毒 | 每张攻击牌结算后，对其命中且仍存活的敌人施加等于淬毒值的毒素；多段攻击只触发一次，全体攻击对各存活目标各触发一次。攻击被护甲挡住也可施毒。 |\n"
 doc += "| 反伤 | 每次敌方攻击命中后反击，即使伤害被护甲完全挡住。按每段触发；若反死敌人，则中止其剩余连击。反击受敌方护甲和易伤影响。棘甲只增加临时反伤，在下个玩家回合开始清零；反震、荆棘生长提供永久反伤，二者之和用于反击与风暴。 |\n"
 doc += "| 嗜战 | 每张攻击牌全部效果结算后，获得等于嗜战值的狂怒。多段攻击仍只触发一次，技能与能力牌不触发。 |\n"
 doc += "| 狂怒 | 跨回合保留；怒斩清空现有狂怒，按倍率增加本次伤害，之后再触发嗜战。下场战斗清零。 |\n"
 doc += "| 虚弱 | 敌人每段攻击先加力量，再乘 75%，向下取整；该敌人行动后回合数减 1，防御/蓄力回合也会减。 |\n"
 doc += "| 易伤 | 敌人受到的普通伤害增加 50%，向上取整，再扣护甲；该敌人行动后回合数减 1。不增强毒素与毒爆。 |\n"
 doc += "| 治疗 | 卸力、急救、全才直接治疗，可恢复旧伤和自伤。汲取仍只治疗上轮敌方攻击造成的未恢复伤势，多张共用额度，下一敌方阶段开始过期。药水优先扣除该额度，避免重复治疗。营火、药水和遗物仍可治疗旧伤，均不超过最大生命。汲取不取决于攻击实际伤害。 |\n"
 doc += "| 延迟效果 | 厚积薄发和毒素回收在下一回合额外发放能量，额外抽牌仍受手牌上限限制，只生效一次。 |\n\n"
 doc += "关键顺序：碎甲击先清空目标护甲再攻击；识破先伤害再施加状态；血性冲锋先获得狂怒，再攻击；毒素回收必须先支付目标的 4 层毒素，不足则无法出牌；燃血先扣生命，致死时立即战败。毒爆清空毒素后按层数倍率造成穿甲伤害，不吃力量或易伤。钢甲冲撞取当前护甲的一半并向下取整；盾击与钢甲冲撞均不消耗护甲，反击风暴不消耗反伤。\n\n青蛇牙的首次施毒加成只给本场第一个成功施毒的目标；若首次施放群体毒，额外 2 层并不会给所有敌人。催化使毒层翻倍，但每次最多新增12层（升级18层），不会触发或消耗首次施毒加成。\n\n"
 doc += "## 5. 难度设定\n\n| 难度 | 行动预告 | 敌人数值 |\n| --- | --- | --- |\n"
 for difficulty in ["easy", "normal", "hard"]:
  var d: Dictionary = Data.DIFFICULTIES[difficulty]
  doc += "| %s | %s | %s |\n" % [d.name, "显示攻击/连击伤害、次数、总伤害、防御与蓄力" if d.show_intents else "统一显示行动未知，不显示类型或预告颜色", "生命×1.35；攻击、护甲、蓄力增长量×1.25，向上取整" if difficulty == "hard" else "基础数值"]
 doc += "\n中等即普通模式。难度不改变行动顺序、连击次数、奖励或玩家初始属性。难度在新局开始前选择，随存档保存；旧存档按简单继续。简单模式预告计入当前敌人力量和虚弱，实际生命损失还受玩家护甲影响。所有难度都显示已发生的战斗记录和敌人当前状态。\n\n"
 doc += "## 6. 怪物通用规则\n\n- 当前敌人技能只有三种底层动作：攻击（单次/多段）、给自己增加护甲、给自己增加力量。名称与外观不代表额外技能：目前没有怪物施毒、召唤、回血、阶段变身、随机选招或死亡被动。四位 Boss 同样遵循固定循环。\n- 每名敌人从循环第一项开始，每个敌方回合执行一项，到末尾后回到第一项。多敌人关卡按表内从上到下的顺序依次行动；所有攻击都打玩家，防御和蓄力只影响自己。\n- 敌人自己的行动开始：先清空旧护甲，再结算毒素；若仍存活则执行动作，之后易伤与虚弱各减少 1 回合。\n- 防御动作获得的新护甲会保留到接下来的玩家回合，直到敌人下次行动开始时清空。力量不会每回合清空，每次蓄力持续累加，后续每段攻击都会增加伤害。\n- 初始敌人均无护甲、毒素、力量、虚弱或易伤。表格中的攻击数字是**未叠力量、未受虚弱影响的动作基础值**；并不保证每次重复循环都打相同伤害。\n\n"
 var enemy_count = 0
 var boss_count = 0
 for chapter in range(4):
  doc += "### 第 %d 章：%s\n\n" % [chapter + 1, Data.CHAPTERS[chapter]]
  for stage in range(chapter * 3 + 1, chapter * 3 + 4):
   doc += "#### 第 %d 关：%s%s\n\n" % [stage, Data.STAGE_NAMES[stage - 1], "（Boss）" if stage % 3 == 0 else ""]
   doc += "| 怪物 | 简单/中等生命 | 简单/中等行动循环（基础值） | 困难生命 | 困难行动循环（基础值） |\n| --- | ---: | --- | ---: | --- |\n"
   var normals = easy.encounter_for(stage)
   var hards = hard.encounter_for(stage)
   for i in range(normals.size()):
    var e: Dictionary = normals[i]
    var h: Dictionary = hards[i]
    enemy_count += 1
    if e.boss: boss_count += 1
    doc += "| %s | %d | %s → 循环 | %d | %s → 循环 |\n" % [e.name, e.hp, pattern_text(e), h.hp, pattern_text(h)]
   doc += "\n"
 doc += "## 7. 四位 Boss 的首轮实际行动\n\n下表已经算入首轮中途获得的力量，假设玩家没有施加虚弱，也不提前击杀 Boss；伤害为扣除玩家护甲前的值。完成第一轮后力量继续保留，后续循环伤害还会增长。\n\n| Boss | 简单/中等首轮 | 困难首轮 | 每轮永久增加的力量（基础/困难） |\n| --- | --- | --- | --- |\n"
 for stage in [3, 6, 9, 12]:
  var e: Dictionary = easy.encounter_for(stage)[0]
  var h: Dictionary = hard.encounter_for(stage)[0]
  var growth = 0
  var hard_growth = 0
  for action in e.pattern:
   if action.type == "buff": growth += action.amount
  for action in h.pattern:
   if action.type == "buff": hard_growth += action.amount
  doc += "| %s | %s | %s | +%d / +%d |\n" % [e.name, pattern_text(e, true), pattern_text(h, true), growth, hard_growth]
 doc += "\n例如：铁狱监军的三连击基础值为 7×3，但第一轮会先蓄力 +3，因此首轮实际为 10×3=30。困难模式基础每段 9、蓄力 +4，首轮实际为 13×3=39。\n\n"
 doc += "## 8. 与卡组相关的奖励及遗物\n\n普通战胜利基础奖励 30 金币及三选一卡；前 3 位 Boss 基础奖励 80 金币、恢复 15 生命、升级卡三选一、遗物三选一。最后一关直接通关结算，获得余烬王冠记录，不再选牌/遗物或进入营地。选牌可跳过，奖励池为当前路线与通用牌，斩击/防守不进入随机奖励池；每次三张中至少一张路线牌。\n\n| 遗物 | 效果 | 来源 |\n| --- | --- | --- |\n"
 for id in Data.RELICS:
  var r: Dictionary = Data.RELICS[id]
  doc += "| %s | %s | %s |\n" % [r.name, r.desc, "路线初始" if id.ends_with("_core") else "Boss奖励"]
 doc += "\n营火每关免费休息或升级一张牌，二选一；休息恢复最大生命的 25%（向上取整）。商店买牌 45 金币、治疗 30 金币（恢复 24）、药水 25 金币、永久删牌 40 金币。治疗与永久删牌每关各一次，药水最多携带 3 瓶。免费移入备用卡库不等于永久删牌。\n\n"
 doc += "## 9. 配置来源与维护\n\n- `scripts/data.gd`：全部卡牌、升级规则、初始路线、遗物、敌人与固定行动模式、难度倍率。\n- `scripts/run_state.gd`：真实伤害、状态、回合结算、难度缩放、卡组和奖励规则。\n- `tests/export_design.gd`：读取当前配置重新生成本文。\n\n本文仅梳理当前已实现的玩法，没有改动游戏数值。\n"
 if enemy_count != 17 or boss_count != 4:
  printerr("Unexpected encounter counts")
  quit(1)
  return
 var file = FileAccess.open("res://游戏完整设定-卡牌与怪物.md", FileAccess.WRITE)
 if file == null:
  printerr("Cannot write design reference")
  quit(1)
  return
 file.store_string(doc)
 file.close()
 print("Export verified: 47 cards + upgrades, ", enemy_count, " enemies, ", boss_count, " bosses, 12 stages, 3 difficulties.")
 quit()
