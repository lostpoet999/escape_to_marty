extends Control

func _on_main_menu_button_pressed() -> void:
	print("main menu button pressed")
	get_tree().change_scene_to_file("res://scenes_and_scripts/ui_main_menu/main_menu.tscn")
