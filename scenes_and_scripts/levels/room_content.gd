class_name RoomContent extends Resource

enum ROOM_TYPES {
	starting_room = 0,
	combat = 1,
	shop = 2,
	memory = 3,
	free_item = 4,
	boss = 5,
	bonus_room = 6,
	}

## room types with no combat objective — exits open on entry, and secret exits
## may be revealed by clicking while the room sits in LEVEL_CLEARED
const AUTO_CLEAR_ROOM_TYPES: Array[ROOM_TYPES] = [
	ROOM_TYPES.starting_room,
	ROOM_TYPES.shop,
	ROOM_TYPES.free_item,
	ROOM_TYPES.bonus_room,
]

enum FloorFlavor {
	INHERIT = 0,
	FLOOR_1 = 1,
	FLOOR_2 = 2,
	FLOOR_3 = 3,
	FLOOR_4 = 4,
	}

@export var room_scene: PackedScene
@export var room_type: ROOM_TYPES
## test-floor helper: while this room is active it adopts the picked floor's FloorData wholesale (seal phases, enemy spawns, walls, 3D backdrop, verb gates). INHERIT = leave the current floor's data alone.
@export var floor_flavor: FloorFlavor = FloorFlavor.INHERIT
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
## memory rooms only: the codec sequence the flame plays. the cross-run save key
## (memory_id) derives from this resource's filename
@export var memory_tree: DialogTree

func memory_id() -> StringName:
	if memory_tree != null and not memory_tree.resource_path.is_empty():
		return StringName(memory_tree.resource_path.get_file().get_basename())
	if room_scene == null:
		return &""
	return StringName(room_scene.resource_path.get_file().get_basename())
