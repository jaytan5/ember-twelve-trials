extends RefCounted
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
const DECK_LIMIT = 30
const DECK_MIN = 15
var s: Dictionary = {}
var rng = RandomNumberGenerator.new()

func save_run(path: String = "user://run_save.json") -> Error:
 var file = FileAccess.open(path, FileAccess.WRITE)
 if file == null: return FileAccess.get_open_error()
 var payload = s.duplicate(true)
 payload.rng_state = str(rng.state)
 file.store_string(JSON.stringify(payload))
 return OK

func load_run(path: String = "user://run_save.json") -> bool:
 if not FileAccess.file_exists(path): return false
 var parsed = normalize_numbers(JSON.parse_string(FileAccess.get_file_as_string(path)))
 if not parsed is Dictionary: return false
 if parsed.get("version", 0) not in [1, 2, 3, 4, 5, 6, 7, 8]: return false
 if not parsed.has("difficulty"): parsed.difficulty = "easy"
 if not Data.DIFFICULTIES.has(parsed.difficulty): return false
 for key in ["route", "stage", "phase", "hp", "max_hp", "deck", "relics", "enemies", "hand", "draw", "discard", "exhaust", "log", "gold"]:
  if not parsed.has(key): return false
 if not Data.ROUTES.has(parsed.route) or parsed.stage < 1 or parsed.stage > 12: return false
 if parsed.phase not in ["battle", "reward", "relic", "camp", "victory", "defeat"]: return false
 if not parsed.has("reserve"): parsed.reserve = []
 if not parsed.reserve is Array: return false
 if parsed.version < 5:
  var replacements = {"first_aid":"disarm", "rally":"stockpile", "feint":"expose", "prepare":"aegis"}
  for zone in ["deck", "reserve", "hand", "draw", "discard", "exhaust", "reward_cards", "shop_cards"]:
   for i in range(parsed.get(zone, []).size()):
    var old: String = parsed[zone][i]
    var id = old.trim_suffix("+")
    if replacements.has(id): parsed[zone][i] = replacements[id] + ("+" if old.ends_with("+") else "")
 for id in parsed.deck + parsed.reserve + parsed.hand + parsed.draw + parsed.discard + parsed.exhaust + parsed.get("reward_cards", []) + parsed.get("shop_cards", []):
  if not id is String or not Data.CARDS.has(id.trim_suffix("+")): return false
 # JSON stores numbers as floats. Indices and serialized shop identifiers must be integers.
 for key in ["stage", "hp", "max_hp", "gold", "potions", "wins", "played", "damage_total", "block", "strength", "thorns", "turn", "target", "energy", "energy_max", "last_gold"]:
  if parsed.has(key): parsed[key] = int(parsed[key])
 for i in range(parsed.get("shop_sold", []).size()): parsed.shop_sold[i] = int(parsed.shop_sold[i])
 s = parsed
 # Preserve old saves and the current battle's already-shuffled piles.
 # Oversized legacy decks are capped for all future battles, without deleting cards.
 while s.deck.size() > DECK_LIMIT: s.reserve.push_front(s.deck.pop_back())
 for key in ["lifesteal", "next_lifesteal", "low_hp_crit", "next_strength", "temporary_strength", "coating", "next_block", "next_draw", "next_energy", "retain_cap", "temp_thorns", "recoverable_hp", "barrier"]:
  if not s.has(key): s[key] = 0
 s.erase("fury")
 s.erase("fury_engine")
 # Legacy small decks: equip owned reserves first, then grant basic cards.
 # Keep an ongoing battle intact; new equipped copies join its draw pile.
 while s.deck.size() < DECK_MIN:
  var id: String = s.reserve.pop_front() if not s.reserve.is_empty() else ("strike" if s.deck.size() % 2 == 0 else "guard")
  s.deck.append(id)
  if s.phase == "battle": s.draw.append(id)
 # Former one-use skills become recyclable; preserve every copy and upgrade.
 for i in range(s.exhaust.size() - 1, -1, -1):
  if Data.card(s.exhaust[i]).kind != "能力" and not Data.card(s.exhaust[i]).get("exhaust", false):
   s.discard.append(s.exhaust[i])
   s.exhaust.remove_at(i)
 if not s.has("last_acquired_zone"): s.last_acquired_zone = "deck"
 while s.hand.size() > Data.CONFIG.hand_limit: s.draw.append(s.hand.pop_back())
 for enemy in s.enemies:
  if not enemy.has("frozen"): enemy.frozen = 0
 if not s.has("turn_cards_played"): s.turn_cards_played = 0
 migrate_balance_state(s)
 var checkpoint: Dictionary = s.get("battle_checkpoint", {})
 if checkpoint.has("state"): migrate_balance_state(checkpoint.state)
 rng.randomize()
 if s.has("rng_state"): rng.state = int(s.rng_state)
 s.erase("rng_state")
 return true

func migrate_balance_state(state: Dictionary) -> void:
 if not state.has("fate_triggers"):
  state.fate_triggers = 1 if state.get("fate_triggered", false) else 0
 state.erase("fate_triggered")
 # Keep legacy extra copies in reserve, but equip at most one ability.
 var unique_equipped = false
 if not state.has("reserve"): state.reserve = []
 var equipped: Array = []
 for id in state.get("deck", []):
  if id.trim_suffix("+") == "rage_slash":
   if unique_equipped:
    state.reserve.append(id)
    continue
   unique_equipped = true
  equipped.append(id)
 state.deck = equipped
 while state.deck.size() < DECK_MIN:
  state.deck.append("strike" if state.deck.size() % 2 == 0 else "guard")
 var owns_unique = false
 for id in state.deck + state.reserve:
  if id.trim_suffix("+") == "rage_slash": owns_unique = true
 if owns_unique:
  for zone in ["reward_cards", "shop_cards"]:
   var cards: Array = []
   var sold: Array = []
   for i in range(state.get(zone, []).size()):
    var id: String = state[zone][i]
    if id.trim_suffix("+") == "rage_slash": continue
    if zone == "shop_cards" and i in state.get("shop_sold", []): sold.append(cards.size())
    cards.append(id)
   state[zone] = cards
   if zone == "shop_cards": state.shop_sold = sold
 state.potions = clampi(int(state.get("potions", 0)), 0, 2)
 state.erase("shop_removed")
 if not state.has("low_hp_crit_threshold"):
  state.low_hp_crit_threshold = 45 if state.get("low_hp_crit", 0) >= 60 else 30
 if not state.has("barrier_reflects"): state.barrier_reflects = []
 var charges = maxi(0, int(state.get("barrier", 0)))
 while state.barrier_reflects.size() < charges: state.barrier_reflects.append(0)
 if state.barrier_reflects.size() > charges: state.barrier_reflects.resize(charges)
 for enemy in state.get("enemies", []):
  for status in ["weak", "vulnerable"]:
   var duration = maxi(0, int(enemy.get(status, 0)))
   enemy[status] = mini(duration, 1) if state.get("version", 0) < 8 else duration
 state.version = 8

func normalize_numbers(value: Variant) -> Variant:
 # This schema uses whole numbers only; JSON decodes every number as a float.
 if value is float: return int(value)
 if value is Array:
  for i in range(value.size()): value[i] = normalize_numbers(value[i])
 elif value is Dictionary:
  for key in value: value[key] = normalize_numbers(value[key])
 return value

