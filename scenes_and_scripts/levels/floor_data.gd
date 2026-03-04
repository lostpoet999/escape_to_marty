class_name FloorData extends Resource

@export var floor_id: int
@export var floor_name: String
@export var room_entries: Array[RoomEntry]
@export var grid_size: Vector2i = Vector2i(5,5)
@export var show_mini_map: bool
@export var starting_room: int
