extends SceneTree
## Export the independent Premium Stylized 3D masters; never cut glows out of a screenshot.
const BASE = "res://Game/Assets/UI/TalentSelection/"
const SOURCE = BASE + "Source/Premium3D/"

func _initialize() -> void:
 for asset in ["RouteVenom","RouteFury","RouteBastion","DifficultyEasy","DifficultyNormal","DifficultyHard","DifficultyLegendary","RedGoldBar"]:
  var sprite = Image.load_from_file(SOURCE + asset + ".png")
  if sprite == null:
   push_error("Missing independent sprite: " + asset)
   quit(1)
   return
  sprite.convert(Image.FORMAT_RGBA8)
  # Use opaque artwork to measure padding; keep original antialiased edge pixels intact.
  var min_point = sprite.get_size()
  var max_point = Vector2i.ZERO
  for y in range(sprite.get_height()):
   for x in range(sprite.get_width()):
    if sprite.get_pixel(x,y).a >= 0.2:
     min_point = min_point.min(Vector2i(x,y))
     max_point = max_point.max(Vector2i(x,y))
  var bounds = Rect2i(min_point,max_point-min_point+Vector2i.ONE).grow(4)
  bounds = bounds.intersection(Rect2i(Vector2i.ZERO,sprite.get_size()))
  sprite.get_region(bounds).save_png(BASE+asset+".png")
  print("EXPORTED 3D MODULE: ",asset)
 var manifest = FileAccess.get_file_as_string(SOURCE+"modules.json")
 var background = Image.load_from_file(SOURCE+"VillageDisplayBackground.png")
 if background != null: background.save_png(BASE+"VillageDisplayBackground.png")
 FileAccess.open(BASE+"modules.json",FileAccess.WRITE).store_string(manifest)
 quit()
