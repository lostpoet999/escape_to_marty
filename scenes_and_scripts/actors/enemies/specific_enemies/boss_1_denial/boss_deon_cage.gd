extends Node
@onready var boss_deon_cage: Node = $"."
var cage: Array
var seals: Array
var _seal_total: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_seals_and_walls()
	Signalbus.deon_boss_seal_cleared.connect(_on_seal_cleared)
	Signalbus.encounter_progress.emit.call_deferred(1, 3, float(_seal_total), float(_seal_total))


func _on_seal_cleared(seal: Node2D)->void:
	seals.erase(seal)
	Signalbus.encounter_progress.emit(1, 3, float(seals.size()), float(_seal_total))
	if seals.is_empty():
		Signalbus.deon_boss_cage_cleared.emit()
		boss_deon_cage.queue_free()	

func get_seals_and_walls() -> void:
	for child: Node2D in boss_deon_cage.get_children():
		if child.is_in_group("open_seal"):
			cage.append(child)
			seals.append(child)
		elif child.is_in_group("walls"):
			cage.append(child)
		else:
			print("ERROR: not in walls or seals")
	_seal_total = seals.size()
