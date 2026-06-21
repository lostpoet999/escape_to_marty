class_name RoomContent extends Resource

enum ROOM_TYPES {starting_room, combat, shop, memory, free_item, boss, bonus_room}

## room types with no combat objective — exits open on entry, and secret exits
## may be revealed by clicking while the room sits in LEVEL_CLEARED
const AUTO_CLEAR_ROOM_TYPES: Array[ROOM_TYPES] = [
	ROOM_TYPES.starting_room,
	ROOM_TYPES.shop,
	ROOM_TYPES.free_item,
	ROOM_TYPES.bonus_room,
]

@export var room_scene: PackedScene
@export var room_type: ROOM_TYPES
@export var is_secret: bool = false
## how many clears before the room is permanently cleared; -1 = never (replayable)
@export var max_clears: int
## guaranteed placement when pooled; filler otherwise (used by randomization)
@export var required: bool = false
## the floor's memory trophy — kept across runs once you grab it
@export var bonus_item: BaseItem
## free-item/memory rooms only: a curated pool to draw the offered picks from instead of the
## floor's rarity-weighted master pool. when set, picks are flat-random so every listed item is equally likely
@export var item_pool_override: ItemPool

func memory_id() -> StringName:
	if room_scene == null:
		return &""
	return StringName(room_scene.resource_path.get_file().get_basename())
