extends Control
## Approved v2 artwork, independent character/shadow and native centered text.
const ART = "res://Game/Assets/UI/TalentSelection/定稿_v2/"
const MODULES = preload("res://Game/Assets/UI/TalentSelection/定稿_v2/界面布局.json")
const ART_BUTTON = preload("res://Game/Scenes/MainMenu/Components/TalentArtButton.gd")
const COPY = preload("res://Game/Scenes/MainMenu/Components/TalentText.gd")
var host: Control
var design: Control
var route_buttons: Dictionary = {}
var difficulty_buttons: Dictionary = {}

func setup(ui: Control) -> void:
 host = ui
 var backdrop = image("TalentBackground",MODULES.data.background)
 backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 add_child(backdrop)
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 design = Control.new()
 design.name = "TalentCanvas"
 design.mouse_filter = Control.MOUSE_FILTER_IGNORE
 design.size = Vector2(1672,941)
 add_child(design)
 for module in MODULES.data.decorations:
  var art = image(module.name,module.file)
  design.add_child(art)
  art.position = rect_from(module.rect).position
  art.size = rect_from(module.rect).size
 var route_group = ButtonGroup.new()
 var difficulty_group = ButtonGroup.new()
 for module in MODULES.data.routes:
  var button = make_button("Route_"+module.id,module)
  button.is_route = true
  button.choice = true
  button.toggle_mode = true
  button.button_group = route_group
  button.button_pressed = ui.selected_route == module.id
  button.disabled = ui.resuming
  button.selection_glow = image("SelectionGlow",module.glow)
  button.glow_rect = rect_from(module.glow_rect)
  button.selection_badge = image("SelectionBadge",MODULES.data.badge)
  button.badge_rect = rect_from(module.badge_rect)
  button.badge_center = point_from(module.badge_center)
  button.pressed.connect(func(): select_route(module.id))
  route_buttons[module.id] = button
  design.add_child(button)
 for module in MODULES.data.difficulties:
  var button = make_button("Difficulty_"+module.id,module)
  button.normal_texture = load(ART+MODULES.data.difficulty_normal)
  button.selected_texture = load(ART+MODULES.data.difficulty_selected)
  button.caption_size = 39
  button.choice = true
  button.toggle_mode = true
  button.button_group = difficulty_group
  button.button_pressed = ui.selected_difficulty == module.id
  button.disabled = ui.resuming
  button.pressed.connect(func(): select_difficulty(module.id))
  difficulty_buttons[module.id] = button
  design.add_child(button)
 var back = action_button("TalentBack",MODULES.data.back,"返回",36,false)
 back.pressed.connect(ui.return_home)
 var confirm = action_button("ConfirmRoute",MODULES.data.confirm,"继续冒险" if ui.resuming else "开始冒险",57)
 confirm.pressed.connect(ui.confirm_route)
 copy_label(design,"TitleCopy","选择你的天赋路线",Vector2(908,99),60)
 copy_label(design,"SubtitleCopy","选择一份卡包",Vector2(910,208),38,false)
 if ui.resuming:
  copy_label(design,"SavedRouteLock","存档天赋与难度已锁定",Vector2(937,719),22)
 configure_focus(back,confirm)
 resized.connect(update_layout)
 update_layout()

func update_layout() -> void:
 if not is_instance_valid(design): return
 var factor = minf(size.x/1672.0,size.y/941.0)
 design.scale = Vector2.ONE*factor
 design.position = (size-Vector2(1672,941)*factor)*0.5

func image(node_name: String, filename: String) -> TextureRect:
 var result = TextureRect.new()
 result.name = node_name
 result.texture = load(ART+filename)
 result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 result.stretch_mode = TextureRect.STRETCH_SCALE
 result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return result

func make_button(node_name: String, module: Dictionary) -> TextureButton:
 var button = TextureButton.new()
 button.set_script(ART_BUTTON)
 button.name = node_name
 button.normal_rect = rect_from(module.normal_rect)
 button.selected_rect = rect_from(module.selected_rect)
 button.normal_center = point_from(module.normal_center)
 button.selected_center = point_from(module.selected_center)
 button.caption_text = module.title
 if module.has("file"):
  button.normal_texture = load(ART+module.file)
  button.selected_texture = button.normal_texture
 button.pressed.connect(host.settings.play_click)
 return button

func action_button(node_name: String, module: Dictionary, title: String, pixels: int, light: bool = true) -> TextureButton:
 var data = {"normal_rect":module.rect,"selected_rect":module.rect,"normal_center":module.center,"selected_center":module.center,"title":title,"file":module.file}
 var button = make_button(node_name,data)
 button.caption_size = pixels
 button.cream = light
 design.add_child(button)
 return button

func copy_label(parent: Control, node_name: String, value: String, center: Vector2, pixels: int, light: bool = true) -> Control:
 var result = Control.new()
 result.set_script(COPY)
 result.name = node_name
 parent.add_child(result)
 result.configure(value,center,pixels,light)
 return result

static func rect_from(values: Array) -> Rect2:
 return Rect2(values[0],values[1],values[2],values[3])

static func point_from(values: Array) -> Vector2:
 return Vector2(values[0],values[1])

func select_route(id: String) -> void:
 if host.resuming: return
 host.selected_route = id
 for key in route_buttons: route_buttons[key].set_selected(key == id)

func select_difficulty(id: String) -> void:
 if host.resuming: return
 host.selected_difficulty = id
 for key in difficulty_buttons: difficulty_buttons[key].set_selected(key == id)

func configure_focus(back: Control, confirm: Control) -> void:
 var controls: Array[Control] = [back]
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
