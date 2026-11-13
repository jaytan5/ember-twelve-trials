extends RefCounted
## 美术资源按稳定卡牌 ID 索引，升级卡复用基础卡插图。
const ROOT = "res://Game/Assets/Cards/正式卡牌/"
const MANIFEST = preload("res://Game/Assets/Cards/正式卡牌/卡牌资产映射.json")
static var catalog: Dictionary = MANIFEST.data
static var textures: Dictionary = {}

static func entry(id: String) -> Dictionary:
 return catalog.cards.get(id.trim_suffix("+"), {})

static func texture(relative_path: String) -> Texture2D:
 if not textures.has(relative_path):
  var path = ROOT + relative_path
  textures[relative_path] = load(path) if ResourceLoader.exists(path) else null
 return textures[relative_path]

static func shell(id: String) -> Texture2D:
 var route: String = entry(id).get("route", "neutral")
 return texture(entry(id).get("shell", catalog.shells.get(route, catalog.shells.neutral)))

static func illustration(id: String) -> Texture2D:
 return texture(entry(id).get("illustration", ""))
