extends Control

@onready var stars: Label = $MarginContainer/HBoxContainer/Stars
@onready var score: Label = $MarginContainer/HBoxContainer/Score
@onready var health: Label = $MarginContainer/HBoxContainer/health

func _ready() -> void:
	Signalbus.stars_updated.connect(update_star_ui)
	Signalbus.score_updated.connect(update_score_ui)
	Signalbus.player_health_updated.connect(update_player_health)

func update_star_ui() -> void:
	stars.text = str(PlayerData.get_player_stars())

func update_score_ui() -> void:
	score.text = str(PlayerData.get_player_score())
	
func update_player_health() -> void:
	health.text = str(PlayerData.get_player_health())
