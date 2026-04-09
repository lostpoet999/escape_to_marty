@tool
class_name MinimapRoom
extends Control

# We're not updating the visited or cleared state on RoomState yet as far as I can tell
# When we do that, we can set this to transparent for unvisited rooms to not show up at all
# Or something like alpha 0.2 for them to show up but look different.
const UNVISITED_ROOMS_MOD : Color = Color.TRANSPARENT

@onready var background: ColorRect = $RoomBackground
@onready var player_indicator: TextureRect = $PlayerIndicator

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
	else:
		background.hide()
		player_indicator.hide()
