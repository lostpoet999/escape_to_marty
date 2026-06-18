extends Control

const MAIN_MENU: PackedScene = preload("uid://djuj72c4lcukn")
const CREDITS_SCENE: PackedScene = preload("res://scenes_and_scripts/ui_main_menu/credits_scene.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://scenes_and_scripts/ui_main_menu/settings_scene.tscn")

const RESET_HOLD_SECONDS: float = 1.5
const RESET_IDLE_TEXT: String = "Reset Progress"
const RESET_FILL_COLOR: Color = Color(1.0, 0.3, 0.3, 0.45)
const RESET_DONE_COLOR: Color = Color(0.4, 1.0, 0.4, 0.5)

@onready var exit_button: Button = $VBoxContainer/ButtonContainer/"Exit Button"
@onready var reset_button: Button = $"Reset Button"

var _reset_fill: ColorRect
var _reset_holding: bool = false
var _reset_hold_time: float = 0.0

func _ready() -> void:
	# Hide exit button on web (quit doesn't work in browsers)
	if OS.has_feature("web"):
		exit_button.hide()
	_reset_fill = ColorRect.new()
	_reset_fill.color = RESET_FILL_COLOR
	_reset_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reset_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reset_fill.scale.x = 0.0
	reset_button.add_child(_reset_fill)
	reset_button.button_down.connect(_on_reset_hold_started)
	reset_button.button_up.connect(_on_reset_hold_released)

func _process(delta: float) -> void:
	if not _reset_holding:
		return
	_reset_hold_time += delta
	if _reset_hold_time >= RESET_HOLD_SECONDS:
		_execute_reset()
		return
	_reset_fill.scale.x = _reset_hold_time / RESET_HOLD_SECONDS

func _on_reset_hold_started() -> void:
	_reset_holding = true
	_reset_hold_time = 0.0
	_reset_fill.color = RESET_FILL_COLOR
	_reset_fill.scale.x = 0.0
	reset_button.text = RESET_IDLE_TEXT

func _on_reset_hold_released() -> void:
	if not _reset_holding:
		return
	_reset_holding = false
	_reset_fill.scale.x = 0.0

func _execute_reset() -> void:
	_reset_holding = false
	SaveProgression.reset_progress()
	_reset_fill.color = RESET_DONE_COLOR
	_reset_fill.scale.x = 1.0
	reset_button.text = "Progress Reset!"

func _on_start_button_pressed() -> void:
	print("start button pressed")
	GameManager.change_state(GameManager.GameState.BALL_ON_PADDLE)
	GameManager.load_current_room()

func _on_settings_button_pressed() -> void:
	print("settings button pressed")
	get_tree().change_scene_to_packed(SETTINGS_SCENE)

func _on_credits_button_pressed() -> void:
	print("credits button pressed")
	get_tree().change_scene_to_packed(CREDITS_SCENE)

func _on_exit_button_pressed() -> void:
	print("exit button pressed")
	get_tree().quit()

func _on_fullscreen_button_pressed() -> void:
	print("fullscreen button pressed")
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
