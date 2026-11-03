extends Node

func show_settings(ui: Control) -> void:
 var body = ui.open_modal("基础设置", Vector2(660, 460))
 body.add_child(ui.paragraph("调整适合你的声音与显示方式。设置会自动保存。", 17))
 for channel in ["master", "effects"]:
  var line = ui.row(18)
  var caption = ui.label("总音量" if channel == "master" else "音效音量", 20)
  caption.custom_minimum_size.x = 120
  line.add_child(caption)
  var slider = HSlider.new()
  slider.name = "Volume_" + channel
  slider.min_value = 0
  slider.max_value = 100
  slider.step = 1
  slider.value = (ui.settings.master_volume if channel == "master" else ui.settings.effects_volume) * 100
  slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  slider.custom_minimum_size = Vector2(280, 42)
  var value_label = ui.label("%d%%" % slider.value, 18, ui.GOLD)
  value_label.custom_minimum_size.x = 60
  slider.value_changed.connect(func(value):
   ui.settings.set_volume(channel, value / 100.0)
   value_label.text = "%d%%" % value)
  line.add_child(slider)
  line.add_child(value_label)
  body.add_child(line)
 var fullscreen = CheckButton.new()
 fullscreen.name = "FullscreenToggle"
 fullscreen.text = "全屏显示 · 16:9"
 fullscreen.button_pressed = ui.settings.fullscreen
 fullscreen.toggled.connect(ui.settings.set_fullscreen)
 body.add_child(fullscreen)
 body.add_child(ui.button("试听音效", ui.settings.play_click))
 body.add_child(ui.paragraph("数字1–9对应前九张手牌，0对应第十张；空格结束回合，Esc打开或关闭菜单。", 15))

func show_game_menu(ui: Control) -> void:
 var body = ui.open_modal("冒险菜单", Vector2(540, 670))
 for item in [["关卡地图", ui.open_map], ["卡组", ui.show_deck_manager], ["图鉴", ui.show_catalog], ["玩法", ui.show_help], ["保存", ui.manual_save], ["声音与显示", ui.show_settings]]:
  var action = ui.button(item[0], item[1])
  action.name = "Menu_" + str(item[0])
  body.add_child(action)
 body.add_child(ui.button("返回主界面", ui.return_home))
 var back = ui.button("返回", ui.close_modal, true)
 back.name = "MenuReturn"
 body.add_child(back)
