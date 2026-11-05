extends Node

const BACKGROUND_VIDEO = preload("res://Game/Assets/Videos/MainMenu/开篇循环背景动画.ogv")
const TITLE_LOGO = preload("res://Game/Assets/UI/Titles/小泥团出击-透明Logo.png")
const MENU_BUTTON = preload("res://Game/Scenes/MainMenu/HomeMenuButton.gd")
const START_ART = preload("res://Game/Assets/UI/MainMenu/圆角立体版/主按钮_红金.png")
const CONTINUE_ART = preload("res://Game/Assets/UI/MainMenu/圆角立体版/次按钮_古铜棕.png")
const SETTINGS_ART = preload("res://Game/Assets/UI/MainMenu/圆角立体版/设置_圆齿轮.png")
# These regions include the alpha-faded contact shadows, not the export margins.
const START_REGION = Rect2(137, 99, 1890, 560)
const CONTINUE_REGION = Rect2(127, 94, 1916, 568)
const SETTINGS_REGION = Rect2(127, 106, 980, 1020)
var background: Control
var video: VideoStreamPlayer
var shade: ColorRect

func update_background(ui: Control, enabled: bool) -> void:
 if not is_instance_valid(background):
  background = Control.new()
  background.name = "HomeVideoBackground"
  background.mouse_filter = Control.MOUSE_FILTER_IGNORE
  ui.add_child(background)
  background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  video = VideoStreamPlayer.new()
  video.name = "OpeningVideo"
  video.stream = BACKGROUND_VIDEO
  video.expand = true
  video.loop = true
  video.volume = 0.0
  video.mouse_filter = Control.MOUSE_FILTER_IGNORE
  background.add_child(video)
  video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  shade = ColorRect.new()
  shade.color = Color(0.02, 0.04, 0.06, 0.25)
  shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
  background.add_child(shade)
  shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.visible = enabled
 shade.visible = false
 if enabled:
  if not video.is_playing(): video.play()
 else:
  video.stop()

func build_title(ui: Control) -> void:
 var title = create_canvas(ui, "TitleScreen")
 add_logo(title)
 var prompt = ui.label("按任意键开始游戏", 22, Color.WHITE)
 prompt.name = "TitlePrompt"
 prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
 prompt.add_theme_constant_override("shadow_offset_x", 1)
 prompt.add_theme_constant_override("shadow_offset_y", 2)
 title.add_child(prompt)
 prompt.anchor_left = 0.25
 prompt.anchor_right = 0.75
 prompt.anchor_top = 0.74
 prompt.anchor_bottom = 0.80

func create_canvas(ui: Control, node_name: String) -> Control:
 var canvas = Control.new()
 canvas.name = node_name
 canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ui.add_child(canvas)
 canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 return canvas

func add_logo(parent: Control) -> void:
 var logo = TextureRect.new()
 logo.name = "TitleLogo"
 logo.texture = TITLE_LOGO
 logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(logo)
 logo.anchor_left = 0.30
 logo.anchor_right = 0.70
 logo.anchor_top = 0.035
 logo.anchor_bottom = 0.355

func build_home(ui: Control) -> void:
 var home = create_canvas(ui, "HomeScreen")
 add_logo(home)
 var start = art_button(ui, home, "HomeNew", "开始游戏", START_ART, START_REGION, ui.open_new_routes)
 place_menu_button(start, 0.747)
 var resume = art_button(ui, home, "HomeContinue", "继续游戏", CONTINUE_ART, CONTINUE_REGION, ui.open_continue_routes)
 resume.disabled = not FileAccess.file_exists("user://run_save.json")
 resume.update_feedback()
 place_menu_button(resume, 0.87)
 var settings_button = art_button(ui, home, "HomeSettings", "", SETTINGS_ART, SETTINGS_REGION, ui.show_settings)
 settings_button.anchor_left = 1.0
 settings_button.anchor_right = 1.0
 settings_button.offset_left = -116
 settings_button.offset_right = -32
 settings_button.offset_top = 30
 settings_button.offset_bottom = 114
 start.focus_neighbor_bottom = resume.get_path() if not resume.disabled else settings_button.get_path()
 resume.focus_neighbor_top = start.get_path()
 resume.focus_neighbor_bottom = settings_button.get_path()
 settings_button.focus_neighbor_top = resume.get_path() if not resume.disabled else start.get_path()
 settings_button.focus_neighbor_bottom = start.get_path()

func art_button(ui: Control, parent: Control, node_name: String, caption: String, source: Texture2D, region: Rect2, action: Callable) -> TextureButton:
 var atlas = AtlasTexture.new()
 atlas.atlas = source
 # Exclude transparent export margins while leaving the original PNG untouched.
 atlas.region = region
 var control = MENU_BUTTON.new()
 control.name = node_name
 control.texture_normal = atlas
 var hit_mask = BitMap.new()
 # Soft shadows remain visible but are not part of the clickable silhouette.
 hit_mask.create_from_image_alpha(atlas.get_image(), 0.5)
 control.texture_click_mask = hit_mask
 control.pressed.connect(ui.settings.play_click)
 control.pressed.connect(action)
 parent.add_child(control)
 control.set_caption(caption)
 return control

func place_menu_button(control: Control, vertical_anchor: float) -> void:
 control.anchor_left = 0.5
 control.anchor_right = 0.5
 control.anchor_top = vertical_anchor
 control.anchor_bottom = vertical_anchor
 control.offset_left = -152
 control.offset_right = 152
 control.offset_top = -42
 control.offset_bottom = 48
