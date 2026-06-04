class_name StarsPayload extends BonusPayload

@export var stars: int = 100

func apply() -> void:
	PlayerData.change_player_stars(stars)
