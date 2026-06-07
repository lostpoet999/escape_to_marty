class_name RoomContent extends Resource

enum ROOM_TYPES {starting_room, combat, shop, memory, free_item, boss}

## room types with no combat objective — exits open on entry, and secret exits
## may be revealed by clicking while the room sits in LEVEL_CLEARED
const AUTO_CLEAR_ROOM_TYPES: Array[ROOM_TYPES] = [
	ROOM_TYPES.starting_room,
	ROOM_TYPES.shop,
	ROOM_TYPES.free_item,
]

@export var room_scene: PackedScene
@export var room_type: ROOM_TYPES
@export var is_secret: bool = false
## how many clears before the room is permanently cleared; -1 = never (replayable)
@export var max_clears: int
## guaranteed placement when pooled; filler otherwise (used by randomization)
@export var required: bool = false
