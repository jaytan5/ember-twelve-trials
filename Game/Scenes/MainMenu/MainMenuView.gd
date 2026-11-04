extends Node
## Independent view; the host retains run creation and persistence.
const SCREEN = preload("res://Game/Scenes/MainMenu/Components/TalentScreen.tscn")

func build_menu(ui: Control) -> void:
 var screen = SCREEN.instantiate()
 ui.add_child(screen)
 screen.setup(ui)
