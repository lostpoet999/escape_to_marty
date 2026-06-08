extends Node2D

const ESCAPED_SPIRIT: PackedScene = preload("uid://5j2pau7yvts4")
const DAMAGE_NUMBER: PackedScene = preload("uid://bedvoohhfbi03")
const FREE_ITEM_PANEL: PackedScene = preload("uid://ct8n40refigl7")
const SHOP_PANEL: PackedScene = preload("uid://cshoppanel1")

const PLAYER_HURT_TRAUMA: float = 0.8

var stars_cleared: bool = false
var bricks_cleared: bool = false
var stars_in_level: int = 0
var bricks_in_level: int = 0
@onready var game_state_lbl: Label = $PlayArea/GameState_Lbl
@onready var current_room_lbl: Label = $PlayArea/CurrentRoom_Lbl
@onready var item_spawn_point: Marker2D = $item_spawn_point

var room_state: RoomState
var entry: RoomEntry
@onready var loot_items_data: LootItemsData
@onready var item_box: Itembox
@onready var no_respawn: Node2D = $"No-Respawn"
@onready var play_background: ColorRect = $PlayArea/Background
@onready var flash_overlay: ColorRect = $PlayArea/FlashOverlay
@onready var canvas_modulate_node: CanvasModulate = $CanvasModulate
@onready var paddle: Paddle = $Paddle



func _process(_delta: float) -> void:
	game_state_lbl.text = "Game State: " + GameManager.GameState.keys()[GameManager.current_state]

	
func supress_respawn_entities()->void:
	no_respawn.queue_free()	

func _ready() -> void:

	visible = false
	entry = GameManager.get_current_floor_entry(GameManager.current_room_id)
	room_state = PlayerData.get_room_state(entry)
	Signalbus.level_cleared.connect(_on_level_cleared_boss_extras)
	if room_state.cleared:
		supress_respawn_entities()
		Signalbus.level_cleared.emit()
	_apply_floor_wall_visuals()
	await get_tree().process_frame
	visible = true
	room_state.visited = true
	bricks_in_level = get_tree().get_nodes_in_group("bricks").size()
	current_room_lbl.text = "Current Room: " + GameManager.current_room_id
	Signalbus.stars_updated.emit()
	Signalbus.score_updated.emit()
	Signalbus.player_health_updated.emit()
	Signalbus.brick_destroyed.connect(_on_brick_destroyed)
	Signalbus.star_collected.connect(update_stars_in_level)
	Signalbus.star_spawned.connect(update_stars_in_level)
	Signalbus.enemy_requested.connect(_on_enemy_requested)
	Signalbus.screen_flash.connect(flash_play_area)
	Signalbus.player_damaged.connect(_on_player_damaged)
	initiate_special_room()

func flash_play_area(color: Color) -> void:
	flash_overlay.color = Color(color.r, color.g, color.b, 0.0)
	var tw: Tween = create_tween()
	tw.tween_property(flash_overlay, "color:a", 0.45, 0.06)
	tw.tween_property(flash_overlay, "color:a", 0.0, 0.35)

func _on_player_damaged(amount: int) -> void:
	flash_play_area(Color.RED)
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_trauma"):
		cam.add_trauma(PLAYER_HURT_TRAUMA)
	SFX.play_sound("player_hurt")
	paddle.hit_feedback()
	var damage_number := DAMAGE_NUMBER.instantiate()
	damage_number.position = paddle.david_global_position()
	add_child(damage_number)
	damage_number.show_damage("-" + str(amount), DamageNumber.COLOR_TAKEN)

func _on_level_cleared_boss_extras() -> void:
	if entry.content.room_type != RoomContent.ROOM_TYPES.boss:
		return
			
	room_state.cleared = true
	_despawn_boss_entities()
	_spawn_boss_drop()
	_activate_floor_portal()

func _spawn_boss_drop() -> void:
	var config: BossLootConfig = GameManager.floor_data.boss_loot_config
	if config == null:
		return
	# first defeat: generate and persist; re-entry: reuse persisted (preserves unclaimed items)
	if room_state.loot_items_data == null:
		room_state.loot_items_data = LootItemsData.new()
		room_state.loot_items_data.generate_boss_drop(config)
	loot_items_data = room_state.loot_items_data
	if loot_items_data.items.is_empty():
		return
	item_box = loot_items_data.instantiate_lootbox()
	item_box.global_position = item_spawn_point.global_position
	item_box.loot_items_data = loot_items_data
	add_child(item_box)

func _activate_floor_portal() -> void:
	var portal: FloorPortal = find_child("FloorPortal", true, false) as FloorPortal
	if portal != null:
		portal.activate()

func _despawn_boss_entities() -> void:
	var cage: Node = find_child("BossDeonCage", true, false)
	if cage != null and not cage.is_queued_for_deletion():
		cage.queue_free()
	var boss: Node = find_child("Boss1Denial", true, false)
	if boss != null and not boss.is_queued_for_deletion():
		boss.queue_free()

