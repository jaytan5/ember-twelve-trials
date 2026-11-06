extends Node
## Keep the sword cursor across button hover, dragging and busy states.
const ART = preload("res://Game/Assets/UI/Cursors/星芒小剑-透明.png")
const CURSOR_SIZE = Vector2i(48, 48)
const HOTSPOT = Vector2(5, 1)
const SHADOW_OFFSET = Vector2i(1, 2)
const SHADOW_OPACITY = 0.30
const MAX_CLICK_EFFECTS = 8
const CLICK_EFFECT = preload("res://Game/Scenes/UI/CursorClickEffect.gd")
var texture: ImageTexture
var click_layer: CanvasLayer

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 click_layer = CanvasLayer.new()
 click_layer.name = "CursorClickLayer"
 click_layer.layer = 100
 add_child(click_layer)
 var image = ART.get_image()
 image.resize(CURSOR_SIZE.x, CURSOR_SIZE.y, Image.INTERPOLATE_LANCZOS)
 texture = ImageTexture.create_from_image(_with_shadow(image))
 if DisplayServer.get_name() == "headless": return
 for shape in range(Input.CURSOR_ARROW, Input.CURSOR_HELP + 1):
  Input.set_custom_mouse_cursor(texture, shape, HOTSPOT)

func _with_shadow(source: Image) -> Image:
 var result = Image.create(CURSOR_SIZE.x, CURSOR_SIZE.y, false, Image.FORMAT_RGBA8)
 result.fill(Color.TRANSPARENT)
 # A small weighted blur behind the sword keeps its silhouette and click hotspot.
 var weights = [1.0, 2.0, 1.0]
 for y in range(CURSOR_SIZE.y):
  for x in range(CURSOR_SIZE.x):
   var alpha = 0.0
   for dy in range(-1, 2):
    for dx in range(-1, 2):
     var sample = Vector2i(x, y) - SHADOW_OFFSET + Vector2i(dx, dy)
     if sample.x >= 0 and sample.y >= 0 and sample.x < source.get_width() and sample.y < source.get_height():
      alpha += source.get_pixelv(sample).a * weights[dx + 1] * weights[dy + 1]
   result.set_pixel(x, y, Color(0.12, 0.07, 0.04, alpha / 16.0 * SHADOW_OPACITY))
 result.blend_rect(source, Rect2i(Vector2i.ZERO, CURSOR_SIZE), Vector2i.ZERO)
 return result

func _input(event: InputEvent) -> void:
 if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
  return
 if click_layer.get_child_count() >= MAX_CLICK_EFFECTS:
  var oldest = click_layer.get_child(0)
  click_layer.remove_child(oldest)
  oldest.queue_free()
 var effect = CLICK_EFFECT.new()
 effect.position = event.position
 click_layer.add_child(effect)
 # Observe the click without consuming it; buttons and card dragging still receive it.

func _exit_tree() -> void:
 if DisplayServer.get_name() != "headless":
  for shape in range(Input.CURSOR_ARROW, Input.CURSOR_HELP + 1):
   Input.set_custom_mouse_cursor(null, shape)
 texture = null
