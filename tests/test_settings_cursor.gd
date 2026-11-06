extends SceneTree
## 使用 tests/run_checks.ps1 的独立测试账户目录，避免改写玩家设置。
const MAIN = preload("res://Game/Scenes/Main.tscn")
const OUTPUT = "res://test-results/settings-cursor/"
var ui
var checks = 0
var errors = 0

func _initialize() -> void:
 call_deferred("run")

func expect(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  errors += 1
  printerr("FAIL: ", message)

func settle() -> void:
 for _frame in range(6): await process_frame

func capture(filename: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 expect(root.get_texture().get_image().save_png(OUTPUT + filename + ".png") == OK, "capture " + filename)

func mouse_button(at: Vector2, pressed: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
 var event = InputEventMouseButton.new()
 event.position = at
 event.global_position = at
 event.button_index = button
 event.pressed = pressed
 event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed and button == MOUSE_BUTTON_LEFT else 0
 root.push_input(event, true)

func click(at: Vector2) -> void:
 var motion = InputEventMouseMotion.new()
 motion.position = at
 root.push_input(motion, true)
 mouse_button(at, true)
 mouse_button(at, false)
 await settle()

func find_label(text: String, node: Node = ui.modal) -> Label:
 if node is Label and node.text == text: return node
 for child in node.get_children():
  var result = find_label(text, child)
  if result != null: return result
 return null

func check_bounds(node: Node) -> void:
 if node is Control and node.is_visible_in_tree():
  var rect: Rect2 = node.get_global_rect()
  expect(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= ui.size.x + 1 and rect.end.y <= ui.size.y + 1, "settings stays in canvas: " + str(node.name))
 for child in node.get_children(): check_bounds(child)

func run() -> void:
 if not "/.test_profile/" in OS.get_user_data_dir().replace("\\", "/"):
  printerr("Run with APPDATA and LOCALAPPDATA pointing to the project's .test_profile directories.")
  quit(1)
  return
 DirAccess.make_dir_recursive_absolute(OUTPUT)
 root.size = Vector2i(1280, 720)
 ui = MAIN.instantiate()
 root.add_child(ui)
 await settle()
 ui.return_home()
 await settle()
 ui.show_settings()
 await settle()

 for channel in ["master", "music", "effects"]:
  var slider: HSlider = ui.find_child("Volume_" + channel, true, false)
  for style_name in ["slider", "grabber_area", "grabber_area_highlight"]:
   expect(slider.get_theme_stylebox(style_name).get_minimum_size().y >= 10, channel + " has a visible track: " + style_name)
  expect(slider.size.x >= 280 and slider.size.y >= 38, channel + " retains a generous drag area")
  for value in [0, 35, 100]:
   slider.value = value
   await settle()
   expect(is_equal_approx(float(ui.settings.get(channel + "_volume")), value / 100.0), channel + " updates setting")
   var badge: Label = slider.get_parent().get_child(2).get_child(0)
   expect(badge.text == "%d%%" % value, channel + " updates percent label")
   var bus_name: String = {"master": "Master", "music": "Music", "effects": "Effects"}[channel]
   var bus = AudioServer.get_bus_index(bus_name)
   expect(AudioServer.is_bus_mute(bus) == (value == 0), channel + " mutes only at zero")
   if value > 0:
    expect(is_equal_approx(AudioServer.get_bus_volume_linear(bus), value / 100.0), channel + " updates audio immediately")
  ui.settings.load_settings()
  expect(is_equal_approx(float(ui.settings.get(channel + "_volume")), 1.0), channel + " persists")

 for entry in [["基础设置", 31], ["声音设置", 24], ["总音量", 18], ["调整后立即生效", 15], ["选择窗口或全屏显示", 14], ["版权、字体授权及 AI 资产声明", 16], ["Esc", 14]]:
  var label = find_label(entry[0])
  expect(label != null and label.get_theme_font_size("font_size") == entry[1], "larger text: " + entry[0])

 # Click, drag, keyboard and end values exercise the real HSlider input path.
 var master: HSlider = ui.find_child("Volume_master", true, false)
 var rect = master.get_global_rect()
 await click(rect.get_center())
 expect(master.value > 45 and master.value < 55, "clicking the track positions the knob")
 var start = rect.get_center()
 mouse_button(start, true)
 var motion = InputEventMouseMotion.new()
 motion.position = Vector2(rect.end.x - 18, rect.get_center().y)
 motion.relative = motion.position - start
 motion.button_mask = MOUSE_BUTTON_MASK_LEFT
 root.push_input(motion, true)
 mouse_button(motion.position, false)
 await settle()
 expect(master.value >= 95, "dragging still reaches the upper end")
 master.grab_focus()
 var key = InputEventKey.new()
 key.keycode = KEY_LEFT
 key.pressed = true
 var previous = master.value
 root.push_input(key, true)
 expect(master.value < previous, "keyboard still adjusts volume")
 master.release_focus()

 var cursor = ui.game_cursor
 var cursor_image: Image = cursor.texture.get_image()
 var original: Image = cursor.ART.get_image()
 original.resize(48, 48, Image.INTERPOLATE_LANCZOS)
 expect(cursor_image.get_size() == Vector2i(48, 48) and cursor_image.get_pixel(0, 0).a == 0, "cursor keeps its compact size and transparent margin")
 var shadow_pixels = 0
 for y in range(48):
  for x in range(48):
   if original.get_pixel(x, y).a < 0.01 and cursor_image.get_pixel(x, y).a > 0.02: shadow_pixels += 1
 expect(shadow_pixels > 15, "cursor has a soft shadow outside its original silhouette")
 cursor_image.save_png(OUTPUT + "小剑指针_淡阴影.png")

 master.value = 65
 ui.find_child("Volume_music", true, false).value = 85
 ui.find_child("Volume_effects", true, false).value = 45
 await create_timer(0.4).timeout
 for dimensions in [Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(960, 540)]:
  root.size = dimensions
  await settle()
  check_bounds(ui.modal)
  await capture("基础设置_%dx%d" % [dimensions.x, dimensions.y])

 root.size = Vector2i(1280, 720)
 await settle()
 var layer: CanvasLayer = cursor.click_layer
 await create_timer(0.4).timeout
 var point = Vector2(760, 440)
 mouse_button(point, true)
 expect(layer.get_child_count() == 1 and layer.get_child(0).position == point, "left press shows feedback at the click location")
 mouse_button(point, false)
 expect(layer.get_child_count() == 1, "release does not duplicate feedback")
 mouse_button(point, true, MOUSE_BUTTON_RIGHT)
 mouse_button(point, false, MOUSE_BUTTON_RIGHT)
 expect(layer.get_child_count() == 1, "right click does not duplicate left-click feedback")
 await create_timer(0.06).timeout
 await capture("点击金色光圈")
 await create_timer(0.4).timeout
 expect(layer.get_child_count() == 0, "click feedback expires")
 for _index in range(14):
  mouse_button(point, true)
  mouse_button(point, false)
 expect(layer.get_child_count() <= 8, "rapid clicks keep effects bounded")
 await create_timer(0.4).timeout
 expect(layer.get_child_count() == 0, "rapid-click effects clean themselves up")

 var close = ui.find_child("CloseSettingsButton", true, false)
 await click(close.get_global_rect().get_center())
 expect(ui.modal == null and layer.get_child_count() > 0, "feedback does not block the close button")
 ui.show_settings()
 await settle()
 var restore = find_label("恢复默认").get_parent()
 await click(restore.get_global_rect().get_center())
 expect(is_equal_approx(ui.settings.master_volume, 0.8) and is_equal_approx(ui.settings.music_volume, 1.0) and is_equal_approx(ui.settings.effects_volume, 0.7), "restore defaults still works")
 expect(ui.find_child("Volume_master", true, false).value == 80 and ui.find_child("Volume_effects", true, false).value == 70, "restore defaults refreshes slider positions")
 await click(find_label("查看详情").get_parent().get_global_rect().get_center())
 expect(find_label("版权与授权说明") != null, "details button still opens legal text")
 await capture("版权与授权说明")
 ui.close_modal()
 ui.open_new_routes()
 await settle()
 expect(is_instance_valid(layer) and layer.layer == 100, "click layer survives screen changes above all UI")
 mouse_button(point, true)
 mouse_button(point, false)
 expect(layer.get_child_count() > 0, "click feedback also works on the route screen")
 await create_timer(0.4).timeout
 expect(layer.get_child_count() == 0, "screen changes leave no effects behind")
 ui.settings.menu_music_player.stop()
 ui.home_view_component.video.stop()
 ui.queue_free()
 await settle()
 print("SETTINGS/CURSOR CHECKS: ", checks, " passed: ", checks - errors, " failed: ", errors)
 quit(0 if errors == 0 else 1)
