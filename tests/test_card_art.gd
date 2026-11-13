extends SceneTree
## 检查所有基础/升级卡资源、外壳比例、文字越界与实际界面的卡牌入口。
const Main = preload("res://main.tscn")
const Data = preload("res://Game/Scripts/CardSystem/CardCatalog.gd")
const Art = preload("res://Game/Scripts/CardSystem/CardArtCatalog.gd")
var ui: Control
var failures: Array[String] = []
var checks = 0
const OUTPUT = "res://../output/卡牌拆分/正式接入/验收预览/"

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  failures.append(title)
  printerr("FAIL: ", title)

func settle() -> void:
 for _i in range(6): await process_frame

func capture(filename: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUTPUT + filename + ".png")

func validate_face(face: Control, id: String) -> void:
 var design: Control = face.design
 check(design.get_node("CardCost").text == Data.cost_text(Data.card(id)), "live cost " + id)
 check(design.get_node("CardTitle").text == Data.card(id).name, "live title " + id)
 check(is_equal_approx(design.scale.x, design.scale.y), "uniform scale " + id)
 check(Rect2(Vector2(-0.1, -0.1), face.size + Vector2(0.2, 0.2)).encloses(Rect2(design.position, design.size * design.scale)), "face fits " + id)
 for child in design.get_children():
  if child is Label:
   check(Rect2(Vector2.ZERO, design.size).encloses(child.get_rect()), "text fits shell " + id + "/" + child.name)
   if child.name == "CardDescription":
    check(child.get_line_count() * child.get_line_height() <= 351, "description fully fits " + id)
 check(design.get_node("CardIllustration").get_index() < design.get_node("CardShell").get_index(), "art behind shell " + id)

func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
 root.size = Vector2i(1600, 900)
 ui = Main.instantiate()
 root.add_child(ui)
 await settle()
 var partial = "--partial" in OS.get_cmdline_user_args()
 check(Art.catalog.cards.size() == Data.CARDS.size(), "manifest covers all cards")
 var unique_paths = {}
 for id in Data.CARDS:
  var entry = Art.entry(id)
  check(entry.get("route") == Data.card(id).route, "correct route " + id)
  check(Art.shell(id) != null, "shell loads " + id)
  check(not unique_paths.has(entry.illustration), "dedicated illustration " + id)
  unique_paths[entry.illustration] = true
  if not partial:
   check(Art.illustration(id) != null, "illustration loads " + id)
   check(Art.illustration(id) == Art.illustration(id + "+"), "upgrade reuses art " + id)
  for suffix in ["", "+"]:
   var card: Button = ui.card_view(id + suffix, func(): pass)
   card.size = Vector2(190, 286)
   root.add_child(card)
   await process_frame
   validate_face(card.get_node("CardArtwork"), id + suffix)
   card.queue_free()
 await settle()
 # 一张四路线代表卡，使用真实渲染组件。
 ui.hide()
 var showcase = Control.new()
 showcase.name = "CardShowcase"
 showcase.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_child(showcase)
 var i = 0
 for id in ["strike", "rage_slash", "thorn_armor", "coating"]:
  var card: Button = ui.card_view(id, func(): pass)
  card.position = Vector2(50 + i * 390, 110)
  card.size = Vector2(330, 630)
  showcase.add_child(card)
  i += 1
 await settle()
 await capture("四路线卡牌实机")
 for route in ["neutral", "fury", "bastion", "venom"]:
  var ids = Data.sorted_card_ids(route)
  var columns = 5 if route == "neutral" else 4
  var page_size = columns * 2
  for page in range(ceili(float(ids.size()) / page_size)):
   for child in showcase.get_children(): child.queue_free()
   await settle()
   for n in range(page * page_size, mini(ids.size(), (page + 1) * page_size)):
    var index = n % page_size
    var card: Button = ui.card_view(ids[n], func(): pass)
    var cell_width = 1600.0 / columns
    card.position = Vector2((index % columns) * cell_width + 14, floorf(float(index) / columns) * 440 + 12)
    card.size = Vector2(cell_width - 28, 420)
    showcase.add_child(card)
   await settle()
   await capture("全卡牌_" + route + ("" if page == 0 else "_02"))
 showcase.queue_free()
 root.size = Vector2i(1600, 900)
 ui.show()
 ui.game.new_run("fury", 12113)
 var random_card: Button = ui.card_view("whirlwind", func(): pass)
 check(random_card.get_node("CardArtwork/CardDesign/CardHint").text == "随机敌人", "random card target hint")
 random_card.free()
 ui.game.s.hand = ["strike", "guard", "cleave", "rage", "warcry"]
 ui.screen = "run"
 ui.render()
 await settle()
 await capture("战斗手牌_1600x900")
 for dimensions in [Vector2i(1280, 720), Vector2i(1024, 768)]:
  root.size = dimensions
  await settle()
  var hand = ui.find_child("HandScroll", true, false)
  for card in hand.cards.get_children(): validate_face(card.get_node("CardArtwork"), str(card.get_meta("card_id")))
  await capture("战斗手牌_%dx%d" % [dimensions.x, dimensions.y])
 root.size = Vector2i(1600,900)
 ui.show_catalog("neutral")
 await settle()
 check(ui.find_child("CardArtwork", true, false) != null, "catalog uses shared art")
 await capture("卡牌图鉴")
 ui.close_modal()
 ui.show_catalog_card("strike", "neutral")
 await settle()
 await capture("升级前后对照")
 ui.close_modal()
 ui.show_card_info("rage_slash+")
 await settle()
 check(ui.find_child("CardInfoDialog", true, false) != null, "detail dialog renders")
 check(ui.find_child("CardArtwork", true, false) != null, "detail uses shared art")
 await capture("长效果卡牌详情")
 ui.close_modal()
 ui.confirm_deck_change(0, "upgrade")
 await settle()
 await capture("锻造对照")
 ui.close_modal()
 var report = {"checks":checks, "failed":failures.size(), "failures":failures, "cards":Data.CARDS.size(), "partial":partial}
 var file = FileAccess.open(OUTPUT + "界面核验.json", FileAccess.WRITE)
 file.store_string(JSON.stringify(report, "  "))
 print("CARD ART CHECKS: ", checks, " passed: ", checks - failures.size(), " failed: ", failures.size())
 ui.queue_free()
 await settle()
 quit(0 if failures.is_empty() else 1)
