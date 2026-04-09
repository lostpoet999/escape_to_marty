@tool
class_name MinimapRoom
extends Control

# We're not updating the visited or cleared state on RoomState yet as far as I can tell
# When we do that, we can set this to transparent for unvisited rooms to not show up at all
# Or something like alpha 0.2 for them to show up but look different.
const UNVISITED_ROOMS_MOD : Color = Color.TRANSPARENT

@onready var background: ColorRect = $RoomBackground
@onready var player_indicator: TextureRect = $PlayerIndicator
@onready var north_exit: ColorRect = $ExitNorth
@onready var south_exit: ColorRect = $ExitSouth
@onready var east_exit: ColorRect = $ExitEast
@onready var west_exit: ColorRect = $ExitWest

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


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if room_entry:
		background.show()
		player_indicator.visible = is_current
		modulate = Color.WHITE if is_visited or is_current else UNVISITED_ROOMS_MOD
		north_exit.visible = bool(room_entry.north_exit != "")
		south_exit.visible = bool(room_entry.south_exit != "")
		east_exit.visible = bool(room_entry.east_exit != "")
		west_exit.visible = bool(room_entry.west_exit != "")
	else:
		background.hide()
		player_indicator.hide()
		north_exit.hide()
		south_exit.hide()
		east_exit.hide()
		west_exit.hide()
