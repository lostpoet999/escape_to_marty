class_name HealPayload extends BonusPayload

func apply() -> void:
	PlayerData.heal_to_full()
