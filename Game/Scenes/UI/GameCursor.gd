extends Node
## Keep the sword cursor across button hover, dragging and busy states.
const ART = preload("res://Game/Assets/UI/Cursors/星芒小剑-透明.png")
const CURSOR_SIZE = Vector2i(48, 48)
const HOTSPOT = Vector2(5, 1)
var texture: ImageTexture

func _ready() -> void:
 var image = ART.get_image()
 image.resize(CURSOR_SIZE.x, CURSOR_SIZE.y, Image.INTERPOLATE_LANCZOS)
 texture = ImageTexture.create_from_image(image)
 if DisplayServer.get_name() == "headless": return
 for shape in range(Input.CURSOR_ARROW, Input.CURSOR_HELP + 1):
  Input.set_custom_mouse_cursor(texture, shape, HOTSPOT)

func _exit_tree() -> void:
 if DisplayServer.get_name() != "headless":
  for shape in range(Input.CURSOR_ARROW, Input.CURSOR_HELP + 1):
   Input.set_custom_mouse_cursor(null, shape)
 texture = null
