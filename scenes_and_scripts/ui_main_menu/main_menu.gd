extends Control

@onready var exit_button: Button = $VBoxContainer/ButtonContainer/"Exit Button"

func _ready() -> void:
	# Hide exit button on web (quit doesn't work in browsers)
	if OS.has_feature("web"):
		exit_button.hide()

func _on_start_button_pressed() -> void:
	GameManager.change_state(GameManager.GameState.BALL_ON_PADDLE)
	GameManager.load_scene(GameManager.LEVEL_01)


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_fullscreen_button_pressed() -> void:
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
