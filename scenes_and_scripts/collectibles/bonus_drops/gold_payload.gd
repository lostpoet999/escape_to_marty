class_name GoldPayload extends BonusPayload

@export var gold: int = 100

func apply() -> void:
	PlayerData.change_player_gold(gold)
