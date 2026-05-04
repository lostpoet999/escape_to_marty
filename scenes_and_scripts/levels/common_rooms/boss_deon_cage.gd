extends Node
@onready var boss_deon_cage: Node = $"."
var cage: Array
var seals: Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_seals_and_walls()
	Signalbus.deon_boss_seal_cleared.connect(_on_seal_cleared)
	

func _on_seal_cleared(seal: Node2D)->void:
	seals.erase(seal)
	if seals.is_empty():
		print ("wall cleared")
		Signalbus.deon_boss_cage_cleared.emit()
		boss_deon_cage.queue_free()
	else:		
		print("not yet")

func get_seals_and_walls() -> void:
	for child: Node2D in boss_deon_cage.get_children():
		if child.is_in_group("open_seal"):
			cage.append(child)
			seals.append(child)
		elif child.is_in_group("walls"):
			cage.append(child)
		else:
			print("ERROR: not in walls or seals")
