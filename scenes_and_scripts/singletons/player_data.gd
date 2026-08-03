extends Node

const MAX_REFLECT_REDUCTION: float = 0.5
const REFLECT_MISS_CAP_RATIO: float = 0.85
const BASE_MAX_HEALTH: int = 10
const MAX_HEALTH_CEILING: int = 25
const MAX_FREE_MISS_SHIELDS: int = 1

var score: int = 0
var gold_collected: int = 0
var player_current_health: int = BASE_MAX_HEALTH
var player_max_health: int = BASE_MAX_HEALTH
var free_miss_shields: int = 0
var item_shields_spent: int = 0
var pick2_vouchers: int = 0
var shop_restock_vouchers: int = 0
var spider_stolen_gold: int = 0

var inventory: PlayerInventory
var room_state: Dictionary = {}
var item_box: Node2D
var seen_dialog_trees: Array[StringName] = []
var seen_cutscenes: Array[StringName] = []
var dialog_trigger_counts: Dictionary[StringName, int] = {}
var pending_memories: Array[StringName] = []
var retry_counts: Dictionary[int, int] = {}

var bankruptcy_gold_per_life_bonus: int = 0
var bankruptcy_damage_per_life_bonus: int = 0

const GOLD_STREAK_WINDOW: float = 1.0
const GOLD_STREAK_PITCH_STEP: float = 0.1
const GOLD_STREAK_MAX: int = 12
var _gold_streak: int = 0
var _last_gold_pickup_ms: int = -100000
var _last_barrier_clear_ms: int = -100000


func _ready() -> void:
	Signalbus.inventory_changed.connect(recompute_max_health)
	Signalbus.floor_cleared.connect(_on_floor_cleared)

func recompute_max_health() -> void:
	if inventory == null:
		return
	player_max_health = mini(BASE_MAX_HEALTH + inventory.get_max_health_bonus(), MAX_HEALTH_CEILING)
	player_current_health = mini(player_current_health, player_max_health)
	Signalbus.player_health_updated.emit()
	Signalbus.reflect_shield_changed.emit(get_player_shields())

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
	gold_collected = 0
	player_current_health = BASE_MAX_HEALTH
	player_max_health = BASE_MAX_HEALTH
	free_miss_shields = 0
	item_shields_spent = 0
	pick2_vouchers = 0
	shop_restock_vouchers = 0
	spider_stolen_gold = 0
	room_state.clear()
	seen_dialog_trees.clear()
	seen_cutscenes.clear()
	dialog_trigger_counts.clear()
	pending_memories.clear()
	retry_counts.clear()
	bankruptcy_gold_per_life_bonus = 0
	bankruptcy_damage_per_life_bonus = 0
	_last_barrier_clear_ms = -100000
	if inventory: inventory.free()
	inventory = PlayerInventory.new()
	add_child(inventory)
	GameManager.grant_memory_trophies()

func change_player_gold(gold_value: int) -> void:
	gold_collected += gold_value
	Signalbus.gold_updated.emit()

func grant_gold_over_time(amount: int, duration: float) -> void:
	if amount <= 0:
		return
	var interval: float = duration / amount
	var tween: Tween = create_tween()
	for i: int in amount:
		tween.tween_callback(change_player_gold.bind(1))
		tween.tween_callback(play_gold_pickup_sfx)
		if i < amount - 1:
			tween.tween_interval(interval)

func play_gold_pickup_sfx() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_gold_pickup_ms > roundi(GOLD_STREAK_WINDOW * 1000.0):
		_gold_streak = 0
	_last_gold_pickup_ms = now
	var sfx_player: AudioStreamPlayer = SFX.play_sound("gold_collected")
	if sfx_player != null:
		var base_pitch: float = SFX.sound_dict["gold_collected"].pitch_scale
		sfx_player.pitch_scale = base_pitch + GOLD_STREAK_PITCH_STEP * mini(_gold_streak, GOLD_STREAK_MAX)
	_gold_streak += 1

func pay_bargain_cost(cost: int, allow_damage: bool = true) -> void:
	if cost <= gold_collected:
		change_player_gold(-cost)
		return
	if not allow_damage:
		change_player_gold(-mini(cost, gold_collected))
		return
	_cover_bankrupt_deal(cost)

func apply_bankruptcy_modifiers(gold_per_life_bonus: int, damage_per_life_bonus: int) -> void:
	bankruptcy_gold_per_life_bonus = gold_per_life_bonus
	bankruptcy_damage_per_life_bonus = damage_per_life_bonus

func _cover_bankrupt_deal(cost: int) -> void:
	var active_floor: FloorData = GameManager.floor_data
	if active_floor == null or not active_floor.bankruptcy_enabled:
		change_player_gold(-mini(cost, gold_collected))
		return
	var gold_per_life: int = maxi(active_floor.bankruptcy_gold_per_life + bankruptcy_gold_per_life_bonus, 1)
	var lives_needed: int = ceili(float(cost - gold_collected) / gold_per_life)
	var damage_per_life: int = maxi(active_floor.bankruptcy_damage_per_life + bankruptcy_damage_per_life_bonus, 0)
	accept_damage(lives_needed * damage_per_life)
	gold_collected += lives_needed * gold_per_life - cost
	Signalbus.gold_updated.emit()


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
	if get_item_shields() > 0:
		item_shields_spent += 1
		Signalbus.reflect_shield_changed.emit(get_player_shields())
		return
	if free_miss_shields > 0:
		free_miss_shields -= 1
		Signalbus.reflect_shield_changed.emit(get_player_shields())
		return
	var reduction: float = inventory.get_reflect_reduction() if inventory else 0.0
	var mitigated: float = amount * (1.0 - reduction)
	var capped: float = minf(mitigated, player_max_health * REFLECT_MISS_CAP_RATIO)
	accept_damage(maxi(1, roundi(capped)))

