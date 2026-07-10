class_name DeonEncounterRoom extends EncounterRoomBase

func _ready() -> void:
	Signalbus.boss_defeated.connect(clear_encounter)
	await super()
