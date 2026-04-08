extends GridContainer

var room_template: PackedScene = preload("res://scenes_and_scripts/minimap/minimap_room.tscn")

func _ready() -> void:
	var data: FloorData = GameManager.floor_data
	var rooms: Array[MinimapRoom] = []
	columns = data.grid_size.x

	for i: int in range(data.grid_size.x * data.grid_size.y):
		var room: MinimapRoom = room_template.instantiate()
		rooms.append(room)
		add_child(room)

	for room_entry: RoomEntry in data.room_entries:
		var idx: int = (room_entry.room_coords.y - 1) * data.grid_size.x + (room_entry.room_coords.x - 1)
		var room_state: RoomState = PlayerData.get_room_state(room_entry)
		rooms[idx].room_entry = room_entry
		rooms[idx].is_visited = room_state.visited or room_state.cleared
		if room_entry.room_name_id == GameManager.current_room_id:
			rooms[idx].is_current = true
