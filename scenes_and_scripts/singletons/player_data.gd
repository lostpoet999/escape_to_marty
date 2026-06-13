extends Node

const MAX_REFLECT_REDUCTION: float = 0.5
const REFLECT_MISS_CAP_RATIO: float = 0.85
const BASE_MAX_HEALTH: int = 10
const MAX_HEALTH_CEILING: int = 25
const MAX_FREE_MISS_SHIELDS: int = 1

var score: int = 0
var stars_collected: int = 0
var player_current_health: int = BASE_MAX_HEALTH
var player_max_health: int = BASE_MAX_HEALTH
var free_miss_shields: int = 0
var pick2_vouchers: int = 0
var shop_restock_vouchers: int = 0

var inventory: PlayerInventory
var room_state: Dictionary = {}
var item_box: Node2D
var seen_dialog_trees: Array[StringName] = []
var seen_cutscenes: Array[StringName] = []
var dialog_trigger_counts: Dictionary[StringName, int] = {}

var bankruptcy_stars_per_life_bonus: int = 0
var bankruptcy_damage_per_life_bonus: int = 0


func _ready() -> void:
	Signalbus.inventory_changed.connect(recompute_max_health)

func recompute_max_health() -> void:
	if inventory == null:
		return
	player_max_health = mini(BASE_MAX_HEALTH + inventory.get_max_health_bonus(), MAX_HEALTH_CEILING)
	player_current_health = mini(player_current_health, player_max_health)
	Signalbus.player_health_updated.emit()

func update_player_score(amount: int) -> void:
	score += amount
	Signalbus.score_updated.emit()

func get_player_score() -> int:
	return score

func get_room_state(entry: RoomEntry)->RoomState:
	var id: String = RoomEntry.make_key(entry.room_coords)
	if !room_state.has(id):
		room_state[id] = RoomState.new()
	return room_state[id]

func initialize_player_data() -> void:
	score = 0
	stars_collected = 0
	player_current_health = BASE_MAX_HEALTH
	player_max_health = BASE_MAX_HEALTH
	free_miss_shields = 0
	pick2_vouchers = 0
	shop_restock_vouchers = 0
	room_state.clear()
	seen_dialog_trees.clear()
	seen_cutscenes.clear()
	dialog_trigger_counts.clear()
	bankruptcy_stars_per_life_bonus = 0
	bankruptcy_damage_per_life_bonus = 0
	if inventory: inventory.free()
	inventory = PlayerInventory.new()
	add_child(inventory)
	GameManager.grant_memory_trophies()

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

func heal_to_full() -> void:
	player_current_health = player_max_health
	Signalbus.player_health_updated.emit()

func accept_damage(damage: int) -> void:
	change_player_health(-damage)
	if damage > 0:
		Signalbus.player_damaged.emit(damage)
	if player_current_health <= 0:
		Signalbus.player_died.emit()

func accept_reflect_damage(amount: float) -> void:
	if free_miss_shields > 0:
		free_miss_shields -= 1
		Signalbus.reflect_shield_changed.emit(free_miss_shields)
		return
	var reduction: float = inventory.get_reflect_reduction() if inventory else 0.0
	var mitigated: float = amount * (1.0 - reduction)
	var capped: float = minf(mitigated, player_max_health * REFLECT_MISS_CAP_RATIO)
	accept_damage(maxi(1, roundi(capped)))

func grant_free_miss_shield(count: int = 1) -> void:
	free_miss_shields = mini(free_miss_shields + count, MAX_FREE_MISS_SHIELDS)
	Signalbus.reflect_shield_changed.emit(free_miss_shields)

func grant_pick2_voucher(count: int = 1) -> void:
	pick2_vouchers += count
	Signalbus.pick2_vouchers_changed.emit(pick2_vouchers)

func consume_pick2_voucher() -> bool:
	if pick2_vouchers <= 0:
		return false
	pick2_vouchers -= 1
	Signalbus.pick2_vouchers_changed.emit(pick2_vouchers)
	return true

func grant_shop_restock_voucher(count: int = 1) -> void:
	shop_restock_vouchers += count
	Signalbus.shop_restock_vouchers_changed.emit(shop_restock_vouchers)

func consume_shop_restock_voucher() -> bool:
	if shop_restock_vouchers <= 0:
		return false
	shop_restock_vouchers -= 1
	Signalbus.shop_restock_vouchers_changed.emit(shop_restock_vouchers)
	return true

func get_player_health() -> int:
	return player_current_health

func get_player_stars() -> int:
	return stars_collected
