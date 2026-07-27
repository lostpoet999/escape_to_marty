extends RoomBase

## 1-based FLOOR_REGISTRY index; while this room is active it adopts that floor's FloorData wholesale — lighting, walls, 3D backdrop, seal pools, verb gates.
@export var mimic_floor_index: int = 1

func _enter_tree() -> void:
	var floors: Array[FloorData] = GameManager.FLOOR_REGISTRY.floors
	var idx: int = clampi(mimic_floor_index, 1, floors.size())
	var fd_variant: Variant = floors[idx - 1]
	GameManager.floor_data = fd_variant
