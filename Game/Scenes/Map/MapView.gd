extends Node
const SCREEN = preload("res://Game/Scenes/Map/AdventureMapScreen.gd")

func build_map(ui: Control) -> void:
 var screen = Control.new()
 screen.set_script(SCREEN)
 screen.name = "AdventureMapScreen"
 ui.add_child(screen)
 screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 screen.setup(ui)