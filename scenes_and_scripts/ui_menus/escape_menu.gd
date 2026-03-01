extends Control

@onready var exit_button: Button = $ColorRect/VBoxContainer/HBoxContainer/"Exit Button"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_menu()
	Signalbus.game_state_paused.connect(show_menu)
	Signalbus.game_state_playing.connect(hide_menu)

	# Hide exit button on web (quit doesn't work in browsers)
	if OS.has_feature("web"):
		exit_button.hide()

func show_menu() -> void:
	show()

func hide_menu() -> void:
	hide()

func _on_restart_button_pressed() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	GameManager.restart_level()

func _on_button_pressed() -> void:
	get_tree().quit()
