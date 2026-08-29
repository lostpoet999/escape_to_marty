extends Control

@export var music: AudioStream
@export var music_volume_db: float = -5.0
@export var scroll_speed: float = 40.0
@export var scroll_top_pause: float = 2.0
@export var scroll_bottom_pause: float = 8.0

@onready var _credits_text: RichTextLabel = $"VBoxContainer/CreditsContainer/Credits Text"


func _ready() -> void:
	if music != null:
		MusicPlayer.play_song(music, music_volume_db)
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

func _on_main_menu_button_pressed() -> void:
	print("main menu button pressed")
	get_tree().change_scene_to_file("res://scenes_and_scripts/ui_main_menu/main_menu.tscn")
