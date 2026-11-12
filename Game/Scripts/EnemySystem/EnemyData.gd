extends Resource
class_name EnemyData
@export var id: String
@export var title: String
@export var max_hp: int = 1
@export var pattern: Array = []
@export var boss: bool = false

func create_state() -> Dictionary:
 return {"id":id,"name":title,"hp":max_hp,"max_hp":max_hp,"block":0,"poison":0,"weak":0,"vulnerable":0,"strength":0,"frozen":0,"stunned":0,"mark_crit":0,"mark_turns":0,"step":0,"pattern":pattern.duplicate(true),"boss":boss}
