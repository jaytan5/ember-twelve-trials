extends Control
## Separate, non-interactive selection mark; remains readable without animation.
var wide = false
var title_font: Font

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)

func _draw() -> void:
 var radius = size.y * 0.5
 var plate = StyleBoxFlat.new()
 plate.bg_color = Color("214d35")
 plate.border_color = Color("ffe28a")
 plate.set_border_width_all(2)
 plate.set_corner_radius_all(int(radius))
 plate.shadow_color = Color(0.12,0.06,0.01,0.45)
 plate.shadow_size = 4
 plate.shadow_offset = Vector2(0,2)
 draw_style_box(plate,Rect2(Vector2.ZERO,size))
 var center = Vector2(radius,radius)
 draw_polyline(PackedVector2Array([center+Vector2(-6,0),center+Vector2(-1,5),center+Vector2(8,-6)]),Color("fff4ba"),3,true)
 if wide and title_font != null:
  draw_string(title_font,Vector2(35,23),"已选择",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("fff1c1"))
