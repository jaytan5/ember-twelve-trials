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
 if counts != {"neutral":20, "venom":12, "bastion":12, "fury":12}:
  printerr("Unexpected card counts: ", counts)
  quit(1)
  return
 var easy = Run.new()
 var hard = Run.new()
 easy.new_run("venom", 1, "easy")
 hard.new_run("venom", 1, "hard")
 var doc = "# 小泥团，出击！｜完整卡牌与怪物设定\n\n整理日期：2026-11-12。内容以当前 `Game/Resources/`、`Game/Data/Config/game_rules.tres` 和 `Game/Scripts/` 为准，表格直接读取游戏配置生成。共 **56 种基础卡、56 种升级版、17 种敌人（含 4 位 Boss）、12 个战斗关卡、4 档难度**。\n\n"
 doc += "## 1. 基本流程与玩家规则\n\n12 关顺序推进，第 3、6、9、12 关为 Boss。玩家先行动，以卡牌消耗能量；结束回合后，存活敌人按关卡表中的排列依次行动。敌人不用卡牌，每轮执行自身行动循环中的下一项。生命跨关保留，护甲与战斗状态下场重置。\n\n每回合默认3能量。首回合抽5张，后续回合抽2张，手牌最多10张；回合结束保留剩余手牌，未用能量不累积。抽牌堆空时洗入弃牌堆。出战卡组 15–30 张，额外拥有的卡可留在备用卡库；战斗外可以免费拖动换牌。初始拥有 65 金币、2 瓶治疗药水（携带上限2瓶），每瓶恢复 20 生命，不耗能量。\n\n"
 doc += "## 2. 路线、起始卡组与核心玩法\n\n所有路线共用初始卡：奋力挥击×3、稳固防御×2、迅捷连击×2、横扫四方×1、战术调整×2、敏锐洞察×1、博闻强识×1，再加5张路线牌，总计17张。\n\n| 路线 | 初始生命 | 路线初始牌 | 初始遗物 | 两套核心玩法 |\n| --- | ---: | --- | --- | --- |\n"
 var builds = {"venom":"叠毒与淬毒持续伤害；消耗毒层引爆、回能", "bastion":"护甲转单体/群体伤害；反伤累积与主动飞刺齐发", "fury":"力量强化多段攻击；以战养战恢复与低血量暴击"}
 for route in Data.ROUTES:
  var r: Dictionary = Data.ROUTES[route]
  var names: Array[String] = []
  for id in r.cards: names.append(Data.card(id).name)
  var relic: Dictionary = Data.RELICS[r.relic]
  doc += "| %s | %d | %s | %s：%s | %s |\n" % [r.name, r.hp, "、".join(names), relic.name, relic.desc, builds[route]]
 doc += "\n蚀毒的常用配合：利刃淬毒→毒刃突袭/多张攻击叠毒→毒性催化→选择持续结算或毒素引爆；毒素回收消耗4层毒，提供下回合能量，不抽牌。铁壁的配合：坚盾护身/固守不移→重盾猛击或钢甲冲撞；反震之力/荆棘护甲/荆棘生长→飞刺齐发。狂刃的配合：坚定战意→连环挥击/疾风连击；以战养战→下一回合攻击恢复生命；透支潜能/孤注一掷失去生命，背水一击按已损失生命造成伤害；逆境觉醒在低血量时提供暴击，振奋战吼为本回合提供临时力量。\n\n"
 doc += "## 3. 全部卡牌\n\n下表为基础效果，不含力量、易伤和遗物加成。除标注全体或自身效果外，伤害与负面状态作用于当前选中的单体敌人。所有卡只能升级一次，以战养战由3费降为2费，震慑心神由2费降为1费，其余升级费用不变。各路线内按基础费用升序排列，X费列在固定费用之后。**能力牌**生效后本场移入「已激活」，下场恢复；紧急救护使用后也本场移出；其他攻击和技能进入弃牌堆循环使用。力量、永久反伤、淬毒可叠加；以战养战吸血率与逆境觉醒暴击率取最高值，不叠加；固守不移保留上限取最高值，不相加。\n\n"
 for route in ["neutral", "venom", "bastion", "fury"]:
  doc += "### " + ("通用" if route == "neutral" else Data.ROUTES[route].name) + "（%d 种）\n\n" % counts[route]
  doc += "| 卡牌 | 类型 | 能量 | 基础效果 | 升级后效果 |\n| --- | --- | ---: | --- | --- |\n"
  for id in Data.sorted_card_ids(route):
   var c = Data.card(id)
   if c.route != route: continue
   doc += "| %s | %s | %s | %s | %s |\n" % [c.name, c.kind, Data.cost_text(c) + ("→" + Data.cost_text(Data.card(id + "+")) if c.cost != Data.card(id + "+").cost else ""), Data.describe(c).replace("\n", "；"), Data.describe(Data.card(id + "+")).replace("\n", "；")]
  doc += "\n"
 doc += "冰冻让全体存活敌人跳过下一次行动，毒素照常结算，行动循环不前进；重复冰冻刷新而不叠加回合。蛋壳结界抵挡一次正伤害（包括自伤），先于护甲扣除，多段攻击只挡一段，可叠加次数、跨回合保留，下场清零。升级后反弹被抵挡伤害的50%（基础值向下取整），反弹给实际攻击者并沿用普通对敌伤害结算；自伤不反弹。厚积薄发消耗全部当前能量X，下回合额外发放X能量一次；升级后本回合使用后立即额外获得1点能量，返还的1点不计入本次X。碎甲重击按移除护甲量造成伤害，不受力量或易伤影响；升级版为移除量的1.5倍，向下取整。全能身手先伤害，后获得力量。\n\n"
 doc += "## 4. 状态、伤害与结算细节\n\n| 机制 | 当前实现 |\n| --- | --- |\n"
 doc += "| 护甲 | 抵挡普通伤害，按每段攻击依次扣除；玩家通常在下个玩家回合开始清空，敌人在自己的行动开始清空。固守不移生效后，本场每回合保留剩余护甲至上限（基础12、升级16），多张取最高值，再获得遗物和延迟护甲。 |\n"
 doc += "| 力量 | 每点力量给每段攻击伤害 +1，包含重盾猛击与钢甲冲撞；不增强毒素、毒素引爆、反伤或飞刺齐发。双方力量都可叠加。 |\n"
 doc += "| 毒素 | 该敌人行动前受到等于层数的伤害，无视护甲，随后减少 1 层。毒死的敌人不行动；不会触发反伤。 |\n"
 doc += "| 淬毒 | 每张攻击牌结算后，对其命中且仍存活的敌人施加等于淬毒值的毒素；多段攻击只触发一次，全体攻击对各存活目标各触发一次。攻击被护甲挡住也可施毒。 |\n"
 doc += "| 反伤 | 每次敌方攻击命中后反击，即使伤害被护甲完全挡住。按每段触发；若反死敌人，则中止其剩余连击。反击受敌方护甲和易伤影响。荆棘护甲只增加临时反伤，在下个玩家回合开始清零；反震之力、荆棘生长提供永久反伤，二者之和用于反击与风暴。 |\n"
 doc += "| 以战养战/吸血 | 打出后下一回合生效，所有对敌伤害（含毒素、毒素引爆、反伤）按实际扣除敌方生命的75%治疗自身，逐段向下取整；护甲吸收与过量伤害不计入。持续至再下一玩家回合开始；不能超过最大生命，也不能复活。 |\n"
 doc += "| 逆境觉醒/暴击 | 能力生效后，本场当前生命严格低于最大生命35%（升级50%）时，每段对敌伤害独立有50%（升级60%）几率翻倍，再计算易伤与护甲。包括毒素、毒素引爆和反伤；每段重新判断生命门槛，吸血回到门槛以上即不再触发。 |\n"
 doc += "| 虚弱 | 敌人每段攻击先加力量，再乘70%，向下取整。基础持续1回合，升级持续2回合；敌方阶段结束减少1回合，攻击、防御、蓄力或冰冻均计时；重复施加取较长剩余时间。 |\n"
 doc += "| 易伤 | 敌人受到的普通伤害增加20%，向上取整，再扣护甲。基础持续1回合，升级持续2回合；敌方阶段结束减少1回合，重复施加取较长剩余时间；沿用原有范围，不增强毒素、毒素引爆与碎甲重击。 |\n"
 doc += "| 治疗 | 卸劲调息、紧急救护、全能身手直接治疗，可恢复旧伤和自伤。汲取生机仍只治疗上轮敌方攻击造成的未恢复伤势，多张共用额度，下一敌方阶段开始过期。药水优先扣除该额度，避免重复治疗。营火、药水和遗物仍可治疗旧伤，均不超过最大生命。汲取生机不取决于攻击实际伤害。 |\n"
 doc += "| 延迟效果 | 厚积薄发和毒素回收在下一回合额外发放能量，只生效一次；振奋战吼立即获得6（升级9）临时力量，本玩家回合结束时只移除这部分力量；背水之力按出牌时的失血量在下回合提供临时力量，再下回合开始移除，坚定战意等永久力量保留；以战养战仅在下一回合生效。 |\n\n"
 doc += "关键顺序：碎甲重击先清空目标护甲再攻击；识破弱点先伤害再施加状态；背水一击按出牌时（最大生命−当前生命）的50%（升级60%）向下取整，再加力量并结算易伤、暴击与护甲；乱刃连斩每段重新从存活敌人中随机选目标，可重复选中同一敌人，淬毒对命中且存活的每个目标只触发一次；毒素回收必须先支付目标的 4 层毒素，不足则无法出牌；透支潜能先扣生命，致死时立即战败，不再获得能量；孤注一掷先造成45（升级55）伤害，未击杀目标才失去10生命；蛋壳结界仍沿用原规则，可以抵挡自伤。毒素引爆清空毒素后按层数倍率造成穿甲伤害，不吃力量或易伤。钢甲冲撞取当前护甲的一半并向下取整；重盾猛击与钢甲冲撞均不消耗护甲，飞刺齐发不消耗反伤。\n\n进阶宝石按路线提供独立加成，和初始遗物叠加：狂刃开战共3力量，铁壁首回合共7护甲（后续仅初始遗物的3护甲），蚀毒首次施毒共额外5层。青蛇牙的首次施毒加成只给本场第一个成功施毒的目标；若首次施放群体毒，额外 2 层并不会给所有敌人。毒性催化使毒层翻倍，但每次最多新增12层（升级18层），不会触发或消耗首次施毒加成。\n\n"
 doc += "\n- 震慑心神使单个目标跳过下一次行动，毒素照常结算；与冰冻同时存在时共同消耗，不额外叠加跳过次数。\n- 灵感迸发先从牌堆预取3张（升级4张），再依次免费使用；牌堆不足时洗入弃牌堆。预取牌不占手牌位，其他抽牌仍遵守10张上限。X牌以当前能量为X但不扣能量；毒素不足的牌进入弃牌堆；胜负后停止使用剩余牌。自动牌正常计入连击齿轮，单次出牌最多连续自动结算64张。\n- 发条炸弹为2费能力牌，锁定目标，于下一玩家回合结束、敌人行动前造成21（升级28）点基础伤害，不加力量，沿用易伤、逆境觉醒与吸血规则；原目标死亡时转向首个存活敌人。\n- 盯紧破绽持续本回合及下回合（两次敌方阶段结束后移除），攻击牌每段暴击率增加20（升级30）个百分点，与逆境觉醒相加、上限100%，只掷一次；不提高毒素、反伤或炸弹的暴击率。重复施加取最高概率和最长时间。\n- 背水之力在出牌时按已损失生命的15%（升级20%）向下取整，安排下回合临时力量，之后回血或受伤不改变已排定数值；可与振奋战吼和永久力量叠加，分别到期移除。\n- 卸甲重击先清空自身护甲，再按消耗量的2倍（升级2.5倍，向下取整）加力量造成普通攻击伤害；荆棘穿刺计入永久与临时反伤，但不消耗反伤。\n- 毒性发作要求目标至少1层毒，立即造成一次穿甲毒素伤害，随后减1层；升级不减层。趁毒追击按目标当前毒层增加普通攻击伤害，最多10（升级15），不消耗毒素。\n"
 doc += "## 5. 难度设定\n\n| 难度 | 行动预告 | 敌人数值 | 战败重试 |\n| --- | --- | --- | --- |\n"
 for difficulty in ["easy", "normal", "hard", "legendary"]:
  var d: Dictionary = Data.DIFFICULTIES[difficulty]
  doc += "| %s | %s | %s | %s |\n" % [d.name, "显示攻击/连击伤害、次数、总伤害、防御与蓄力" if d.show_intents else "统一显示行动未知，不显示类型或预告颜色", "生命×1.35；攻击、护甲、蓄力增长量×1.25，向上取整" if difficulty in ["hard", "legendary"] else "基础数值", "可重开本小关" if d.allow_retry else "不可重试，须从头开始"]
 doc += "\n四档依次为轻松、标准、勇者、传奇。传奇敌人数值与勇者相同，但无法重试小关。前三档重试恢复本关开战时的完整状态（生命、药水、卡组、手牌、敌人及随机数状态），不会重复发放奖励；新存档保存该快照，旧存档若无快照则保留现有资源、满血重建本关。难度不改变行动顺序、连击次数、奖励或玩家初始属性。难度在新局开始前选择，随存档保存；旧存档按轻松继续。轻松模式预告计入当前敌人力量和虚弱，实际生命损失还受玩家护甲影响。所有难度都显示已发生的战斗记录和敌人当前状态。\n\n"
 doc += "## 6. 怪物通用规则\n\n- 当前敌人技能只有三种底层动作：攻击（单次/多段）、给自己增加护甲、给自己增加力量。名称与外观不代表额外技能：目前没有怪物施毒、召唤、回血、阶段变身、随机选招或死亡被动。四位 Boss 同样遵循固定循环。\n- 每名敌人从循环第一项开始，每个敌方回合执行一项，到末尾后回到第一项。多敌人关卡按表内从上到下的顺序依次行动；所有攻击都打玩家，防御和蓄力只影响自己。\n- 敌人自己的行动开始：先清空旧护甲，再结算毒素；若仍存活则执行动作，易伤与虚弱在该敌方阶段结束时减少1回合。\n- 防御动作获得的新护甲会保留到接下来的玩家回合，直到敌人下次行动开始时清空。力量不会每回合清空，每次蓄力持续累加，后续每段攻击都会增加伤害。\n- 初始敌人均无护甲、毒素、力量、虚弱或易伤。表格中的攻击数字是**未叠力量、未受虚弱影响的动作基础值**；并不保证每次重复循环都打相同伤害。\n\n"
 var enemy_count = 0
 var boss_count = 0
 for chapter in range(4):
  doc += "### 第 %d 章：%s\n\n" % [chapter + 1, Data.CHAPTERS[chapter]]
  for stage in range(chapter * 3 + 1, chapter * 3 + 4):
   doc += "#### 第 %d 关：%s%s\n\n" % [stage, Data.STAGE_NAMES[stage - 1], "（Boss）" if stage % 3 == 0 else ""]
   doc += "| 怪物 | 轻松/标准生命 | 轻松/标准行动循环（基础值） | 勇者/传奇生命 | 勇者/传奇行动循环（基础值） |\n| --- | ---: | --- | ---: | --- |\n"
   var normals = easy.encounter_for(stage)
   var hards = hard.encounter_for(stage)
   for i in range(normals.size()):
    var e: Dictionary = normals[i]
    var h: Dictionary = hards[i]
    enemy_count += 1
    if e.boss: boss_count += 1
    doc += "| %s | %d | %s → 循环 | %d | %s → 循环 |\n" % [e.name, e.hp, pattern_text(e), h.hp, pattern_text(h)]
   doc += "\n"
 doc += "## 7. 四位 Boss 的首轮实际行动\n\n下表已经算入首轮中途获得的力量，假设玩家没有施加虚弱，也不提前击杀 Boss；伤害为扣除玩家护甲前的值。完成第一轮后力量继续保留，后续循环伤害还会增长。\n\n| Boss | 轻松/标准首轮 | 勇者/传奇首轮 | 每轮永久增加的力量（基础/勇者与传奇） |\n| --- | --- | --- | --- |\n"
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
 doc += "\n例如：铁狱监军的三连击基础值为 7×3，但第一轮会先蓄力 +3，因此首轮实际为 10×3=30。勇者与传奇模式基础每段 9、蓄力 +4，首轮实际为 13×3=39。\n\n"
 doc += ("## 8. 与卡组相关的奖励及遗物\n\n普通战胜利基础奖励 %d 金币及三选一卡；前 3 位 Boss 基础奖励 %d 金币、恢复 %d 生命、升级卡三选一、遗物三选一。" % [Data.REWARD.normal_gold, Data.REWARD.boss_gold, Data.REWARD.boss_heal]) + "最后一关直接通关结算，获得余烬王冠记录，不再选牌/遗物或进入营地。选牌可跳过，奖励池为当前路线与通用牌，奋力挥击/稳固防御不进入随机奖励池；每次三张中至少一张路线牌。\n\n| 遗物 | 效果 | 来源 |\n| --- | --- | --- |\n"
 for id in Data.RELICS:
  var r: Dictionary = Data.RELICS[id]
  doc += "| %s | %s | %s |\n" % [r.name, r.desc, "路线初始" if id.ends_with("_core") else "Boss奖励"]
 doc += "\n营火每关免费休息或升级一张牌，二选一；休息恢复最大生命的 25%（向上取整）。" + ("商店买牌 %d 金币、治疗 %d 金币（恢复 %d）、药水 %d 金币。治疗每关一次，药水最多携带 2 瓶。" % [Data.REWARD.shop_price, Data.REWARD.heal_price, Data.REWARD.heal_amount, Data.REWARD.potion_price]) + "永久删牌已移除，战斗外仍可免费将卡牌移入备用卡库。\n\n"
 doc += "连击齿轮仅统计成功打出的牌，第2、4、6张结算后各触发一次，之后不再触发；新回合清零。随机选择仍存活的敌人，6点基础伤害不吃力量，但沿用普通伤害的护甲、易伤、暴击与吸血规则，并逐段播放动画。卡牌自伤致死时不触发。逆命护符在回合开始抽牌与恢复能量后检查，生命严格低于50%才触发，每场一次；额外抽牌遵守10张手牌上限，能量仍完整获得。\n\n## 9. 配置来源与维护\n\n- `scripts/data.gd`：全部卡牌、升级规则、初始路线、遗物、敌人与固定行动模式、难度倍率。\n- `scripts/run_state.gd`：真实伤害、状态、回合结算、难度缩放、卡组和奖励规则。\n- `tests/export_design.gd`：读取当前配置重新生成本文。\n\n新版v8，旧存档兼容v1–v7；出战不足15张时优先从备用卡库补齐，仍不足则免费补奋力挥击/稳固防御；战斗中新增牌进入抽牌堆，保留原手牌与战斗进度。旧狂怒与嗜战状态移除，卡牌ID与升级保留。已有第三瓶药水及重试快照中的第三瓶同步收至2瓶上限；旧的持续整场虚弱/易伤转为剩余1回合。\n"
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
 print("Export verified: 56 cards + upgrades, ", enemy_count, " enemies, ", boss_count, " bosses, 12 stages, 4 difficulties.")
 quit()
