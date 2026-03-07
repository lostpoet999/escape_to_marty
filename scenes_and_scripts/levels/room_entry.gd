class_name  RoomEntry extends Resource

enum room_types{starting_room,combat,shop,memory,free_item}

@export var room_name_id: String
@export var room_scene: PackedScene
@export var room_coords: Vector2i #most rooms in the floor will be in 5x5 grid so the player can see minimap
@export var room_type: room_types
@export var north_exit: String = ""
@export var south_exit: String = ""
@export var east_exit: String = ""
@export var west_exit: String = ""
@export var brick_layout: BrickLayout #for future editor/png importer

#TODO: exit conditions for each exit
