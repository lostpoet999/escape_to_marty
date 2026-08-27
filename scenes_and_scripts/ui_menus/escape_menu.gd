extends Control

const EXIT_HOLD_SECONDS: float = 1.5

@onready var fullscreen_button: Button = $ColorRect/VBoxContainer/HBoxContainer/FullscreenButton
@onready var restart_button: Button = $ColorRect/VBoxContainer/HBoxContainer/"Restart Button"
@onready var main_menu_button: Button = $ColorRect/VBoxContainer/HBoxContainer/MainMenu
@onready var return_button: Button = $ColorRect/VBoxContainer/HBoxContainer/ReturnButton
@onready var exit_button: Button = $ColorRect/VBoxContainer/HBoxContainer/"Exit Button"
@onready var music_slider: HSlider = $ColorRect/VBoxContainer/SettingsBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $ColorRect/VBoxContainer/SettingsBox/SfxRow/SfxSlider
@onready var mouse_slider: HSlider = $ColorRect/VBoxContainer/SettingsBox/MouseRow/MouseSlider

var _open_tween: Tween
var _breathe_tween: Tween
var _settings_dirty: bool = false
var _exit_hold_seconds: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	ApolloPalette.style_menu_button(fullscreen_button)
	ApolloPalette.style_menu_button(restart_button)
	ApolloPalette.style_menu_button(main_menu_button)
	ApolloPalette.style_menu_button(exit_button)
	exit_button.add_theme_color_override(&"font_color", ApolloPalette.TEXT_DANGER)
	exit_button.add_theme_color_override(&"font_pressed_color", ApolloPalette.TEXT_DANGER)
	exit_button.add_theme_color_override(&"font_focus_color", ApolloPalette.TEXT_DANGER)
	exit_button.button_down.connect(_on_exit_button_down)
	exit_button.button_up.connect(_on_exit_button_up)
	ApolloPalette.style_menu_button(return_button)
	return_button.pressed.connect(_on_return_button_pressed)
	restart_button.hide()
	_seed_sliders()
	hide_menu()
	Signalbus.game_state_pause_changed.connect(_on_game_state_pause_changed)
	Signalbus.game_state_playing.connect(hide_menu)

	if OS.has_feature("web"):
		exit_button.hide()

func _on_game_state_pause_changed(paused: bool) -> void:
	if paused:
		show_menu()
	else:
		hide_menu()

func show_menu() -> void:
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	if _breathe_tween != null and _breathe_tween.is_valid():
		_breathe_tween.kill()
	_seed_sliders()
	show()
	_open_tween = ApolloPalette.make_open_tween(self, true)
	_open_tween.finished.connect(_start_breathe)

func hide_menu() -> void:
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	if _breathe_tween != null and _breathe_tween.is_valid():
		_breathe_tween.kill()
	ApolloPalette.reset_popup(self)
	_reset_exit_hold()
	hide()
	if _settings_dirty:
		_settings_dirty = false
		SettingsManager.save_settings()

func _seed_sliders() -> void:
	music_slider.set_value_no_signal(SettingsManager.music_volume)
	sfx_slider.set_value_no_signal(SettingsManager.sfx_volume)
	mouse_slider.set_value_no_signal(SettingsManager.mouse_sensitivity)

func _on_music_slider_value_changed(value: float) -> void:
	SettingsManager.music_volume = value
	SettingsManager.apply_audio()
	_settings_dirty = true

func _on_sfx_slider_value_changed(value: float) -> void:
	SettingsManager.sfx_volume = value
	SettingsManager.apply_audio()
	_settings_dirty = true

func _on_mouse_slider_value_changed(value: float) -> void:
	SettingsManager.mouse_sensitivity = value
	_settings_dirty = true

func _start_breathe() -> void:
	_breathe_tween = ApolloPalette.make_breathe_tween(self, true)

func _on_restart_button_pressed() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	GameManager.restart_level()

func _on_main_menu_pressed() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	GameManager.load_scene(GameManager.MAIN_MENU)

func _on_return_button_pressed() -> void:
	GameManager.resume_from_pause()

func _process(delta: float) -> void:
	_exit_hold_seconds += delta
	if _exit_hold_seconds >= EXIT_HOLD_SECONDS:
		get_tree().quit()

func _on_exit_button_down() -> void:
	_exit_hold_seconds = 0.0
	set_process(true)

func _on_exit_button_up() -> void:
	_reset_exit_hold()

func _reset_exit_hold() -> void:
	set_process(false)
	_exit_hold_seconds = 0.0
