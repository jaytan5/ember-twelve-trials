extends Node
const ChapterArt = preload("res://Game/Scenes/UI/ChapterArt.gd")

func build_map(ui: Control) -> void:
 ui.page_heading("WORLD MAP  /  四大场景", "十二道试炼，一步步前行。", "每片区域包含两场普通战斗和一场 Boss 战。点击亮起的当前关卡进入。")
 var chapters = ui.row(18)
 chapters.name = "ChapterMap"
 chapters.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var colors = [Color("75cbb3"), Color("d9b681"), Color("8eb5e5"), Color("e69282")]
 for chapter in range(4):
  var tint: Color = colors[chapter]
  var area = ui.panel(ui.PANEL, tint.darkened(0.5), 18)
  area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  var body = ui.column(12)
  area.add_child(body)
  body.add_child(ui.label("%02d  /  %s" % [chapter + 1, ui.Data.CHAPTERS[chapter]], 24, tint))
  var art = ChapterArt.new()
  art.chapter = chapter
  art.tint = tint
  art.custom_minimum_size.y = 110
  art.size_flags_vertical = Control.SIZE_EXPAND_FILL
  body.add_child(art)
  for local_stage in range(3):
   var stage = chapter * 3 + local_stage + 1
   var current = stage == int(ui.game.s.stage)
   var completed = stage <= int(ui.game.s.wins)
   var status = "已通关" if completed else "尚未解锁"
   if current:
    match str(ui.game.s.phase):
     "battle": status = "进入战斗" if ui.game.s.turn == 1 and ui.game.s.played == 0 else "继续战斗"
     "reward", "relic": status = "领取战利品"
     "camp": status = "继续战后补给"
     _: status = "查看冒险结果"
   var caption = "%02d  %s\n%s · %s" % [stage, ui.Data.STAGE_NAMES[stage - 1], "BOSS" if local_stage == 2 else "普通战斗", status]
   var step = ui.button(caption, func(): ui.enter_map_stage(stage), current)
   step.name = "MapStage_%d" % stage
   step.custom_minimum_size.y = 92
   step.add_theme_font_size_override("font_size", 18)
   step.disabled = not current
   step.tooltip_text = "当前冒险关卡" if current else ("已完成此关" if completed else "完成前一关及战后补给后解锁")
   body.add_child(step)
   if local_stage < 2:
    var link = ui.label("│", 17, tint.darkened(0.3))
    link.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body.add_child(link)
  chapters.add_child(area)
 ui.layout.add_child(chapters)
 var summary = ui.row()
 summary.add_child(ui.label("进度  %d / 12   ·   生命 %d / %d   ·   出战卡组 %d 张" % [ui.game.s.wins, ui.game.s.hp, ui.game.s.max_hp, ui.game.s.deck.size()], 18, ui.GREEN))
 ui.spacer(summary)
 summary.add_child(ui.label("路线与卡组随存档保留", 15, ui.MUTED))
 ui.layout.add_child(summary)
