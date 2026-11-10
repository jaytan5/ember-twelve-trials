extends SceneTree
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
func _init() -> void:
 var doc = "# 卡牌与路线说明\n\n全部 %d 种卡牌（通用 %d 种，每路线10种），每张均有升级版。数据来自 Game/Resources/Cards 下的独立 Resource。\n\n首回合抽5张，之后每回合保留手牌并抽2张，上限10张。满手牌时不继续抽取，牌留在抽牌堆。已打出的普通牌进入弃牌堆；能力牌与急救本场移出，下场恢复。\n\n出战卡组限制15–30张，各路线内按基础费用升序排列，X费列最后；费用“3→2”表示升级降费。\n\n初始卡组17张：斩击×3、防守×2、快斩×2、横扫×1、战术调整×2、洞察×1、博学×1，加5张当前路线牌。\n\n" % [Data.CARDS.size(), Data.card_count("neutral")]
 for route in ["neutral", "venom", "bastion", "fury"]:
  doc += "## " + ("通用" if route == "neutral" else Data.ROUTES[route].name) + "\n\n| 卡牌 | 类型 | 费用 | 基础效果 | 升级效果 |\n| --- | --- | --- | --- | --- |\n"
  for id in Data.sorted_card_ids(route):
   var c = Data.card(id)
   if c.route != route: continue
   doc += "| %s | %s | %s | %s | %s |\n" % [c.name,c.kind,Data.cost_text(c) + ("→" + Data.cost_text(Data.card(id + "+")) if c.cost != Data.card(id + "+").cost else ""),Data.describe(c).replace("\n","；"),Data.describe(Data.card(id+"+")).replace("\n","；")]
  doc += "\n"
 doc += "## 结算说明\n\n- 嗜血下一回合所有对敌伤害附带75%吸血，按实际生命伤害逐段向下取整治疗；包含毒素、毒爆、反伤，持续至再下一玩家回合开始。\n- 暴力执法为本场能力：生命严格低于30%（升级45%）时，每段对敌伤害独立有50%（升级60%）几率翻倍。生命回到门槛以上立即停止触发，不叠加概率。\n- 怒吼仅下回合获得6（升级9）临时力量，再下一回合移除；不影响永久力量。\n- 血性冲锋按当前已损失生命的50%（升级60%）向下取整计算基础伤害，再加力量。\n- 顺劈斩每段独立随机选择存活敌人，可重复选中同一目标，淬毒对每个命中且存活目标仅触发一次。\n- 虚弱使攻击伤害降低30%，易伤使普通伤害增加20%；两者基础持续1回合、升级持续2回合；敌方阶段结束时减少1回合，重复施加取较长剩余时间。易伤沿用原范围，不增强毒素、毒爆与碎甲击。\n- 燃血先自伤，致死则立即战败；破阵先造成45（升级55）伤害，未击杀目标才失去10生命。金钟罩仍可抵挡自伤。\n- 全才先结算伤害，再增加力量；原有力量仍加成攻击。\n- 碎甲击不受力量、易伤影响，按移除护甲量造成伤害，零护甲即零伤害。\n- 暴风雪跳过敌人下一次行动，毒素照常结算；连续冰冻不会累加跳过次数。\n- 金钟罩先于护甲抵挡一次正伤害，包括自伤；多段攻击只抵挡其中一段。可叠加次数，跨回合保留，下场清零。升级后反弹被抵挡伤害的50%（基础值向下取整），反弹给实际攻击者并沿用普通对敌伤害结算；自伤没有攻击者，不反弹。\n- 厚积薄发按实际消耗能量计入下一回合，允许X=0；升级额外+1。\n- 卸力、急救、全才可治疗旧伤；汲取沿用上轮伤势限制。\n- 起始专属牌：蚀毒为毒刃×2、毒雾屏障、催化、腐蚀；铁壁为重盾×2、盾击、固守、整备；狂刃为双连斩×2、战意、破阵、怒吼。\n"
 doc += "\n## 遗物\n\n| 遗物 | 效果 |\n| --- | --- |\n"
 for id in Data.RELICS:
  doc += "| %s | %s |\n" % [Data.RELICS[id].name, Data.RELICS[id].desc]
 doc += "\n## 难度\n\n轻松、标准、勇者战败可重新开始本小关，恢复开战时的状态；传奇沿用勇者敌人数值，战败不能重试，只能从头开始。\n"
 var file = FileAccess.open("res://卡牌与路线说明.md", FileAccess.WRITE)
 file.store_string(doc)
 print("Exported ", Data.CARDS.size(), " card definitions.")
 quit()
