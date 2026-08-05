class_name PlaceholderBossRoom extends EncounterRoomBase

func _ready() -> void:
	await super()
	if not encounter_cleared:
		clear_encounter()
