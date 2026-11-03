extends RefCounted
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")

static func roll_cards(run, count: int, upgraded: bool = false) -> Array:
 var pool: Array = []
 for id in Data.CARDS:
  if id in Data.REWARD.excluded_cards: continue
  if Data.CARDS[id].route == run.s.route or Data.CARDS[id].route == "neutral": pool.append(id)
 run.shuffle_list(pool)
 var result: Array = []
 # The reward resource controls how many route cards are guaranteed.
 var guaranteed = mini(count, Data.REWARD.guaranteed_route)
 for id in pool.duplicate():
  if result.size() >= guaranteed: break
  if Data.CARDS[id].route == run.s.route:
   result.append(id + ("+" if upgraded else ""))
   pool.erase(id)
 for id in pool:
  if result.size() >= count: break
  result.append(id + ("+" if upgraded else ""))
 return result

