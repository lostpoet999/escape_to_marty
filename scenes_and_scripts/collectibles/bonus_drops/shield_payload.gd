class_name ShieldPayload extends BonusPayload

@export var shields: int = 1

func apply() -> void:
	PlayerData.grant_free_miss_shield(shields)
