extends Resource
class_name CardData
## 单卡定义。效果数值由结算器解释，-1 费用代表 X。
@export var id: String
@export var title: String
@export_enum("攻击", "技能", "能力") var kind: String = "技能"
@export var route: String = "neutral"
@export var cost: int = 1
@export var target: bool = false
@export var exhaust: bool = false
@export var effects: Dictionary = {}
@export var upgrade: Dictionary = {}

func to_dictionary() -> Dictionary:
 var result = effects.duplicate(true)
 result.merge({"name":title,"kind":kind,"route":route,"cost":cost,"target":target,"exhaust":exhaust,"upgrade":upgrade.duplicate(true)}, true)
 return result
