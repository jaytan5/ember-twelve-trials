extends SceneTree
const MAIN = preload("res://main.tscn")
var ui
var checks = 0
var errors = 0

func _initialize() -> void:
 call_deferred("run")

func expect(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  errors += 1
  printerr("FAIL: ",title)

func settle() -> void:
 for _frame in range(6): await process_frame

func click(control: Control) -> void:
 var p = control.get_global_rect().get_center()
 var motion = InputEventMouseMotion.new()
 motion.position = p
 root.push_input(motion,true)
 for pressed in [true,false]:
  var event = InputEventMouseButton.new()
  event.position = p
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  root.push_input(event,true)
 await settle()

func capture(filename: String) -> void:
 await settle()
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test-results/map-art-"+filename+".png")

func map_screen():
 return ui.find_child("AdventureMapScreen",true,false)

func actor_layout(screen) -> Array:
 return [screen.hero.position,screen.hero.size,screen.foot_shadow.position,screen.foot_shadow.size,screen.glow.position,screen.glow.size]

func open_map() -> void:
 ui.screen = "map"
 ui.render()
 await settle()

func run() -> void:
 root.size = Vector2i(1600,900)
 ui = MAIN.instantiate()
 root.add_child(ui)
 ui.game.new_run("bastion",183)
 ui.game.s.hp = 37
 await open_map()
 var screen = map_screen()
 expect(ui.layout == null and screen != null,"independent full-screen map replaces shell header/footer")
 expect(screen.health_copy.text == "37/%d" % ui.game.s.max_hp,"HUD uses real health")
 expect(screen.health_bar.value == 37 and screen.health_bar.max_value == ui.game.s.max_hp,"health bar reflects actual ratio")
 expect(screen.design.get_node("ChapterMap/Chapter_2").texture.resource_path.ends_with("名牌_街口集市_含字.png"),"chapter two corrected artwork")
 expect(screen.design.get_node("SettingsButton").size == Vector2(89,89),"round settings icon keeps equal aspect")
 expect(not screen.enter_button.texture_click_mask.get_bitv(Vector2i.ZERO),"transparent corners excluded from button hits")
 await capture("01-current")
 var state = ui.game.s.duplicate(true)
 var rng_before = ui.game.rng.state
 for stage in range(1,13):
  await click(screen.stage_buttons[stage-1])
  expect(screen.selected_stage == stage,"real node click selects %02d" % stage)
  expect(screen.glow.position+Vector2(90,55) == screen.POINTS[0],"unreached preview keeps glow on reached disc %02d" % stage)
  expect(screen.hero.position+Vector2(screen.hero.size.x*.5,screen.hero.size.y+16) == screen.POINTS[0],"unreached preview keeps hero on reached disc %02d" % stage)
  expect(screen.enter_button.disabled == (stage != 1),"entry only for actual current stage %02d" % stage)
  expect(ui.game.s == state and ui.game.rng.state == rng_before,"browsing leaves adventure and RNG unchanged")
  if stage in [4,7,12]: await capture("%02d-preview" % stage)
 await click(screen.enter_button)
 expect(ui.screen == "map","locked stage cannot enter")
 await click(screen.stage_buttons[0])
 var button_rect = screen.enter_button.get_global_rect()
 screen.enter_button.update_feedback(true)
 expect(screen.enter_button.get_global_rect() == button_rect,"pressed art does not move or stretch")
 screen.enter_button.update_feedback()
 await click(screen.design.get_node("SettingsButton"))
 expect(is_instance_valid(ui.modal),"map settings opens existing modal")
 await click(screen.stage_buttons[8])
 expect(screen.selected_stage == 1,"modal blocks map interaction")
 ui.close_modal()
 await click(screen.enter_button)
 expect(ui.screen == "run" and ui.game.s == state and ui.game.rng.state == rng_before,"entry resumes battle without changing state")
 for phase in ["reward","relic","camp","victory","defeat"]:
  ui.game.s.phase = phase
  await open_map()
  screen = map_screen()
  state = ui.game.s.duplicate(true)
  expect(not screen.enter_button.disabled,"current stage remains enterable in "+phase)
  await click(screen.enter_button)
  expect(ui.screen == "run" and ui.game.s == state,"map restores phase without reset: "+phase)
 ui.game.s.phase = "battle"
 for stage in [3,6,12]:
  ui.game.s.stage = stage
  ui.game.s.wins = stage-1
  await open_map()
  screen = map_screen()
  expect(screen.selected_stage == stage,"reopen selects actual progress %d" % stage)
  await click(screen.stage_buttons[0])
  expect(screen.enter_button.disabled,"completed stage preview cannot replay")
  expect(screen.hero.position+Vector2(screen.hero.size.x*.5,screen.hero.size.y+16) == screen.POINTS[0],"reached completed stage can still move hero")
  if stage < 12:
   var reached_layout = actor_layout(screen)
   await click(screen.stage_buttons[11])
   expect(screen.selected_stage == 12 and screen.title_copy.text == "12 汤山洞穴","unreached stage still updates detail panel")
   expect(actor_layout(screen) == reached_layout,"future preview preserves completed-stage hero size shadow and glow")
   expect(screen.enter_button.disabled,"unreached preview remains locked after completed stage")
  await click(screen.stage_buttons[stage-1])
  expect(not screen.enter_button.disabled,"current stage remains enterable after browsing")
  expect(screen.hero.position+Vector2(screen.hero.size.x*.5,screen.hero.size.y+16) == screen.POINTS[stage-1],"current stage places hero on reached disc")
  if stage < 12:
   var current_layout = actor_layout(screen)
   await click(screen.stage_buttons[stage])
   expect(actor_layout(screen) == current_layout,"next unreached stage does not move hero shadow or glow")
 ui.game.s.stage = 4
 ui.game.s.wins = 3
 for dimensions in [Vector2i(1280,720),Vector2i(1024,768)]:
  root.size = dimensions
  await open_map()
  screen = map_screen()
  expect(is_equal_approx(screen.design.scale.x,screen.design.scale.y),"uniform map scaling "+str(dimensions))
  expect(screen.title_copy.text == "04 街口集市","detail title uses corrected chapter name")
  var scaled_layout = actor_layout(screen)
  await click(screen.stage_buttons[5])
  expect(screen.selected_stage == 6,"scaled real click selects stage")
  expect(actor_layout(screen) == scaled_layout,"scaled future preview keeps hero shadow and glow in place")
  await capture("scaled-%dx%d" % [dimensions.x,dimensions.y])
 root.size = Vector2i(1600,900)
 await open_map()
 await capture("04-current")
 state = ui.game.s.duplicate(true)
 await click(map_screen().design.get_node("MapBack"))
 expect(ui.screen == "home" and ui.game.s == state,"back saves and returns home without changing adventure")
 print("ADVENTURE MAP ART: %d checks, %d errors" % [checks,errors])
 ui.queue_free()
 await settle()
 quit(1 if errors else 0)
