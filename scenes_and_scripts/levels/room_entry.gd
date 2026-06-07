class_name  RoomEntry extends Resource

@export var room_coords: Vector2i
@export var is_static: bool = true
## pinned content for static slots; pooled content is assigned at runtime otherwise
@export var content: RoomContent

@export var north_exit: bool = false
@export var south_exit: bool = false
@export var east_exit: bool = false
@export var west_exit: bool = false

static func make_key(coords: Vector2i) -> String:
	return "%d_%d" % [coords.x, coords.y]

func has_door(offset: Vector2i) -> bool:
	match offset:
		Vector2i(0, -1): return north_exit
		Vector2i(0, 1): return south_exit
		Vector2i(1, 0): return east_exit
		Vector2i(-1, 0): return west_exit
	return false
