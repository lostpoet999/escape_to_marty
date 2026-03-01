extends Node

var score: int = 0
var stars_collected: int = 0
var player_current_health: int = 10
var player_max_health: int = 25


func update_player_score(amount: int) -> void:
	score += amount
	Signalbus.score_updated.emit()

func get_player_score() -> int:
	return score

func initialize_player_data() -> void:
	score = 0
	stars_collected = 0
	player_current_health = 10
	player_max_health = 25

func change_player_stars(star_value: int) -> void:
	stars_collected += star_value
	Signalbus.stars_updated.emit()


func accept_damage(damage: int) -> void:
	if player_current_health - damage > 0:
		player_current_health -= damage
		Signalbus.player_health_updated.emit()
	else:
		Signalbus.player_died.emit()

func get_player_health() -> int:
	return player_current_health

func get_player_stars() -> int:
	return stars_collected
