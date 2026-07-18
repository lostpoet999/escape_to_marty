extends Control

@onready var restart_button: Button = $ColorRect/VBoxContainer/HBoxContainer/"Restart Button"
@onready var main_menu_button: Button = $ColorRect/VBoxContainer/HBoxContainer/MainMenu
@onready var exit_button: Button = $ColorRect/VBoxContainer/HBoxContainer/"Exit Button"

var _open_tween: Tween
var _breathe_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ApolloPalette.style_menu_button(restart_button)
	ApolloPalette.style_menu_button(main_menu_button)
	ApolloPalette.style_menu_button(exit_button)
	hide_menu()
	Signalbus.game_state_paused.connect(show_menu)
	Signalbus.game_state_playing.connect(hide_menu)

	if OS.has_feature("web"):
		exit_button.hide()

func show_menu() -> void:
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	if _breathe_tween != null and _breathe_tween.is_valid():
		_breathe_tween.kill()
	show()
	_open_tween = ApolloPalette.make_open_tween(self, true)
	_open_tween.finished.connect(_start_breathe)

func hide_menu() -> void:
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	if _breathe_tween != null and _breathe_tween.is_valid():
		_breathe_tween.kill()
	ApolloPalette.reset_popup(self)
	hide()

func _start_breathe() -> void:
	_breathe_tween = ApolloPalette.make_breathe_tween(self, true)

func _on_restart_button_pressed() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	GameManager.restart_level()

func _on_main_menu_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	GameManager.load_scene(GameManager.MAIN_MENU)

func _on_button_pressed() -> void:
	get_tree().quit()
