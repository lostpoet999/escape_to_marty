class_name CurrencyPayload extends BonusPayload

@export var value: int = 1

func apply() -> void:
	PlayerData.change_player_gold(value)
