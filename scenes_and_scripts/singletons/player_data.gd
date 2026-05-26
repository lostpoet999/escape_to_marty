extends Node

var score: int = 0
var stars_collected: int = 0
var player_current_health: int = 10
var player_max_health: int = 25

var inventory: PlayerInventory
var room_state: Dictionary = {}
var item_box: Node2D


func update_player_score(amount: int) -> void:
	score += amount
	Signalbus.score_updated.emit()

func get_player_score() -> int:
	return score

func get_room_state(entry: RoomEntry)->RoomState:
	var id: String = entry.room_name_id
	if !room_state.has(id):
		room_state[id] = RoomState.new()
	return room_state[id]

func initialize_player_data() -> void:
	score = 0
	stars_collected = 0
	player_current_health = 10
	player_max_health = 25
	room_state.clear()
		
	## If this is reset every level, this probably isn't the right spot, as I imagine
	## inventory should be persistent across levels, but you can make that call.
	## This deletes any existing inventory instance and makes a new one.
	if inventory: inventory.free()
	inventory = PlayerInventory.new()
	add_child(inventory)

func change_player_stars(star_value: int) -> void:
	stars_collected += star_value
	Signalbus.stars_updated.emit()


func change_player_health(amount: int) -> void:
	player_current_health = clampi(player_current_health + amount, 0, player_max_health)
	Signalbus.player_health_updated.emit()

func accept_damage(damage: int) -> void:
	change_player_health(-damage)
	if player_current_health <= 0:
		Signalbus.player_died.emit()

func get_player_health() -> int:
	return player_current_health

func get_player_stars() -> int:
	return stars_collected
