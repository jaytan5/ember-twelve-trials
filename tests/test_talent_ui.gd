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

func click_at(position: Vector2) -> void:
 var motion = InputEventMouseMotion.new()
 motion.position = position
 root.push_input(motion)
 for pressed in [true,false]:
  var event = InputEventMouseButton.new()
  event.position = position
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  root.push_input(event)
 await settle()

func click(control: Control) -> void:
 await click_at(control.get_global_rect().get_center())

func key(code: Key) -> void:
 for pressed in [true,false]:
  var event = InputEventKey.new()
  event.keycode = code
  event.pressed = pressed
  root.push_input(event)
 await settle()

func capture(name_value: String) -> void:
 await settle()
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test-results/talent-"+name_value+".png")

func check_live_glow(control: Control, label_value: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await create_timer(0.2).timeout
 await RenderingServer.frame_post_draw
 var bounds = Rect2i(control.get_global_rect().grow(18))
 var first = root.get_texture().get_image().get_region(bounds)
 await create_timer(0.65).timeout
 await RenderingServer.frame_post_draw
 var second = root.get_texture().get_image().get_region(bounds)
 var changed = 0
 for y in range(0,first.get_height(),2):
  for x in range(0,first.get_width(),2):
   var a = first.get_pixel(x,y)
   var b = second.get_pixel(x,y)
   if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.025: changed += 1
 expect(changed > 20,"live breathing glow changes visible pixels: " + label_value)

func run() -> void:
 root.size = Vector2i(1600,900)
 ui = MAIN.instantiate()
 root.add_child(ui)
 ui.open_new_routes()
 await settle()
 var screen = ui.find_child("TalentScreen",true,false)
 expect(ui.layout == null and screen != null,"talents use an independent full-screen scene")
 expect(screen.get_children().filter(func(child): return child is BaseButton).size() == 9,"nine standalone interactive modules")
 expect(ui.find_child("SettingsButton",true,false) == null,"old shell header removed from talent screen")
 var venom = ui.find_child("Route_venom",true,false)
 var fury = ui.find_child("Route_fury",true,false)
 var bastion = ui.find_child("Route_bastion",true,false)
 expect(venom.position.x < fury.position.x and fury.position.x < bastion.position.x,"fury appears between venom and bastion")
 for route in ["venom","fury","bastion"]:
  var button = ui.find_child("Route_"+route,true,false)
  expect(button.texture_click_mask != null and not button.texture_click_mask.get_bitv(Vector2i.ZERO),"transparent corners are excluded: "+route)
  await click(button)
  expect(ui.selected_route == route,"real card click chooses "+route)
  expect(screen.route_buttons.values().filter(func(item): return item.button_pressed).size() == 1,"one selected route")
  expect(button.outline_material.get_shader_parameter("highlight"),"selected route has outline: "+route)
  expect(button.get_node("SelectionBadge").visible,"chosen route has an explicit selection marker")
  expect(screen.route_buttons.values().filter(func(item): return item.get_node("SelectionBadge").visible).size() == 1,"only chosen route shows its badge")
  # Clicking through a transparent corner must not change selection or focus a card.
  var other = fury if route != "fury" else venom
  await click_at(other.get_global_rect().position + Vector2(1,1))
  expect(ui.selected_route == route,"empty card corner does not select neighboring route")
  await capture(route)
 for difficulty in ["easy","normal","hard","legendary"]:
  await click(ui.find_child("Difficulty_"+difficulty,true,false))
  expect(ui.selected_difficulty == difficulty,"real difficulty click: "+difficulty)
  expect(screen.difficulty_buttons.values().filter(func(item): return item.button_pressed).size() == 1,"one selected difficulty")
  expect(screen.difficulty_buttons.values().filter(func(item): return item.get_node("SelectionBadge").visible).size() == 1,"only chosen difficulty shows its check")
  await capture("difficulty-"+difficulty)
 venom.grab_focus()
 await create_timer(0.2).timeout
 expect(not venom.outline_material.get_shader_parameter("highlight"),"keyboard focus does not imitate a selected route")
 expect(not venom.get_node("SelectionBadge").visible,"focus does not move selected badge")
 await key(KEY_RIGHT)
 expect(root.gui_get_focus_owner() == fury,"keyboard follows visual card order")
 await key(KEY_ENTER)
 expect(ui.selected_route == "fury","keyboard confirms route")
 await create_timer(0.2).timeout
 expect(fury.scale.x > venom.scale.x+0.04,"selected card is visibly larger")
 expect(fury.self_modulate.r > venom.self_modulate.r+0.18,"selected card is visibly brighter")
 expect(venom.outline_material.get_shader_parameter("saturation") < 0.7,"unselected artwork is subdued")
 for button in screen.route_buttons.values():
  expect(button.get_node("RouteDescription").text.replace("\n", "").length() == 8,"eight-character description is independent text: " + button.name)
 for button in screen.difficulty_buttons.values():
  expect(button.get_node("DifficultyName").text.length() == 2,"difficulty uses independent crisp text: " + button.name)
 await check_live_glow(fury,"route")
 await check_live_glow(screen.difficulty_buttons[ui.selected_difficulty],"difficulty")
 await capture("premium-3d")
 expect(ui.find_child("ConfirmRoute",true,false).caption.text == "开始冒险","new adventure caption is exact")
 for dimensions in [Vector2i(1280,720),Vector2i(1024,768)]:
  root.size = dimensions
  await settle()
  var bounds = Rect2(Vector2.ZERO,ui.size)
  for child in screen.get_children():
   if child is BaseButton:
    expect(bounds.encloses(child.get_global_rect()),"module stays in canvas: "+child.name+str(dimensions))
  await capture("scaled-%dx%d" % [dimensions.x,dimensions.y])
 root.size = Vector2i(1600,900)
 ui.game.new_run("fury",123,"hard")
 ui.game.s.hp -= 7
 ui.game.save_run()
 var snapshot = ui.game.s.duplicate(true)
 ui.return_home()
 await settle()
 await click(ui.find_child("HomeContinue",true,false))
 expect(ui.resuming and ui.screen == "routes","original home continue enters new talent view")
 screen = ui.find_child("TalentScreen",true,false)
 for button in screen.route_buttons.values() + screen.difficulty_buttons.values():
  expect(button.disabled,"saved selection stays locked: "+button.name)
 await click(ui.find_child("Route_venom",true,false))
 expect(ui.selected_route == "fury","locked card click cannot change saved route")
 expect(ui.find_child("ConfirmRoute",true,false).caption.text == "继续冒险","saved game confirmation caption is clear")
 expect(ui.find_child("SavedRouteLock",true,false) != null,"saved route lock is visible")
 await capture("continue-locked")
 await click(ui.find_child("ConfirmRoute",true,false))
 expect(ui.screen == "map" and ui.game.s == snapshot,"confirming keeps full saved state")
 ui.open_new_routes()
 await settle()
 await click(ui.find_child("TalentBack",true,false))
 expect(ui.screen == "home" and ui.find_child("HomeNew",true,false) != null,"back returns to original working home")
 expect(ui.home_view_component.video.is_playing(),"original home video resumes")
 await capture("restored-home")
 print("TALENT UI CHECKS: ",checks," passed: ",checks-errors," failed: ",errors)
 ui.settings.menu_music_player.stop()
 ui.home_view_component.video.stop()
 await create_timer(0.2).timeout
 ui.queue_free()
 await process_frame
 quit(0 if errors == 0 else 1)
