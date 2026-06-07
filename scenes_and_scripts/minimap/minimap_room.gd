@tool
class_name MinimapRoom
extends Control

const UNVISITED_ROOMS_MOD : Color = Color.TRANSPARENT

const TYPE_LETTERS: Dictionary = {
	RoomContent.ROOM_TYPES.starting_room: "S",
	RoomContent.ROOM_TYPES.combat: "",
	RoomContent.ROOM_TYPES.shop: "$",
	RoomContent.ROOM_TYPES.memory: "M",
	RoomContent.ROOM_TYPES.free_item: "F",
	RoomContent.ROOM_TYPES.boss: "B",
}
const TYPE_COLORS: Dictionary = {
	RoomContent.ROOM_TYPES.starting_room: Color(0.65, 0.85, 1.0),
	RoomContent.ROOM_TYPES.combat: Color.WHITE,
	RoomContent.ROOM_TYPES.shop: Color(1.0, 0.84, 0.0),
	RoomContent.ROOM_TYPES.memory: Color(0.7, 0.55, 0.95),
	RoomContent.ROOM_TYPES.free_item: Color(0.4, 0.9, 0.45),
	RoomContent.ROOM_TYPES.boss: Color(0.9, 0.2, 0.2),
}
const REVEALED_BLANK_GLYPH: String = "·"

@onready var background: ColorRect = $RoomBackground
@onready var player_indicator: TextureRect = $PlayerIndicator
@onready var north_exit: ColorRect = $ExitNorth
@onready var south_exit: ColorRect = $ExitSouth
@onready var east_exit: ColorRect = $ExitEast
@onready var west_exit: ColorRect = $ExitWest
@onready var type_label: Label = $TypeLabel

@export var room_entry: RoomEntry = null :
	set(v):
		room_entry = v
		_refresh()
@export var is_current: bool = false :
	set(v):
		is_current = v
		_refresh()
@export var is_visited: bool = false :
	set(v):
		is_visited = v
		_refresh()

@export var is_revealed: bool = false :
	set(v):
		is_revealed = v
		_refresh()

@export var revealed_exits: Array[StringName] = [] :
	set(v):
		revealed_exits = v
		_refresh()


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if room_entry:
		var discovered: bool = is_visited or is_current
		var letter: String = TYPE_LETTERS.get(room_entry.content.room_type, "")
		background.visible = discovered
		player_indicator.visible = is_current
		modulate = Color.WHITE if discovered or is_revealed else UNVISITED_ROOMS_MOD
		north_exit.visible = discovered and _exit_tick_visible(&"north", Vector2i(0, -1))
		south_exit.visible = discovered and _exit_tick_visible(&"south", Vector2i(0, 1))
		east_exit.visible = discovered and _exit_tick_visible(&"east", Vector2i(1, 0))
		west_exit.visible = discovered and _exit_tick_visible(&"west", Vector2i(-1, 0))
		var glyph: String = letter
		if is_revealed and not discovered and glyph == "":
			glyph = REVEALED_BLANK_GLYPH
		type_label.visible = (discovered or is_revealed) and glyph != ""
		type_label.text = glyph
		type_label.add_theme_color_override("font_color", TYPE_COLORS.get(room_entry.content.room_type, Color.WHITE))
	else:
		background.hide()
		player_indicator.hide()
		north_exit.hide()
		south_exit.hide()
		east_exit.hide()
		west_exit.hide()
		type_label.hide()


func _exit_tick_visible(direction: StringName, offset: Vector2i) -> bool:
	if not room_entry.has_door(offset):
		return false
	var rooms: Dictionary = GameManager.room_data_for_floor
	var target_id: String = RoomEntry.make_key(room_entry.room_coords + offset)
	if rooms.has(target_id) and rooms[target_id].content.is_secret and direction not in revealed_exits:
		return false
	return true
