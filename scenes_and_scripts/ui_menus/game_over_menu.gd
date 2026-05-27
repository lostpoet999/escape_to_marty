extends Control

@onready var exit_button: Button = $ColorRect/VBoxContainer/HBoxContainer/"Exit Button"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_menu()
	Signalbus.game_state_game_over.connect(show_menu)
	Signalbus.game_state_main_menu.connect(hide_menu)

	# quit doesn't work in browsers
	if OS.has_feature("web"):
		exit_button.hide()

func show_menu() -> void:
	show()

func hide_menu() -> void:
	hide()

func _on_main_menu_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	GameManager.load_scene(GameManager.MAIN_MENU)

func _on_button_pressed() -> void:
	get_tree().quit()
