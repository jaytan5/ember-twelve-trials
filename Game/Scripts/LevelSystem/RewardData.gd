extends Resource
class_name RewardData
@export var id: String
@export var choices: int = 3
@export var guaranteed_route: int = 1
@export var excluded_cards: Array[String] = ["strike", "guard"]
@export var normal_gold: int = 30
@export var boss_gold: int = 80
@export var boss_heal: int = 15
@export var shop_price: int = 45
