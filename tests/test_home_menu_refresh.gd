extends SceneTree
## Read-only verification: never creates, replaces or removes player saves/settings.

const MAIN = preload("res://Game/Scenes/Main.tscn")
const OUTPUT = "res://test-results/home-refresh/"
var ui
var checks = 0
var errors = 0
var save_before: PackedByteArray
var settings_before: PackedByteArray
var save_existed: bool
var settings_existed: bool

func _initialize() -> void:
 call_deferred("run")

func expect(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  errors += 1
  printerr("FAIL: ", message)

func settle() -> void:
 for _i in range(5): await process_frame

func capture(filename: String) -> void:
 await RenderingServer.frame_post_draw
 expect(root.get_texture().get_image().save_png(OUTPUT + filename + ".png") == OK, "capture " + filename)

func key(code: Key) -> void:
 for pressed in [true, false]:
  var event = InputEventKey.new()
  event.keycode = code
  event.pressed = pressed
  root.push_input(event)
 await settle()

func click_at(p: Vector2) -> void:
 var motion = InputEventMouseMotion.new()
 motion.position = p
 root.push_input(motion)
 for pressed in [true, false]:
  var event = InputEventMouseButton.new()
  event.position = p
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  root.push_input(event)
 await settle()

func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUTPUT)
 save_existed = FileAccess.file_exists("user://run_save.json")
 settings_existed = FileAccess.file_exists("user://settings.cfg")
 save_before = FileAccess.get_file_as_bytes("user://run_save.json") if save_existed else PackedByteArray()
 settings_before = FileAccess.get_file_as_bytes("user://settings.cfg") if settings_existed else PackedByteArray()
 root.size = Vector2i(1600, 900)
 ui = MAIN.instantiate()
 root.add_child(ui)
 await settle()
 expect(ui.screen == "title" and ui.find_child("HomeNew", true, false) == null, "opening title remains intact")
 var video = ui.home_view_component.video
 var music = ui.settings.menu_music_player
 music.stop()
 # Stabilize window size even when the user's saved preference is fullscreen.
 DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
 root.size = Vector2i(1600, 900)
 await create_timer(0.6).timeout
 var video_time: float = video.stream_position
 await key(KEY_ENTER)
 expect(ui.screen == "home" and ui.modal == null, "opening input reveals menu only")
 expect(ui.home_view_component.video == video and video.stream_position >= video_time, "opening video continues without replacement")
 expect(not ui.home_view_component.shade.visible, "scene remains bright without global dark overlay")
 var start: TextureButton = ui.find_child("HomeNew", true, false)
 var resume: TextureButton = ui.find_child("HomeContinue", true, false)
 var gear: TextureButton = ui.find_child("HomeSettings", true, false)
 expect(resume.disabled == not save_existed, "continue enabled state follows existing save")
 expect(start.caption_label.text == "开始游戏" and resume.caption_label.text == "继续游戏", "engine labels are correct")
 expect(start.caption_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "label cannot intercept button input")
 expect(start.texture_normal.atlas.resource_path.contains("圆角立体版") and gear.texture_normal.atlas.resource_path.contains("圆角立体版"), "new artwork actually used by running game")
 expect(ui.find_child("HomeScreen", true, false).get_child_count() == 4, "home contains only existing logo and three controls")
 for button in [start, resume, gear]:
  var mask: BitMap = button.texture_click_mask
  expect(mask != null and not mask.get_bitv(Vector2i.ZERO), "transparent corner excluded: " + button.name)
  expect(mask.get_bitv(mask.get_size() / 2), "button center is clickable: " + button.name)
  expect(button.tooltip_text.is_empty(), "no floating tooltip: " + button.name)
 await create_timer(1.2).timeout
 await capture("主界面_1600x900_实际状态")
 await click_at(start.get_global_rect().position + Vector2(1, 1))
 expect(ui.screen == "home", "transparent start corner does not trigger route selection")
 await click_at(gear.get_global_rect().position + Vector2(1, 1))
 expect(ui.modal == null, "transparent gear corner does not open settings")
 await click_at(gear.get_global_rect().get_center())
 expect(ui.modal != null and ui.find_child("Volume_master", true, false) != null, "mouse click opens settings through new gear")
 ui.close_modal()
 gear.release_focus()
 # Preview the enabled bronze artwork without writing a save.
 resume.disabled = false
 resume.update_feedback()
 await create_timer(0.16).timeout
 await capture("主界面_1600x900_启用样式")
 start.grab_focus()
 await key(KEY_DOWN)
 expect(root.gui_get_focus_owner() == (gear if not save_existed else resume), "keyboard focus order respects actual save availability")
 gear.grab_focus()
 await key(KEY_ENTER)
 expect(ui.modal != null, "keyboard activates gear")
 ui.close_modal()
 gear.release_focus()
 var motion = InputEventMouseMotion.new()
 motion.position = start.get_global_rect().get_center()
 root.push_input(motion)
 await create_timer(0.16).timeout
 expect(start.scale.x > 1.0 and start.self_modulate.r > 1.0 and start.self_modulate.r <= 1.07, "hover uses restrained warm highlight")
 await capture("主按钮_悬停")
 var press = InputEventMouseButton.new()
 press.position = start.get_global_rect().get_center()
 press.button_index = MOUSE_BUTTON_LEFT
 press.pressed = true
 root.push_input(press)
 await create_timer(0.16).timeout
 expect(start.scale.x < 1.0 and ui.screen == "home", "press feedback before activation")
 await capture("主按钮_按下")
 press = press.duplicate()
 press.pressed = false
 root.push_input(press)
 await settle()
 expect(ui.screen == "routes", "actual release opens route selection")
 ui.return_home()
 await settle()
 for dimensions in [Vector2i(1280, 720), Vector2i(1024, 768)]:
  root.size = dimensions
  await create_timer(0.2).timeout
  start = ui.find_child("HomeNew", true, false)
  resume = ui.find_child("HomeContinue", true, false)
  gear = ui.find_child("HomeSettings", true, false)
  expect(is_equal_approx(ui.size.x / ui.size.y, 16.0 / 9.0), "aspect maintained " + str(dimensions))
  expect(start.size.x < ui.size.x * 0.2 and absf(start.get_global_rect().get_center().x - ui.size.x * 0.5) < 1.0, "compact centered buttons " + str(dimensions))
  expect(start.get_global_rect().end.y < resume.get_global_rect().position.y and resume.get_global_rect().end.y < ui.size.y, "button gaps and bottom margin " + str(dimensions))
  expect(gear.get_global_rect().position.x > ui.size.x * 0.9 and gear.get_global_rect().end.x < ui.size.x, "small gear stays inside viewport " + str(dimensions))
  await capture("主界面_%dx%d" % [dimensions.x, dimensions.y])
 # Exercise missing-save appearance locally, without touching the user's files.
 resume.disabled = true
 resume.update_feedback()
 await create_timer(0.16).timeout
 expect(resume.self_modulate.a < 1.0 and resume.caption_label.text == "继续游戏", "disabled artwork preserves readable label")
 await capture("继续游戏_禁用样式")
 expect(FileAccess.file_exists("user://run_save.json") == save_existed, "save file existence unchanged")
 expect(FileAccess.file_exists("user://settings.cfg") == settings_existed, "settings file existence unchanged")
 if save_existed: expect(FileAccess.get_file_as_bytes("user://run_save.json") == save_before, "save bytes unchanged")
 if settings_existed: expect(FileAccess.get_file_as_bytes("user://settings.cfg") == settings_before, "settings bytes unchanged")
 print("HOME REFRESH CHECKS: ", checks, " PASSED: ", checks - errors, " FAILED: ", errors)
 ui.queue_free()
 await process_frame
 ui = null
 quit(0 if errors == 0 else 1)
