extends SceneTree
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
func _initialize() -> void:
 var cards: Array = []
 for route in ["neutral", "fury", "bastion", "venom"]:
  for id in Data.sorted_card_ids(route):
   var c = Data.card(id)
   cards.append({"id":id, "name":c.name, "route":c.route, "kind":c.kind, "cost":Data.cost_text(c), "upgraded_cost":Data.cost_text(Data.card(id + "+")), "description":Data.describe(c), "upgraded_description":Data.describe(Data.card(id + "+"))})
 var file = FileAccess.open("res://../output/卡牌拆分/卡牌数据.json", FileAccess.WRITE)
 file.store_string(JSON.stringify(cards, "  "))
 quit()
