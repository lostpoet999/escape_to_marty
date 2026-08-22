class_name EncounterRoomBase extends RoomBase

const CODEC_PLAYER: PackedScene = preload("uid://ccodecplayer")
const BOSS_START_SOUND: String = "boss_fight_start"
const BOSS_CHEST_DRAW_SIZE: float = 128.0

## Optional memory beat played once, right after the encounter clears and before loot.
@export var post_encounter_tree: DialogTree

var encounter_cleared: bool = false

func _ready() -> void:
	mercy_clear_enabled = false
	seal_enemy_cooldown_enabled = false
	await super()
	if room_state.cleared:
		encounter_cleared = true
		_restore_cleared_encounter()
	else:
		SFX.play_sound(BOSS_START_SOUND)

func check_level_cleared() -> void:
	pass

func clear_encounter() -> void:
	if encounter_cleared:
		return
	encounter_cleared = true
	room_state.cleared = true
	Signalbus.level_cleared.emit()
	_clear_threats()
	await _play_room_celebrate()
	_sweep_encounter()
	await _play_post_encounter_beat()
	if not is_inside_tree():
		return
	_spawn_encounter_loot()
	_activate_floor_portal()

func _restore_cleared_encounter() -> void:
	_sweep_encounter()
	_spawn_encounter_loot()
	_activate_floor_portal()

func _sweep_encounter() -> void:
	var container: Node = find_child("Encounter", true, false)
	if container == null:
		return
	for child: Node in container.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()

func _clear_threats() -> void:
	_free_threats_under(self)

func _free_threats_under(node: Node) -> void:
	for child: Node in node.get_children():
		if child.is_queued_for_deletion():
			continue
		if _is_threat(child):
			child.queue_free()
			continue
		_free_threats_under(child)

func _is_threat(node: Node) -> bool:
	var coin: SpitCoin = node as SpitCoin
	if coin != null:
		return coin.hurts_on_miss
	return node is FallingEnemy

func _play_post_encounter_beat() -> void:
	if GameManager.test_floor_active:
		return
	if post_encounter_tree == null or post_encounter_tree.beats.is_empty():
		return
	var player: MemoryCodecPlayer = CODEC_PLAYER.instantiate()
	player.memory_tree = post_encounter_tree
	add_child(player)
	await player.play()
	if is_instance_valid(player):
		player.queue_free()

func _spawn_encounter_loot() -> void:
	var config: BossLootConfig = GameManager.floor_data.boss_loot_config
	if config == null:
		return
	if room_state.loot_items_data == null:
		room_state.loot_items_data = LootItemsData.new()
		room_state.loot_items_data.generate_boss_drop(config)
	loot_items_data = room_state.loot_items_data
	if loot_items_data.free_pick_exhausted():
		return
	_spawn_kiosk(FREE_ITEM_KIOSK, _on_free_item_kiosk_activated, BOSS_CHEST_DRAW_SIZE)

func _activate_floor_portal() -> void:
	var portal: FloorPortal = find_child("FloorPortal", true, false) as FloorPortal
	if portal != null:
		portal.activate()
