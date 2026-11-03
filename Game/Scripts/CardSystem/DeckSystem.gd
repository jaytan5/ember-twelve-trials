extends RefCounted
static func shuffle(items: Array, rng: RandomNumberGenerator) -> void:
 for i in range(items.size() - 1, 0, -1):
  var j = rng.randi_range(0, i)
  var temp = items[i]
  items[i] = items[j]
  items[j] = temp

static func draw(s: Dictionary, amount: int, limit: int, rng: RandomNumberGenerator) -> void:
 for _i in range(amount):
  if s.hand.size() >= limit: return
  if s.draw.is_empty():
   if s.discard.is_empty(): return
   s.draw = s.discard.duplicate()
   s.discard.clear()
   shuffle(s.draw, rng)
  s.hand.append(s.draw.pop_back())
