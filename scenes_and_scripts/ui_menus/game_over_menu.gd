extends Control

const RESTART_HOLD_SECONDS: float = 1.5
const RESTART_FILL_COLOR: Color = Color(1.0, 0.3, 0.3, 0.45)

@onready var main_menu_button: Button = $ColorRect/VBoxContainer/HBoxContainer/MainMenu
@onready var exit_button: Button = $ColorRect/VBoxContainer/HBoxContainer/"Exit Button"
@onready var retry_button: Button = $ColorRect/VBoxContainer/HBoxContainer/Retry
@onready var restart_button: Button = $ColorRect/VBoxContainer/HBoxContainer/RestartRun
@onready var score_value: Label = %ScoreValue

var _open_tween: Tween
var _breathe_tween: Tween
var _restart_fill: ColorRect
var _restart_holding: bool = false
var _restart_hold_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ApolloPalette.style_menu_button(main_menu_button)
	ApolloPalette.style_menu_button(exit_button)
	ApolloPalette.style_menu_button(retry_button)
	ApolloPalette.style_menu_button(restart_button)
	_restart_fill = ColorRect.new()
	_restart_fill.color = RESTART_FILL_COLOR
	_restart_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_restart_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_restart_fill.scale.x = 0.0
	restart_button.add_child(_restart_fill)
	restart_button.button_down.connect(_on_restart_hold_started)
	restart_button.button_up.connect(_on_restart_hold_released)
	hide_menu()
	Signalbus.game_state_game_over.connect(show_menu)
	Signalbus.game_state_main_menu.connect(hide_menu)

	if OS.has_feature("web"):
		exit_button.hide()

func _process(delta: float) -> void:
	if not _restart_holding:
		return
	_restart_hold_time += delta
	if _restart_hold_time >= RESTART_HOLD_SECONDS:
		_restart_holding = false
		GameManager.restart_run()
		return
	_restart_fill.scale.x = _restart_hold_time / RESTART_HOLD_SECONDS

func _on_restart_hold_started() -> void:
	_restart_holding = true
	_restart_hold_time = 0.0
	_restart_fill.scale.x = 0.0

func _on_restart_hold_released() -> void:
	_restart_holding = false
	_restart_fill.scale.x = 0.0

func _on_retry_pressed() -> void:
	GameManager.retry_floor()

func show_menu() -> void:
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	if _breathe_tween != null and _breathe_tween.is_valid():
		_breathe_tween.kill()
	score_value.text = str(PlayerData.get_player_score())
	retry_button.visible = not GameManager.test_floor_active
	restart_button.visible = not GameManager.test_floor_active
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

func _on_main_menu_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	GameManager.load_scene(GameManager.MAIN_MENU)

func _on_button_pressed() -> void:
	get_tree().quit()
