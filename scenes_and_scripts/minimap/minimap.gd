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

	var scanner: bool = PlayerData.inventory != null and PlayerData.inventory.has_room_scanner()
	var idx_by_id: Dictionary = {}
	var revealed_ids: Dictionary = {}

	for room_entry: RoomEntry in data.room_entries:
		var idx: int = (room_entry.room_coords.y - 1) * data.grid_size.x + (room_entry.room_coords.x - 1)
		var room_state: RoomState = PlayerData.get_room_state(room_entry)
		rooms[idx].room_entry = room_entry
		rooms[idx].is_visited = room_state.visited or room_state.cleared
		rooms[idx].revealed_exits = room_state.revealed_exits
		idx_by_id[room_entry.room_name_id] = idx
		if room_entry.room_name_id == GameManager.current_room_id:
			rooms[idx].is_current = true
		if scanner and room_entry.room_name_id == GameManager.current_room_id:
			for exit_id: String in [room_entry.north_exit, room_entry.south_exit, room_entry.east_exit, room_entry.west_exit]:
				if exit_id != "":
					revealed_ids[exit_id] = true

	for exit_id: String in revealed_ids:
		if idx_by_id.has(exit_id):
			var target: MinimapRoom = rooms[idx_by_id[exit_id]]
			if not target.room_entry.is_secret: # secret rooms wait for a higher-tier scouting item
				target.is_revealed = true
