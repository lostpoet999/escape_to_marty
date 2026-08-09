class_name FullscreenButton extends Button

@export var update_text: bool = true

func _ready() -> void:
	pressed.connect(_on_fullscreen_button_pressed)
	_update_text()

func _update_text() -> void:
	if update_text:
		match DisplayServer.window_get_mode():
			DisplayServer.WINDOW_MODE_WINDOWED:
				text = "Fullscreen\n(Windowed)"
			DisplayServer.WINDOW_MODE_FULLSCREEN:
				text = "(Fullscreen)\nWindowed"

func _on_fullscreen_button_pressed() -> void:
	print("fullscreen button pressed")
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	_update_text()
