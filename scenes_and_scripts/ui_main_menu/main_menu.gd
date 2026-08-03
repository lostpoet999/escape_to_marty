extends Control

@export_category("Menu Music")
## drag the menu song here; it loops while the menu is up. Empty = silence
@export var music: AudioStream
@export var music_volume_db: float = -5.0

const MAIN_MENU: PackedScene = preload("uid://djuj72c4lcukn")
const CREDITS_SCENE: PackedScene = preload("res://scenes_and_scripts/ui_main_menu/credits_scene.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://scenes_and_scripts/ui_main_menu/settings_scene.tscn")

const DEV_LABEL_HOVER_COLOR: Color = Color(1.0, 1.0, 1.0)

const RESET_HOLD_SECONDS: float = 1.5
const RESET_IDLE_TEXT: String = "Reset Progress"
const RESET_FILL_COLOR: Color = Color(1.0, 0.3, 0.3, 0.45)
const RESET_DONE_COLOR: Color = Color(0.4, 1.0, 0.4, 0.5)
const START_NEW_RUN_TEXT: String = "New Run"

@onready var exit_button: Button = $VBoxContainer/ButtonContainer/"Exit Button"
@onready var reset_button: Button = $"Reset Button"
@onready var dev_build_label: Label = $Label
@onready var start_button: Button = $VBoxContainer/ButtonContainer/"Start Button"
@onready var continue_button: Button = $VBoxContainer/ButtonContainer/"Continue Button"

var _reset_fill: ColorRect
var _reset_holding: bool = false
var _reset_hold_time: float = 0.0
var _start_fill: ColorRect
var _start_holding: bool = false
var _start_hold_time: float = 0.0
var _dev_label_base_color: Color

func _ready() -> void:
	MusicPlayer.play_song(music, music_volume_db)
	# Hide exit button on web (quit doesn't work in browsers)
	if OS.has_feature("web"):
		exit_button.hide()
	if OS.is_debug_build():
		dev_build_label.mouse_filter = Control.MOUSE_FILTER_STOP
		dev_build_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		dev_build_label.tooltip_text = "click to enter test floor"
		_dev_label_base_color = dev_build_label.label_settings.font_color
		dev_build_label.gui_input.connect(_on_dev_build_label_gui_input)
		dev_build_label.mouse_entered.connect(_on_dev_build_label_hover.bind(true))
		dev_build_label.mouse_exited.connect(_on_dev_build_label_hover.bind(false))
	else:
		dev_build_label.hide()
	_reset_fill = ColorRect.new()
	_reset_fill.color = RESET_FILL_COLOR
	_reset_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reset_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reset_fill.scale.x = 0.0
	reset_button.add_child(_reset_fill)
	reset_button.button_down.connect(_on_reset_hold_started)
	reset_button.button_up.connect(_on_reset_hold_released)
	continue_button.visible = SaveProgression.has_run_checkpoint()
	if SaveProgression.has_run_checkpoint():
		start_button.text = START_NEW_RUN_TEXT
		_start_fill = ColorRect.new()
		_start_fill.color = RESET_FILL_COLOR
		_start_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_start_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_start_fill.scale.x = 0.0
		start_button.add_child(_start_fill)
		start_button.button_down.connect(_on_start_hold_started)
		start_button.button_up.connect(_on_start_hold_released)

func _process(delta: float) -> void:
	if _start_holding:
		_start_hold_time += delta
		if _start_hold_time >= RESET_HOLD_SECONDS:
			_start_holding = false
			_start_new_run()
			return
		_start_fill.scale.x = _start_hold_time / RESET_HOLD_SECONDS
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
	continue_button.visible = false
	start_button.text = "Start"
	_start_holding = false
	if _start_fill != null:
		_start_fill.scale.x = 0.0
	_reset_fill.color = RESET_DONE_COLOR
	_reset_fill.scale.x = 1.0
	reset_button.text = "Progress Reset!"

func _on_start_button_pressed() -> void:
	if SaveProgression.has_run_checkpoint():
		return
	_start_new_run()

func _start_new_run() -> void:
	if not GameManager.change_state(GameManager.GameState.BALL_ON_PADDLE):
		return
	GameManager.write_run_checkpoint()
	GameManager.load_current_room()

func _on_continue_button_pressed() -> void:
	GameManager.continue_run()

func _on_start_hold_started() -> void:
	_start_holding = true
	_start_hold_time = 0.0
	_start_fill.scale.x = 0.0

func _on_start_hold_released() -> void:
	_start_holding = false
	if _start_fill != null:
		_start_fill.scale.x = 0.0

func _on_settings_button_pressed() -> void:
	print("settings button pressed")
	get_tree().change_scene_to_packed(SETTINGS_SCENE)

func _on_credits_button_pressed() -> void:
	print("credits button pressed")
	get_tree().change_scene_to_packed(CREDITS_SCENE)

func _on_exit_button_pressed() -> void:
	print("exit button pressed")
	get_tree().quit()

func _on_dev_build_label_hover(hovering: bool) -> void:
	dev_build_label.label_settings.font_color = DEV_LABEL_HOVER_COLOR if hovering else _dev_label_base_color

func _on_dev_build_label_gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_warp_to_test_floor()

func _warp_to_test_floor() -> void:
	var fd_variant: Variant = load("res://scenes_and_scripts/levels/test_floor/test_floor.tres")
	GameManager.start_floor_with_data(fd_variant)
	GameManager.change_state(GameManager.GameState.BALL_ON_PADDLE)
	GameManager.load_current_room()

func _on_fullscreen_button_pressed() -> void:
	print("fullscreen button pressed")
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
