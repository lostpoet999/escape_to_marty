class_name HighScoresScene
extends Control

@onready var board_rows: RichTextLabel = %BoardRows
@onready var tier_row: HBoxContainer = $"VBoxContainer/Board Container/BoardBox/TierRow"

var _board_request: int = 0


func _ready() -> void:
	var current: String = SettingsManager.tier_name()
	for child: Node in tier_row.get_children():
		var button: Button = child as Button
		if button != null and button.text == current:
			button.button_pressed = true
	_show_tier(current)


func _on_tier_button_pressed(tier: String) -> void:
	_show_tier(tier)


func _show_tier(tier: String) -> void:
	if not Telemetry.enabled():
		board_rows.text = "offline"
		return
	_board_request += 1
	var request: int = _board_request
	board_rows.text = "loading..."
	var rows: Array[Dictionary] = await Telemetry.fetch_top(tier)
	if request != _board_request or not is_inside_tree():
		return
	board_rows.text = Telemetry.format_rows(rows)


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes_and_scripts/ui_main_menu/main_menu.tscn")
