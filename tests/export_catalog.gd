extends SceneTree
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
func _init() -> void:
 var doc = "# 卡牌与路线说明\n\n全部 %d 种卡牌（通用 %d 种，每路线10种），每张均有升级版。数据来自 Game/Resources/Cards 下的独立 Resource。\n\n首回合抽5张，之后每回合保留手牌并抽2张，上限10张。满手牌时不继续抽取，牌留在抽牌堆。已打出的普通牌进入弃牌堆；能力牌与急救本场移出，下场恢复。\n\n初始卡组17张：斩击×3、防守×2、快斩×2、横扫×1、战术调整×2、洞察×1、博学×1，加5张当前路线牌。\n\n" % [Data.CARDS.size(), Data.card_count("neutral")]
 for route in ["neutral", "venom", "bastion", "fury"]:
  doc += "## " + ("通用" if route == "neutral" else Data.ROUTES[route].name) + "\n\n| 卡牌 | 类型 | 费用 | 基础效果 | 升级效果 |\n| --- | --- | --- | --- | --- |\n"
  for id in Data.CARDS:
   var c = Data.card(id)
   if c.route != route: continue
   doc += "| %s | %s | %s | %s | %s |\n" % [c.name,c.kind,Data.cost_text(c),Data.describe(c).replace("\n","；"),Data.describe(Data.card(id+"+")).replace("\n","；")]
  doc += "\n"
 doc += "## 结算说明\n\n- 全才先结算伤害，再增加力量；原有力量仍加成攻击。\n- 碎甲击不受力量、易伤影响，按移除护甲量造成伤害，零护甲即零伤害。\n- 暴风雪跳过敌人下一次行动，毒素照常结算；连续冰冻不会累加跳过次数。\n- 金钟罩先于护甲抵挡一次正伤害，包括自伤；多段攻击只抵挡其中一段。可叠加次数，跨回合保留，下场清零。\n- 厚积薄发按实际消耗能量计入下一回合，允许X=0；升级额外+1。\n- 卸力、急救、全才可治疗旧伤；汲取沿用上轮伤势限制。\n- 起始专属牌：蚀毒为毒刃×2、毒雾屏障、催化、腐蚀；铁壁为重盾×2、盾击、固守、整备；狂刃为双连斩×2、战意、破阵、怒吼。\n"
 var file = FileAccess.open("res://卡牌与路线说明.md", FileAccess.WRITE)
 file.store_string(doc)
 print("Exported ", Data.CARDS.size(), " card definitions.")
 quit()
