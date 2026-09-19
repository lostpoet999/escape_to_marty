extends Control

const RESTART_HOLD_SECONDS: float = 1.5
const RESTART_FILL_COLOR: Color = Color(1.0, 0.3, 0.3, 0.45)
const POSTED_HOLD_SECONDS: float = 1.6
const POSTED_FADE_SECONDS: float = 0.5

@onready var main_menu_button: Button = $ColorRect/VBoxContainer/HBoxContainer/MainMenu
@onready var exit_button: Button = $ColorRect/VBoxContainer/HBoxContainer/"Exit Button"
@onready var retry_button: Button = $ColorRect/VBoxContainer/HBoxContainer/Retry
@onready var restart_button: Button = $ColorRect/VBoxContainer/HBoxContainer/RestartRun
@onready var score_value: Label = %ScoreValue
@onready var run_context: Label = %RunContext
@onready var easier_button: Button = $ColorRect/VBoxContainer/HBoxContainer/EasierRetry
@onready var name_edit: LineEdit = %NameEdit
@onready var board_title: Label = %BoardTitle
@onready var board_rows: RichTextLabel = %BoardRows
@onready var name_hint: Label = %NameHint
@onready var post_button: Button = %PostButton
@onready var posted_toast: Label = %PostedToast

var _open_tween: Tween
var _breathe_tween: Tween
var _restart_fill: ColorRect
var _restart_holding: bool = false
var _restart_hold_time: float = 0.0
var _run_tier: String = ""
var _run_score: int = 0
var _board_request: int = 0
var _name_checking: bool = false
var _posted: bool = false
var _toast_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ApolloPalette.style_menu_button(main_menu_button)
	ApolloPalette.style_menu_button(exit_button)
	ApolloPalette.style_menu_button(retry_button)
	ApolloPalette.style_menu_button(restart_button)
	ApolloPalette.style_menu_button(easier_button)
	easier_button.pressed.connect(_on_easier_pressed)
	_restart_fill = ColorRect.new()
	_restart_fill.color = RESTART_FILL_COLOR
	_restart_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_restart_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_restart_fill.scale.x = 0.0
	restart_button.add_child(_restart_fill)
	restart_button.button_down.connect(_on_restart_hold_started)
	restart_button.button_up.connect(_on_restart_hold_released)
	name_edit.text_submitted.connect(_on_name_submitted)
	ApolloPalette.style_small_menu_button(post_button)
	post_button.pressed.connect(_on_post_pressed)
	name_edit.max_length = Telemetry.NAME_MAX_LENGTH
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

func _on_easier_pressed() -> void:
	Telemetry.track("retry_easier")
	GameManager.retry_floor_easier()

func show_menu() -> void:
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	if _breathe_tween != null and _breathe_tween.is_valid():
		_breathe_tween.kill()
	score_value.text = str(PlayerData.get_player_score())
	var summary: Dictionary = PlayerData.build_run_summary(false)
	run_context.text = "%s  -  %s" % [summary["floor_name"], summary["tier"]]
	SaveProgression.record_run_score(summary["tier"], PlayerData.get_player_score())
	_run_tier = summary["tier"]
	_run_score = PlayerData.get_player_score()
	name_edit.text = SaveProgression.profile_name()
	name_edit.editable = Telemetry.enabled()
	board_title.text = "TOP RUNS  -  %s" % _run_tier
	name_hint.hide()
	board_rows.text = ""
	_hide_toast()
	_posted = false
	post_button.disabled = not Telemetry.enabled()
	_refresh_board()
	if name_edit.editable and name_edit.text.is_empty():
		name_edit.grab_focus()
	retry_button.visible = not GameManager.test_floor_active
	restart_button.visible = not GameManager.test_floor_active
	var tier: int = SettingsManager.tier_index()
	easier_button.visible = tier > 0 and not GameManager.test_floor_active
	if tier > 0:
		easier_button.text = "Retry on %s" % SettingsManager.TIER_NAMES[tier - 1]
	show()
	_open_tween = ApolloPalette.make_open_tween(self, true)
	_open_tween.finished.connect(_start_breathe)

func hide_menu() -> void:
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	if _breathe_tween != null and _breathe_tween.is_valid():
		_breathe_tween.kill()
	ApolloPalette.reset_popup(self)
	_hide_toast()
	hide()

func _on_name_submitted(raw_name: String) -> void:
	name_edit.text = Telemetry.sanitize_name(raw_name)
	name_edit.release_focus()

func _on_post_pressed() -> void:
	if _name_checking or _posted or not Telemetry.enabled():
		return
	var clean_name: String = Telemetry.sanitize_name(name_edit.text)
	name_edit.text = clean_name
	if clean_name.is_empty():
		name_hint.text = "enter a name first"
		name_hint.show()
		name_edit.grab_focus()
		return
	_name_checking = true
	post_button.disabled = true
	var claimed: String = await Telemetry.claim_name(clean_name)
	_name_checking = false
	if not visible:
		return
	if claimed != clean_name:
		post_button.disabled = false
		name_edit.text = claimed
		name_hint.text = "%s is taken" % clean_name
		name_hint.show()
		name_edit.grab_focus()
		name_edit.caret_column = claimed.length()
		return
	name_hint.hide()
	if clean_name != SaveProgression.profile_name():
		SaveProgression.set_profile_name(clean_name)
	var ok: bool = await Telemetry.submit_score(_run_tier, _run_score, clean_name)
	if not visible:
		return
	_posted = ok
	post_button.disabled = ok
	name_edit.release_focus()
	if ok:
		_show_toast()
		_refresh_board()
	else:
		name_hint.text = "post failed"
		name_hint.show()

func _show_toast() -> void:
	_hide_toast()
	posted_toast.modulate.a = 1.0
	posted_toast.show()
	_toast_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_toast_tween.tween_interval(POSTED_HOLD_SECONDS)
	_toast_tween.tween_property(posted_toast, "modulate:a", 0.0, POSTED_FADE_SECONDS)
	_toast_tween.tween_callback(_hide_toast)

func _hide_toast() -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	posted_toast.hide()
	posted_toast.modulate.a = 1.0

func _refresh_board() -> void:
	if not Telemetry.enabled():
		board_rows.text = "offline"
		return
	_board_request += 1
	var request: int = _board_request
	var rows: Array[Dictionary] = await Telemetry.fetch_top(_run_tier)
	if request != _board_request or not visible:
		return
	if Telemetry.last_fetch_failed:
		board_rows.text = "server unreachable"
		return
	board_rows.text = Telemetry.format_rows(rows)

func _start_breathe() -> void:
	_breathe_tween = ApolloPalette.make_breathe_tween(self, true)

func _on_main_menu_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	GameManager.load_scene(GameManager.MAIN_MENU)

func _on_button_pressed() -> void:
	get_tree().quit()
