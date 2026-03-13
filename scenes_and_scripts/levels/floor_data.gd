class_name FloorData extends Resource

@export_category("Spawn Rates:")
@export var common_spawn_weight: float
@export var uncommon_spawn_weight: float
@export var rare_spawn_weight: float
@export var very_rare_spawn_weight: float

@export_category("Floor Layout Data")
@export var floor_name_id: String
@export var room_entries: Array[RoomEntry]
@export var grid_size: Vector2i = Vector2i(5,5)
@export var show_mini_map: bool
@export var starting_room_id: String
@export var starting_room_scene: PackedScene
