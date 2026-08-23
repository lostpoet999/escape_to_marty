class_name SettingsScene
extends Control

const TIPS_CHECK_ICON_SCALE: int = 3

static var open_with_start_run: bool = false

@onready var start_run_button: Button = $"VBoxContainer/ButtonContainer/Start Run Button"
@onready var music_slider: HSlider = $"VBoxContainer/Settings Container/SettingsBox/MusicRow/MusicSlider"
@onready var sfx_slider: HSlider = $"VBoxContainer/Settings Container/SettingsBox/SfxRow/SfxSlider"
@onready var mouse_slider: HSlider = $"VBoxContainer/Settings Container/SettingsBox/MouseRow/MouseSlider"
@onready var tips_check: CheckBox = $"VBoxContainer/Settings Container/SettingsBox/TipsRow/TipsCheck"
@onready var easy_button: Button = $"VBoxContainer/Settings Container/SettingsBox/DifficultyRow/DifficultyButtons/EasyButton"
@onready var normal_button: Button = $"VBoxContainer/Settings Container/SettingsBox/DifficultyRow/DifficultyButtons/NormalButton"
@onready var hard_button: Button = $"VBoxContainer/Settings Container/SettingsBox/DifficultyRow/DifficultyButtons/HardButton"

func _ready() -> void:
	start_run_button.visible = open_with_start_run
	_scale_tips_check_icon(&"checked")
	_scale_tips_check_icon(&"unchecked")
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	mouse_slider.value = SettingsManager.mouse_sensitivity
	tips_check.button_pressed = SettingsManager.show_tutorial_tips
	match SettingsManager.difficulty:
		0: easy_button.button_pressed = true
		2: hard_button.button_pressed = true
		_: normal_button.button_pressed = true

func _on_music_slider_value_changed(value: float) -> void:
	SettingsManager.music_volume = value
	SettingsManager.apply_audio()

func _on_sfx_slider_value_changed(value: float) -> void:
	SettingsManager.sfx_volume = value
	SettingsManager.apply_audio()

func _on_mouse_slider_value_changed(value: float) -> void:
	SettingsManager.mouse_sensitivity = value

func _on_tips_check_toggled(toggled_on: bool) -> void:
	SettingsManager.show_tutorial_tips = toggled_on

func _on_easy_button_pressed() -> void:
	SettingsManager.difficulty = 0

func _on_normal_button_pressed() -> void:
	SettingsManager.difficulty = 1

func _on_hard_button_pressed() -> void:
	SettingsManager.difficulty = 2

func _scale_tips_check_icon(icon_name: StringName) -> void:
	var icon: Texture2D = tips_check.get_theme_icon(icon_name)
	var image: Image = icon.get_image()
	image.resize(image.get_width() * TIPS_CHECK_ICON_SCALE, image.get_height() * TIPS_CHECK_ICON_SCALE, Image.INTERPOLATE_NEAREST)
	tips_check.add_theme_icon_override(icon_name, ImageTexture.create_from_image(image))

func _on_start_run_button_pressed() -> void:
	SettingsManager.save_settings()
	open_with_start_run = false
	GameManager.restart_run()

func _on_main_menu_button_pressed() -> void:
	SettingsManager.save_settings()
	open_with_start_run = false
	get_tree().change_scene_to_file("res://scenes_and_scripts/ui_main_menu/main_menu.tscn")