func grant_free_miss_shield(count: int = 1) -> void:
	free_miss_shields = mini(free_miss_shields + count, MAX_FREE_MISS_SHIELDS)
	Signalbus.reflect_shield_changed.emit(get_player_shields())

func _on_floor_cleared() -> void:
	commit_pending_memories()
	if item_shields_spent == 0:
		return
	item_shields_spent = 0
	Signalbus.reflect_shield_changed.emit(get_player_shields())

func collect_memory(memory_id: StringName) -> void:
	if memory_id not in pending_memories:
		pending_memories.append(memory_id)

func is_memory_collected(memory_id: StringName) -> bool:
	return memory_id in pending_memories or SaveProgression.is_memory_seen(memory_id)

func commit_pending_memories() -> void:
	for memory_id: StringName in pending_memories:
		SaveProgression.mark_memory_seen(memory_id)
	pending_memories.clear()

func refresh_for_retry() -> void:
	pending_memories.clear()
	item_shields_spent = 0
	heal_to_full()
	Signalbus.reflect_shield_changed.emit(get_player_shields())

func build_checkpoint() -> Dictionary:
	var trigger_counts: Dictionary = {}
	for key: StringName in dialog_trigger_counts:
		trigger_counts[String(key)] = dialog_trigger_counts[key]
	var retries: Dictionary = {}
	for floor_index: int in retry_counts:
		retries[str(floor_index)] = retry_counts[floor_index]
	return {
		"score": score,
		"gold": gold_collected,
		"health": player_current_health,
		"free_miss_shields": free_miss_shields,
		"item_shields_spent": item_shields_spent,
		"pick2_vouchers": pick2_vouchers,
		"shop_restock_vouchers": shop_restock_vouchers,
		"spider_stolen_gold": spider_stolen_gold,
		"bankruptcy_gold_per_life_bonus": bankruptcy_gold_per_life_bonus,
		"bankruptcy_damage_per_life_bonus": bankruptcy_damage_per_life_bonus,
		"seen_dialog_trees": seen_dialog_trees.map(func(id: StringName) -> String: return String(id)),
		"seen_cutscenes": seen_cutscenes.map(func(id: StringName) -> String: return String(id)),
		"dialog_trigger_counts": trigger_counts,
		"retry_counts": retries,
		"items": _item_paths(inventory.items),
		"core_items": _item_paths(inventory.core_items),
	}

func _item_paths(source: Array[BaseItem]) -> Array:
	var paths: Array = []
	for item: BaseItem in source:
		if item.resource_path == "":
			push_warning("checkpoint skips unsaved item: %s" % item)
			continue
		paths.append(item.resource_path)
	return paths

func restore_checkpoint(data: Dictionary) -> void:
	score = int(data.get("score", 0))
	gold_collected = int(data.get("gold", 0))
	free_miss_shields = int(data.get("free_miss_shields", 0))
	item_shields_spent = int(data.get("item_shields_spent", 0))
	pick2_vouchers = int(data.get("pick2_vouchers", 0))
	shop_restock_vouchers = int(data.get("shop_restock_vouchers", 0))
	spider_stolen_gold = int(data.get("spider_stolen_gold", 0))
	bankruptcy_gold_per_life_bonus = int(data.get("bankruptcy_gold_per_life_bonus", 0))
	bankruptcy_damage_per_life_bonus = int(data.get("bankruptcy_damage_per_life_bonus", 0))
	seen_dialog_trees.clear()
	for id: String in data.get("seen_dialog_trees", []):
		seen_dialog_trees.append(StringName(id))
	seen_cutscenes.clear()
	for id: String in data.get("seen_cutscenes", []):
		seen_cutscenes.append(StringName(id))
	dialog_trigger_counts.clear()
	var trigger_counts: Dictionary = data.get("dialog_trigger_counts", {})
	for key: String in trigger_counts:
		dialog_trigger_counts[StringName(key)] = int(trigger_counts[key])
	retry_counts.clear()
	var retries: Dictionary = data.get("retry_counts", {})
	for key: String in retries:
		retry_counts[int(key)] = int(retries[key])
	pending_memories.clear()
	inventory.items.clear()
	for path: String in data.get("items", []):
		var item: BaseItem = load(path)
		if item != null:
			inventory.items.append(item)
	inventory.core_items.clear()
	for path: String in data.get("core_items", []):
		var core_item: BaseItem = load(path)
		if core_item != null:
			inventory.core_items.append(core_item)
	Signalbus.inventory_changed.emit()
	player_current_health = clampi(int(data.get("health", BASE_MAX_HEALTH)), 1, player_max_health)
	Signalbus.player_health_updated.emit()

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

func barrier_clear_ready() -> bool:
	var item: UtilityPowerup = inventory.get_barrier_clear() if inventory != null else null
	if item == null:
		return false
	return Time.get_ticks_msec() - _last_barrier_clear_ms >= int(item.barrier_clear_cooldown * 1000.0)

func consume_barrier_clear() -> void:
	_last_barrier_clear_ms = Time.get_ticks_msec()

func get_player_health() -> int:
	return player_current_health

func get_item_shields() -> int:
	var owned: int = inventory.get_shield_count() if inventory else 0
	return maxi(owned - item_shields_spent, 0)

func get_player_shields() -> int:
	return get_item_shields() + free_miss_shields

func get_player_gold() -> int:
	return gold_collected
