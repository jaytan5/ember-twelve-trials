extends Control
## 1600×900 审核稿的原生接入。浏览选择与真实冒险进度分离。
const ART = "res://Game/Assets/UI/AdventureMap/定稿_v1/"
const SHADOWS = preload("res://Game/Assets/UI/AdventureMap/定稿_v1/独立投影布局.json")
const COPY = preload("res://Game/Scenes/MainMenu/Components/TalentText.gd")
const ART_BUTTON = preload("res://Game/Scenes/Map/MapArtButton.gd")
const POINTS = [Vector2(230,804),Vector2(426,791),Vector2(507,684),Vector2(708,681),Vector2(1003,698),Vector2(806,517),Vector2(619,385),Vector2(724,307),Vector2(1074,345),Vector2(1294,405),Vector2(1483,362),Vector2(1436,294)]
const CHAPTERS = ["汤泉村落","街口集市","飞机展馆","汤山洞穴"]
var host: Control
var design: Control
var selected_stage = 1
var hero: TextureRect
var glow: TextureRect
var foot_shadow: TextureRect
var thumbnail: TextureRect
var title_copy: Control
var enter_copy: Control
var status_copy: Control
var enter_button: TextureButton
var health_bar: TextureProgressBar
var health_copy: Control
var stage_buttons: Array[Button] = []

func setup(ui: Control) -> void:
 host = ui
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 design = Control.new()
 design.name = "MapCanvas"
 design.size = Vector2(1600,900)
 design.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(design)
 image("MapBackground","背景_含原版风格关卡与数字.png",Rect2(0,0,1600,900))
 for i in range(12):
  var button = Button.new()
  button.name = "MapStage_%d" % (i+1)
  button.flat = true
  button.position = POINTS[i]-Vector2(55 if (i+1)%3 == 0 else 52.5,31)
  button.size = Vector2(110 if (i+1)%3 == 0 else 105,62)
  button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  for style in ["normal","hover","pressed","focus"]: button.add_theme_stylebox_override(style,StyleBoxEmpty.new())
  button.tooltip_text = "%02d %s · %s" % [i+1,CHAPTERS[i/3],host.Data.STAGE_NAMES[i]]
  button.pressed.connect(func():
   host.settings.play_click()
   select_stage(i+1))
  design.add_child(button)
  stage_buttons.append(button)
 for item in SHADOWS.data:
  var r = item.rect
  image("Shadow"+str(design.get_child_count()),item.file,Rect2(r[0],r[1],r[2],r[3]))
 glow = image("SelectedStageGlow","光圈_圆盘脚下.png",Rect2(0,0,180,114))
 var pulse = create_tween().set_loops()
 pulse.tween_property(glow,"self_modulate:a",.78,.95).set_trans(Tween.TRANS_SINE)
 pulse.tween_property(glow,"self_modulate:a",1.0,.95).set_trans(Tween.TRANS_SINE)
 var portrait = image("HeroPortrait","头像_原主角面部特写.png",Rect2(41.6667,125.3333,85.3333,85.3333))
 var shader = Shader.new()
 shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float mask=1.0-smoothstep(0.485,0.5,length(UV-vec2(0.5))); vec3 bg=mix(vec3(0.86,0.96,0.98),vec3(0.24,0.42,0.52),clamp(length(UV-vec2(0.38,0.3))*1.3,0.0,1.0)); COLOR=vec4(mix(bg,c.rgb,c.a),mask); }"
 var material_value = ShaderMaterial.new()
 material_value.shader = shader
 portrait.material = material_value
 image("MapTitle","主标题_冒险地图_厚木含字.png",Rect2(122,0,340,112))
 image("HeroFrame","人物属性牌_木金底框.png",Rect2(20,108,335,120))
 health_bar = TextureProgressBar.new()
 health_bar.name = "MapHealthBar"
 health_bar.position = Vector2(142.6667,177.3333)
 health_bar.size = Vector2(160.6667,17.6667)
 health_bar.texture_progress = load(ART+"血条_满血填充.png")
 health_bar.nine_patch_stretch = true
 health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
 health_bar.max_value = maxi(1,int(host.game.s.max_hp))
 health_bar.value = host.game.s.hp
 design.add_child(health_bar)
 health_copy = copy("MapHealthValue","%d/%d" % [host.game.s.hp,host.game.s.max_hp],Vector2(247.5,150.3333),32,false)
 var regions = Control.new()
 regions.name = "ChapterMap"
 regions.mouse_filter = Control.MOUSE_FILTER_IGNORE
 design.add_child(regions)
 var rects = [Rect2(60,461,300,106),Rect2(447,407,299,106),Rect2(506,99,290,106),Rect2(1144,97,293,106)]
 for i in range(4): image("Chapter_%d" % (i+1),"名牌_"+CHAPTERS[i]+"_含字.png",rects[i],regions)
 thumbnail = image("ChapterThumbnail","缩略图_汤泉村落.png",Rect2(1150,624,380,130.22))
 thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 thumbnail.clip_contents = true
 image("StageDetailFrame","关卡卡片_镂空木金框.png",Rect2(1095,503,490,383))
 title_copy = copy("StageDetailTitle","",Vector2(1340,580.5),37)
 status_copy = copy("StageProgressStatus","",Vector2(1340,766),19)
 enter_button = art_button("MapEnterButton","按钮_进入关卡_无字.png",Rect2(1174,775,332,80),func(): host.enter_map_stage(selected_stage))
 enter_copy = copy("MapEnterCaption","",Vector2(1340,811.5),43)
 art_button("MapBack","返回_含箭头.png",Rect2(20,15,99,85),host.return_home)
 art_button("SettingsButton","设置_含齿轮.png",Rect2(1497,12,89,89),host.show_game_menu)
 var gradient = Gradient.new()
 gradient.set_color(0,Color(.13,.07,.025,.48))
 gradient.set_color(1,Color(.13,.07,.025,0))
 var shadow_texture = GradientTexture2D.new()
 shadow_texture.gradient = gradient
 shadow_texture.fill = GradientTexture2D.FILL_RADIAL
 shadow_texture.fill_from = Vector2(.5,.5)
 shadow_texture.fill_to = Vector2(1,.5)
 foot_shadow = TextureRect.new()
 foot_shadow.name = "HeroGroundShadow"
 foot_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 foot_shadow.texture = shadow_texture
 foot_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
 design.add_child(foot_shadow)
 hero = image("MapHero","主角_站立_无投影.png",Rect2())
 select_stage(clampi(int(host.game.s.stage),1,12))
 resized.connect(update_layout)
 update_layout()

