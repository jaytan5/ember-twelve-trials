extends Resource
class_name RelicData
@export var id: String
@export var title: String
@export_multiline var description: String
@export var starter: bool = false
@export var effects: Dictionary = {}

func to_dictionary() -> Dictionary:
 return {"name":title,"desc":description,"starter":starter,"effects":effects.duplicate(true)}
