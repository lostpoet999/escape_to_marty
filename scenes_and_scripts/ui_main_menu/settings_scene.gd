class_name SettingsScene
extends Control

const TIPS_CHECK_ICON_SCALE: int = 3
const CASUAL_TOOLTIP: String = "Easy at half the speed"
const EASY_TOOLTIP: String = "Slower ball speed. Missed balls hurt less. Gentler seals."
const NORMAL_TOOLTIP: String = "Standard ball speed, seal mix, and damage."
const HARD_TOOLTIP: String = "Faster ball speed. Full damage from missed balls. Tougher seals. No bonus item when retrying a floor."
const BRUTAL_TOOLTIP: String = "Hard at double the speed"

static var open_with_start_run: bool = false

@onready var start_run_button: Button = $"VBoxContainer/ButtonContainer/Start Run Button"
@onready var music_slider: HSlider = $"VBoxContainer/Settings Container/SettingsBox/MusicRow/MusicSlider"
@onready var sfx_slider: HSlider = $"VBoxContainer/Settings Container/SettingsBox/SfxRow/SfxSlider"
@onready var mouse_slider: HSlider = $"VBoxContainer/Settings Container/SettingsBox/MouseRow/MouseSlider"
@onready var tips_check: CheckBox = $"VBoxContainer/Settings Container/SettingsBox/TipsRow/TipsCheck"
@onready var gameplay_data_check: CheckBox = $"VBoxContainer/Settings Container/SettingsBox/GameplayDataRow/GameplayDataCheck"
@onready var player_name_edit: LineEdit = $"VBoxContainer/Settings Container/SettingsBox/PlayerNameRow/PlayerNameEdit"
@onready var player_name_hint: Label = $"VBoxContainer/Settings Container/SettingsBox/PlayerNameRow/PlayerNameHint"
@onready var casual_button: Button = $"VBoxContainer/Settings Container/SettingsBox/DifficultyRowMORE/DifficultyButtons/CasualButton"
@onready var easy_button: Button = $"VBoxContainer/Settings Container/SettingsBox/DifficultyRowMORE/DifficultyButtons/EasyButton"
@onready var normal_button: Button = $"VBoxContainer/Settings Container/SettingsBox/DifficultyRowMORE/DifficultyButtons/NormalButton"
@onready var hard_button: Button = $"VBoxContainer/Settings Container/SettingsBox/DifficultyRowMORE/DifficultyButtons/HardButton"
@onready var brutal_button: Button = $"VBoxContainer/Settings Container/SettingsBox/DifficultyRowMORE/DifficultyButtons/BrutalButton"

func _ready() -> void:
	start_run_button.visible = open_with_start_run
	_scale_check_icon(tips_check, &"checked")
	_scale_check_icon(tips_check, &"unchecked")
	_scale_check_icon(gameplay_data_check, &"checked")
	_scale_check_icon(gameplay_data_check, &"unchecked")
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	mouse_slider.value = SettingsManager.mouse_sensitivity
	tips_check.button_pressed = SettingsManager.show_tutorial_tips
	gameplay_data_check.button_pressed = SettingsManager.share_gameplay_data
	player_name_edit.text = SaveProgression.profile_name()
	casual_button.tooltip_text = CASUAL_TOOLTIP
	easy_button.tooltip_text = EASY_TOOLTIP
	normal_button.tooltip_text = NORMAL_TOOLTIP
	hard_button.tooltip_text = HARD_TOOLTIP
	brutal_button.tooltip_text = BRUTAL_TOOLTIP
	match SettingsManager.difficulty:
		0:
			if is_equal_approx(SettingsManager.game_speed, 0.5):
				casual_button.button_pressed = true
			else:
				easy_button.button_pressed = true
		2:
			if is_equal_approx(SettingsManager.ball_speed_scale, 2.0):
				brutal_button.button_pressed = true
			else:
				hard_button.button_pressed = true
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

func _on_gameplay_data_check_toggled(toggled_on: bool) -> void:
	SettingsManager.share_gameplay_data = toggled_on

func _on_player_name_edit_text_submitted(_raw_name: String) -> void:
	player_name_edit.release_focus()

func _on_player_name_edit_focus_exited() -> void:
	var clean_name: String = Telemetry.sanitize_name(player_name_edit.text)
	player_name_edit.text = clean_name
	if clean_name == SaveProgression.profile_name():
		return
	var claimed: String = await Telemetry.claim_name(clean_name)
	if not is_inside_tree():
		return
	if claimed != clean_name:
		player_name_edit.text = claimed
		player_name_hint.text = "%s is taken" % clean_name
		player_name_hint.show()
		return
	player_name_hint.hide()
	SaveProgression.set_profile_name(clean_name)

func _on_casual_button_pressed() -> void:
	SettingsManager.difficulty = 0
	SettingsManager.game_speed = 0.5
	SettingsManager.ball_speed_scale = 1.0

func _on_easy_button_pressed() -> void:
	SettingsManager.difficulty = 0
	SettingsManager.game_speed = 1
	SettingsManager.ball_speed_scale = 1.0

func _on_normal_button_pressed() -> void:
	SettingsManager.difficulty = 1
	SettingsManager.game_speed = 1
	SettingsManager.ball_speed_scale = 1.0

func _on_hard_button_pressed() -> void:
	SettingsManager.difficulty = 2
	SettingsManager.game_speed = 1
	SettingsManager.ball_speed_scale = 1.0

func _on_brutal_button_pressed() -> void:
	SettingsManager.difficulty = 2
	SettingsManager.game_speed = 1
	SettingsManager.ball_speed_scale = 2.0

func _scale_check_icon(check: CheckBox, icon_name: StringName) -> void:
	var icon: Texture2D = check.get_theme_icon(icon_name)
	var image: Image = icon.get_image()
	image.resize(image.get_width() * TIPS_CHECK_ICON_SCALE, image.get_height() * TIPS_CHECK_ICON_SCALE, Image.INTERPOLATE_NEAREST)
	check.add_theme_icon_override(icon_name, ImageTexture.create_from_image(image))

func _on_start_run_button_pressed() -> void:
	SettingsManager.save_settings()
	open_with_start_run = false
	GameManager.restart_run()

func _on_main_menu_button_pressed() -> void:
	SettingsManager.save_settings()
	open_with_start_run = false
	get_tree().change_scene_to_file("res://scenes_and_scripts/ui_main_menu/main_menu.tscn")