func image(node_name: String, filename: String, rect: Rect2, parent: Control = null) -> TextureRect:
 var result = TextureRect.new()
 result.name = node_name
 result.texture = load(ART+filename)
 result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 result.stretch_mode = TextureRect.STRETCH_SCALE
 result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 result.position = rect.position
 result.size = rect.size
 (parent if parent != null else design).add_child(result)
 return result

func copy(node_name: String, value: String, center: Vector2, pixels: int, light: bool = true) -> Control:
 var result = COPY.new()
 result.name = node_name
 design.add_child(result)
 result.configure(value,center,pixels,light)
 return result

func art_button(node_name: String, filename: String, rect: Rect2, action: Callable) -> TextureButton:
 var result = TextureButton.new()
 result.set_script(ART_BUTTON)
 result.name = node_name
 result.ignore_texture_size = true
 result.texture_normal = load(ART+filename)
 result.position = rect.position
 result.size = rect.size
 result.pressed.connect(host.settings.play_click)
 result.pressed.connect(action)
 design.add_child(result)
 return result

func select_stage(stage: int) -> void:
 if stage < 1 or stage > 12: return
 selected_stage = stage
 var chapter = (stage-1)/3
 var point: Vector2 = POINTS[stage-1]
 var height = 112.0 if stage >= 7 else 144.0
 hero.size = Vector2(height*.51,height)
 hero.position = point-Vector2(hero.size.x*.5,height+16)
 foot_shadow.position = point-Vector2(31,26)
 foot_shadow.size = Vector2(62,23)
 glow.position = point+Vector2(-90,-55)
 thumbnail.texture = load(ART+"缩略图_"+CHAPTERS[chapter]+".png")
 title_copy.configure("%02d %s" % [stage,CHAPTERS[chapter]],Vector2(1340,580.5),37)
 var current = stage == int(host.game.s.stage)
 var completed = stage <= int(host.game.s.wins)
 enter_button.disabled = not current
 var action = "进入关卡"
 if not current: action = "已通关" if completed else "尚未解锁"
 else:
  match str(host.game.s.phase):
   "battle": action = "进入关卡" if int(host.game.s.turn) == 1 and int(host.game.s.played) == 0 else "继续战斗"
   "reward", "relic": action = "领取战利品"
   "camp": action = "继续补给"
   _: action = "查看结果"
 enter_copy.configure(action,Vector2(1340,811.5),43 if action.length() <= 4 else 37)
 enter_copy.modulate = Color.WHITE if current else Color(.76,.73,.68)
 enter_button.update_feedback()
 var progress = "当前关卡" if current else ("已完成" if completed else "完成前一关后解锁")
 status_copy.configure(("首领战" if stage%3 == 0 else "普通战斗")+" · "+progress,Vector2(1340,765),18)
 for i in range(stage_buttons.size()): stage_buttons[i].set_meta("selected",i+1 == stage)

func update_layout() -> void:
 if not is_instance_valid(design): return
 var factor = minf(size.x/1600.0,size.y/900.0)
 design.scale = Vector2.ONE*factor
 design.position = (size-Vector2(1600,900)*factor)*.5
