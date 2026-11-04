extends Control
## Premium Stylized 3D talent screen; independent art, typography and live lighting.
const ART = "res://Game/Assets/UI/TalentSelection/"
const MODULES = preload("res://Game/Assets/UI/TalentSelection/modules.json")
const ART_BUTTON = preload("res://Game/Scenes/MainMenu/Components/ArtButton.tscn")
const ROUTE_CARD = preload("res://Game/Scenes/MainMenu/Components/RouteCard.tscn")
const DIFFICULTY_BUTTON = preload("res://Game/Scenes/MainMenu/Components/DifficultyButton.tscn")
const RED_BUTTON = preload("res://Game/Assets/UI/TalentSelection/RedGoldBar.png")
var host: Control
var route_buttons: Dictionary = {}
var difficulty_buttons: Dictionary = {}

func setup(ui: Control) -> void:
 host = ui
 var backdrop = TextureRect.new()
 backdrop.name = "TalentBackground"
 backdrop.texture = preload("res://Game/Assets/UI/TalentSelection/VillageDisplayBackground.png")
 backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 backdrop.stretch_mode = TextureRect.STRETCH_SCALE
 backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(backdrop)
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var atmosphere = ColorRect.new()
 atmosphere.name = "WarmAtmosphere"
 atmosphere.color = Color(0.20,0.12,0.045,0.075)
 atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(atmosphere)
 atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var route_group = ButtonGroup.new()
 var difficulty_group = ButtonGroup.new()
 for module in MODULES.data.exports:
  var rect = Rect2(module.rect[0],module.rect[1],module.rect[2],module.rect[3])
  var texture = load(ART + module.file) as Texture2D
  var control: Control
  if module.role == "decoration":
   var image = TextureRect.new()
   image.name = "TalentTitle"
   image.texture = texture
   image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   image.stretch_mode = TextureRect.STRETCH_SCALE
   image.mouse_filter = Control.MOUSE_FILTER_IGNORE
   control = image
  elif module.role == "route":
   control = ROUTE_CARD.instantiate()
   control.name = "Route_" + module.id
   control.wide_selection_badge = true
   control.caption_font = ui.DISPLAY_FONT
   control.texture_normal = texture
   control.button_group = route_group
   control.button_pressed = ui.selected_route == module.id
   control.disabled = ui.resuming
   route_buttons[module.id] = control
   control.set_meta("route_id", module.id)
   control.pressed.connect(func(): select_route(module.id))
  elif module.role == "difficulty":
   control = DIFFICULTY_BUTTON.instantiate()
   control.name = "Difficulty_" + module.id
   control.texture_normal = texture
   control.button_group = difficulty_group
   control.button_pressed = ui.selected_difficulty == module.id
   control.disabled = ui.resuming
   difficulty_buttons[module.id] = control
   control.pressed.connect(func(): select_difficulty(module.id))
  else:
   control = ART_BUTTON.instantiate()
   control.name = "TalentBack"
   control.texture_normal = RED_BUTTON
   control.caption_text = "←"
   control.caption_font = ui.READING_FONT
   control.font_ratio = 0.72
   control.pressed.connect(ui.return_home)
  if control is BaseButton: control.pressed.connect(ui.settings.play_click)
  add_child(control)
  place(control,rect)
  if module.role == "decoration":
   var title_copy = copy_label(control,"TitleCopy","选择你的天赋路线",Rect2(0.04,0.08,0.92,0.84),43,Color("fff2c8"))
   title_copy.add_theme_color_override("font_outline_color",Color("663213"))
   title_copy.add_theme_constant_override("outline_size",3)
  elif module.role == "route": add_route_copy(control,module.id)
  elif module.role == "difficulty": add_difficulty_copy(control,module.id)
 var confirm = ART_BUTTON.instantiate()
 confirm.name = "ConfirmRoute"
 confirm.texture_normal = RED_BUTTON
 confirm.caption_text = "继续冒险" if ui.resuming else "开始冒险"
 confirm.caption_font = ui.DISPLAY_FONT
 confirm.font_ratio = 0.44
 confirm.pressed.connect(ui.settings.play_click)
 confirm.pressed.connect(ui.confirm_route)
 add_child(confirm)
 place(confirm,Rect2(1150,775,498,110))
 if ui.resuming:
  var locked = ui.label("存档天赋与难度已锁定",19,Color("fff0c1"))
  locked.name = "SavedRouteLock"
  locked.add_theme_color_override("font_outline_color",Color("4b2410"))
  locked.add_theme_constant_override("outline_size",5)
  locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  add_child(locked)
  place(locked,Rect2(445,728,1060,36))
 configure_focus(confirm)

