class_name  RoomEntry extends Resource

enum room_types{starting_room,combat,shop,memory,free_item}

@export var room_id: int
@export var room_name: String
@export var room_coords: Vector2i #most rooms in the floor will be in 5x5 grid so the player can see minimap
@export var room_type: room_types
@export var north_exit: int = -1
@export var south_exit: int = -1
@export var east_exit: int = -1
@export var west_exit: int = -1
@export var brick_layout: BrickLayout
@export var spawn_plan: SpawnPlan

#@export var exit_conditions: TBD **Note: might be another array of key items and/or flaggs. this field would accept multiple entries of what is required
