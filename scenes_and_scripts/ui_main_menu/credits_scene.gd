extends Control

@export var music: AudioStream
@export var music_volume_db: float = -5.0
@export var scroll_speed: float = 40.0
@export var scroll_top_pause: float = 2.0
@export var scroll_bottom_pause: float = 8.0

const POSTED_HOLD_SECONDS: float = 1.6
const POSTED_FADE_SECONDS: float = 0.5

@onready var _credits_text: RichTextLabel = $"VBoxContainer/CreditsContainer/Credits Text"
@onready var _run_summary: Label = $VBoxContainer/RunSummary
@onready var _post_row: HBoxContainer = $VBoxContainer/PostRow
@onready var _name_edit: LineEdit = %NameEdit
@onready var _post_button: Button = %PostButton
@onready var _name_hint: Label = %NameHint
@onready var _posted_toast: Label = %PostedToast

var _name_checking: bool = false
var _posted: bool = false
var _toast_tween: Tween


func _ready() -> void:
	if music != null:
		MusicPlayer.play_song(music, music_volume_db)
	_show_run_summary()
	ApolloPalette.style_small_menu_button(_post_button)
	_post_button.pressed.connect(_on_post_pressed)
	_name_edit.text_submitted.connect(_on_name_submitted)
	get_tree().process_frame.connect(_start_scroll_loop, CONNECT_ONE_SHOT)


func _start_scroll_loop() -> void:
	var bar: VScrollBar = _credits_text.get_v_scroll_bar()
	var distance: float = bar.max_value - bar.page
	if distance <= 0.0:
		get_tree().process_frame.connect(_start_scroll_loop, CONNECT_ONE_SHOT)
		return
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_callback(bar.set_value.bind(0.0))
	tween.tween_interval(scroll_top_pause)
	tween.tween_property(bar, "value", distance, distance / scroll_speed)
	tween.tween_interval(scroll_bottom_pause)

func _show_run_summary() -> void:
	var summary: Dictionary = GameManager.last_run_summary
	_run_summary.visible = not summary.is_empty()
	if summary.is_empty():
		return
	_run_summary.text = "SCORE: %d  -  %s  -  RETRIES: %d" % [int(summary["score"]), String(summary["tier"]), int(summary["retries"])]
	_post_row.visible = Telemetry.enabled()
	_name_edit.text = SaveProgression.profile_name()
	_post_button.disabled = false

func _on_name_submitted(raw_name: String) -> void:
	_name_edit.text = Telemetry.sanitize_name(raw_name)
	_name_edit.release_focus()

func _on_post_pressed() -> void:
	if _name_checking or _posted or not Telemetry.enabled():
		return
	var summary: Dictionary = GameManager.last_run_summary
	if summary.is_empty():
		return
	var clean_name: String = Telemetry.sanitize_name(_name_edit.text)
	_name_edit.text = clean_name
	if clean_name.is_empty():
		_name_hint.text = "enter a name first"
		_name_hint.show()
		_name_edit.grab_focus()
		return
	_name_checking = true
	_post_button.disabled = true
	var claimed: String = await Telemetry.claim_name(clean_name)
	_name_checking = false
	if not is_inside_tree():
		return
	if claimed != clean_name:
		_post_button.disabled = false
		_name_edit.text = claimed
		_name_hint.text = "%s is taken" % clean_name
		_name_hint.show()
		_name_edit.grab_focus()
		_name_edit.caret_column = claimed.length()
		return
	_name_hint.hide()
	if clean_name != SaveProgression.profile_name():
		SaveProgression.set_profile_name(clean_name)
	var ok: bool = await Telemetry.submit_score(String(summary["tier"]), int(summary["score"]), clean_name)
	if not is_inside_tree():
		return
	_posted = ok
	_post_button.disabled = ok
	_name_edit.release_focus()
	if ok:
		_show_toast()
	else:
		_name_hint.text = "post failed"
		_name_hint.show()

func _show_toast() -> void:
	_hide_toast()
	_posted_toast.modulate.a = 1.0
	_posted_toast.show()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(POSTED_HOLD_SECONDS)
	_toast_tween.tween_property(_posted_toast, "modulate:a", 0.0, POSTED_FADE_SECONDS)
	_toast_tween.tween_callback(_hide_toast)

func _hide_toast() -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_posted_toast.hide()
	_posted_toast.modulate.a = 1.0

func _on_main_menu_button_pressed() -> void:
	print("main menu button pressed")
	get_tree().change_scene_to_file("res://scenes_and_scripts/ui_main_menu/main_menu.tscn")
