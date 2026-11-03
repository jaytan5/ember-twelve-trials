extends Resource
class_name LevelData
@export var number: int = 1
@export var title: String
@export var chapter: String
@export var enemies: Array[Resource] = []

func create_enemies() -> Array:
 var result: Array = []
 for definition in enemies: result.append(definition.create_state())
 return result