func initiate_special_room()->void:
	if entry.content.room_type in RoomContent.AUTO_CLEAR_ROOM_TYPES:
		bricks_cleared = true
		stars_cleared = true
		check_level_cleared()
	match entry.content.room_type:
		RoomContent.ROOM_TYPES.free_item:
			if !room_state.loot_items_data:
				room_state.generate_item_box()
			if !room_state.loot_items_data.items.is_empty():
				loot_items_data = room_state.loot_items_data
				var panel: FreeItemPanel = FREE_ITEM_PANEL.instantiate()
				panel.z_index = 500
				panel.setup(loot_items_data)
				$PlayArea.add_child(panel)
		RoomContent.ROOM_TYPES.shop:
			if !room_state.loot_items_data:
				room_state.generate_item_box()
			if !room_state.loot_items_data.items.is_empty():
				loot_items_data = room_state.loot_items_data
				var panel: ShopPanel = SHOP_PANEL.instantiate()
				panel.z_index = 500
				panel.setup(loot_items_data)
				$PlayArea.add_child(panel)

func _on_enemy_requested(spawn_from: Area2D) -> void: # for brick break enemies
	var seal_break_enemies: Array[EnemyConfig] = GameManager.floor_data.seal_break_enemies
	var config: EnemyConfig = pick_seal_break_config(seal_break_enemies)
	
	if config and not _config_at_spawn_cap(config):
		var enemy: FallingEnemy = config.scene_ref.instantiate()
		enemy.add_to_group(_spawn_cap_group(config))
		spawn_from.get_parent().add_child(enemy)
		enemy.position = spawn_from.position
	else:#freed-spirit
		var spirit: Node2D = ESCAPED_SPIRIT.instantiate()
		spirit.position = spawn_from.position
		spawn_from.get_parent().add_child(spirit)

func pick_seal_break_config(enemy_configs: Array[EnemyConfig]) -> EnemyConfig: #for brick break enemies
	var index: int = 0
	var spawned_percentage: float = randf() * 100
	while (index < enemy_configs.size()):
		var spawn_configuration: EnemyConfig = enemy_configs[index]
		if (spawned_percentage < spawn_configuration.spawn_chance):
			return spawn_configuration
		else:
			spawned_percentage -= spawn_configuration.spawn_chance
			index += 1
	return null

func _config_at_spawn_cap(config: EnemyConfig) -> bool:
	if config.max_global_spawn <= 0:
		return false
	return get_tree().get_nodes_in_group(_spawn_cap_group(config)).size() >= config.max_global_spawn

func _spawn_cap_group(config: EnemyConfig) -> StringName:
	return StringName("seal_break_enemy_" + config.enemy_name)

func check_level_cleared() -> void: #let gamemanager know level is cleared
	if entry.content.room_type == RoomContent.ROOM_TYPES.boss:
		return
	var max_clear:int = GameManager.get_current_floor_entry(GameManager.current_room_id).content.max_clears
	if stars_cleared && bricks_cleared:
		Signalbus.level_cleared.emit()
		room_state.clear_count +=1
		if entry.content.max_clears == -1: return
		if room_state.clear_count >= max_clear: room_state.cleared = true

func update_stars_in_level(amount: int) -> void:
	stars_in_level += amount
	if stars_in_level <= 0:
		stars_cleared = true
		check_level_cleared()
	else:
		stars_cleared = false

func _on_brick_destroyed() -> void:
	bricks_in_level -= 1
	if bricks_in_level <= 0:
		bricks_cleared = true
		check_level_cleared()

func _apply_floor_wall_visuals() -> void:
	var fd: FloorData = GameManager.floor_data
	if fd == null:
		return
	# local RNG seeded by room id so jitter/flip stay stable across re-entries
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(GameManager.current_room_id)
	var base_tint: Color = fd.wall_modulate
	base_tint.a *= fd.wall_alpha
	for wall: Node in get_tree().get_nodes_in_group("walls"):
		for child: Node in wall.find_children("*", "", true, false):

			if (child is TextureRect or child is Sprite2D) and child.texture != null:
				if fd.wall_texture != null:
					child.texture = fd.wall_texture
				child.self_modulate = _jittered(base_tint, fd.wall_brightness_jitter, rng)
				child.texture_filter = fd.wall_texture_filter
				if fd.wall_random_flip:
					child.flip_h = rng.randi() % 2 == 0
					child.flip_v = rng.randi() % 2 == 0
	play_background.color = fd.background_color
	canvas_modulate_node.color = fd.canvas_modulate_color

func _jittered(base: Color, amount: float, rng: RandomNumberGenerator) -> Color:
	if amount <= 0.0:
		return base
	var j: float = rng.randf_range(-amount, amount)
	return Color(clampf(base.r + j, 0.0, 1.0), clampf(base.g + j, 0.0, 1.0), clampf(base.b + j, 0.0, 1.0), base.a)
