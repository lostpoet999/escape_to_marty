extends Control

@export var music: AudioStream
@export var music_volume_db: float = -5.0

func _ready() -> void:
	if music != null:
		MusicPlayer.play_song(music, music_volume_db)

func _on_main_menu_button_pressed() -> void:
	print("main menu button pressed")
	get_tree().change_scene_to_file("res://scenes_and_scripts/ui_main_menu/main_menu.tscn")