static func place(control: Control, rect: Rect2) -> void:
 control.anchor_left = rect.position.x / 1672.0
 control.anchor_top = rect.position.y / 941.0
 control.anchor_right = rect.end.x / 1672.0
 control.anchor_bottom = rect.end.y / 941.0

func select_route(id: String) -> void:
 if host.resuming: return
 host.selected_route = id
 for key in route_buttons: route_buttons[key].set_selected(key == id)

func select_difficulty(id: String) -> void:
 if host.resuming: return
 host.selected_difficulty = id
 for key in difficulty_buttons: difficulty_buttons[key].set_selected(key == id)

func configure_focus(confirm: Control) -> void:
 var controls: Array[Control] = [get_node("TalentBack")]
 if not host.resuming:
  for id in ["venom","fury","bastion"]: controls.append(route_buttons[id])
  for id in ["easy","normal","hard","legendary"]: controls.append(difficulty_buttons[id])
 controls.append(confirm)
 for i in range(controls.size()):
  var previous = controls[posmod(i-1,controls.size())].get_path()
  var next = controls[(i+1)%controls.size()].get_path()
  controls[i].focus_previous = previous
  controls[i].focus_next = next
  controls[i].focus_neighbor_left = previous
  controls[i].focus_neighbor_right = next
  controls[i].focus_neighbor_top = previous
  controls[i].focus_neighbor_bottom = next

func copy_label(parent: Control, node_name: String, text_value: String, box: Rect2, font_size: int, color: Color) -> Label:
 var text_label = Label.new()
 text_label.name = node_name
 text_label.text = text_value
 text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 text_label.add_theme_font_override("font",host.DISPLAY_FONT)
 text_label.add_theme_font_size_override("font_size",font_size)
 text_label.add_theme_color_override("font_color",color)
 parent.add_child(text_label)
 text_label.anchor_left = box.position.x
 text_label.anchor_top = box.position.y
 text_label.anchor_right = box.end.x
 text_label.anchor_bottom = box.end.y
 return text_label

func add_route_copy(control: Control, id: String) -> void:
 var copy = {
  "venom":["蚀毒","叠毒侵蚀\n毒层引爆"],
  "fury":["狂刃","力量连击\n嗜血暴击"],
  "bastion":["铁壁","护甲转伤\n荆棘反击"]
 }[id]
 copy_label(control,"RouteName",copy[0],Rect2(0.12,0.675,0.76,0.10),34,Color("633713"))
 var description = copy_label(control,"RouteDescription",copy[1],Rect2(0.12,0.785,0.76,0.15),23,Color("684324"))
 description.add_theme_constant_override("line_spacing",5)

func add_difficulty_copy(control: Control, id: String) -> void:
 var title = {"easy":"轻松","normal":"标准","hard":"勇者","legendary":"传奇"}[id]
 var text_label = copy_label(control,"DifficultyName",title,Rect2(0.12,0.43,0.76,0.40),29,Color("fff2c8"))
 text_label.add_theme_color_override("font_outline_color",Color("573113"))
 text_label.add_theme_constant_override("outline_size",3)
