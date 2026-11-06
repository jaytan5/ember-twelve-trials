extends Control
## Actual glyph bounds are centered in the face; shadows never affect alignment.
const FONT = preload("res://Game/Assets/Fonts/天赋界面方圆体.tres")
var text = ""
var font_size = 34
var cream = true
var ink_bounds = Rect2()

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(value: String, center: Vector2, pixels: int, light: bool = true) -> void:
 text = value
 font_size = pixels
 cream = light
 size = Vector2(FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x + 20,font_size + 24)
 position = center - size * 0.5
 queue_redraw()

func _draw() -> void:
 if text.is_empty(): return
 var line = TextLine.new()
 line.add_string(text,FONT,font_size)
 var server = TextServerManager.get_primary_interface()
 var pen = Vector2.ZERO
 var bounds = Rect2()
 var has_ink = false
 for glyph in server.shaped_text_get_glyphs(line.get_rid()):
  for _repeat in range(glyph.repeat):
   if glyph.index > 0 and glyph.font_rid.is_valid():
    var glyph_size = server.font_get_glyph_size(glyph.font_rid,Vector2i(font_size,0),glyph.index)
    if glyph_size.x > 0 and glyph_size.y > 0:
     var rect = Rect2(pen+glyph.offset+server.font_get_glyph_offset(glyph.font_rid,Vector2i(font_size,0),glyph.index),glyph_size)
     bounds = bounds.merge(rect) if has_ink else rect
     has_ink = true
   pen.x += glyph.advance
 if not has_ink: return
 var origin = size*0.5 - bounds.get_center()
 ink_bounds = Rect2(bounds.position+origin,bounds.size)
 var shadow = origin + Vector2(1.1,2.3)
 FONT.draw_string_outline(get_canvas_item(),shadow,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,2,Color(0.14,0.065,0.03,0.16))
 FONT.draw_string(get_canvas_item(),shadow,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(0.14,0.065,0.03,0.32))
 if cream:
  FONT.draw_string_outline(get_canvas_item(),origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,maxi(2,roundi(font_size*0.07)),Color("412a20"))
 FONT.draw_string(get_canvas_item(),origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("fff1d1") if cream else Color("412a20"))
