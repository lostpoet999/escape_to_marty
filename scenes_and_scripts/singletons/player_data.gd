extends Node

var score: int = 0
var stars_collected: int = 0
var player_current_health: int = 10
var player_max_health: int = 25

var inventory: PlayerInventory
var room_state: Dictionary = {}
var item_box: Node2D

var bankruptcy_stars_per_life_bonus: int = 0
var bankruptcy_damage_per_life_bonus: int = 0


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
	bankruptcy_stars_per_life_bonus = 0
	bankruptcy_damage_per_life_bonus = 0
	if inventory: inventory.free()
	inventory = PlayerInventory.new()
	add_child(inventory)

func change_player_stars(star_value: int) -> void:
	stars_collected += star_value
	Signalbus.stars_updated.emit()

func pay_bargain_cost(cost: int) -> void:
	if cost <= stars_collected:
		change_player_stars(-cost)
		return
	_cover_bankrupt_deal(cost)

func apply_bankruptcy_modifiers(stars_per_life_bonus: int, damage_per_life_bonus: int) -> void:
	bankruptcy_stars_per_life_bonus = stars_per_life_bonus
	bankruptcy_damage_per_life_bonus = damage_per_life_bonus

func _cover_bankrupt_deal(cost: int) -> void:
	var active_floor: FloorData = GameManager.floor_data
	if active_floor == null or not active_floor.bankruptcy_enabled:
		change_player_stars(-mini(cost, stars_collected))
		return
	var stars_per_life: int = maxi(active_floor.bankruptcy_stars_per_life + bankruptcy_stars_per_life_bonus, 1)
	var lives_needed: int = ceili(float(cost - stars_collected) / stars_per_life)
	var damage_per_life: int = maxi(active_floor.bankruptcy_damage_per_life + bankruptcy_damage_per_life_bonus, 0)
	accept_damage(lives_needed * damage_per_life)
	stars_collected += lives_needed * stars_per_life - cost
	Signalbus.stars_updated.emit()


func change_player_health(amount: int) -> void:
	player_current_health = clampi(player_current_health + amount, 0, player_max_health)
	Signalbus.player_health_updated.emit()

func accept_damage(damage: int) -> void:
	change_player_health(-damage)
	if damage > 0:
		Signalbus.player_damaged.emit(damage)
	if player_current_health <= 0:
		Signalbus.player_died.emit()

func get_player_health() -> int:
	return player_current_health

func get_player_stars() -> int:
	return stars_collected
