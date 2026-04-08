class_name MinimapRoom
extends Control

@onready var background: ColorRect = $RoomBackground
@onready var player_indicator: TextureRect = $PlayerIndicator

@export var room_entry: RoomEntry = null : set=set_room_entry
@export var is_current: bool = false : set=set_current

func _ready() -> void:
	set_room_entry(room_entry)
	set_current(is_current)

func set_current(_is_current: bool) -> void:
	is_current = _is_current
	_refresh()

func set_room_entry(_room_entry: RoomEntry) -> void:
	room_entry = _room_entry
	_refresh()

func _refresh() -> void:
	if room_entry:
		background.show()
		if is_current:
			player_indicator.show()
		else:
			player_indicator.hide()
	else:
		background.hide()
		player_indicator.hide()
