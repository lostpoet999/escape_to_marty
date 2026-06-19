extends Control

@onready var music_slider: HSlider = $"VBoxContainer/Settings Container/SettingsBox/MusicRow/MusicSlider"
@onready var sfx_slider: HSlider = $"VBoxContainer/Settings Container/SettingsBox/SfxRow/SfxSlider"
@onready var easy_button: Button = $"VBoxContainer/Settings Container/SettingsBox/DifficultyRow/DifficultyButtons/EasyButton"
@onready var normal_button: Button = $"VBoxContainer/Settings Container/SettingsBox/DifficultyRow/DifficultyButtons/NormalButton"
@onready var hard_button: Button = $"VBoxContainer/Settings Container/SettingsBox/DifficultyRow/DifficultyButtons/HardButton"

func _ready() -> void:
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
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

func _on_easy_button_pressed() -> void:
	SettingsManager.difficulty = 0

func _on_normal_button_pressed() -> void:
	SettingsManager.difficulty = 1

func _on_hard_button_pressed() -> void:
	SettingsManager.difficulty = 2

func _on_main_menu_button_pressed() -> void:
	SettingsManager.save_settings()
	get_tree().change_scene_to_file("res://scenes_and_scripts/ui_main_menu/main_menu.tscn")
