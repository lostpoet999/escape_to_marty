extends Node2D

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
@onready var shop_grid: ShopGrid
@onready var no_respawn: Node2D = $"No-Respawn"



func _process(_delta: float) -> void:
	game_state_lbl.text = "Game State: " + GameManager.GameState.keys()[GameManager.current_state]

	
func supress_respawn_entities()->void:
	no_respawn.queue_free()	

func _ready() -> void:
	visible = false
	entry = GameManager.get_current_floor_entry(GameManager.current_room_id)
	room_state = PlayerData.get_room_state(entry)
	if room_state.cleared:
		supress_respawn_entities()
		Signalbus.level_cleared.emit()
	await get_tree().process_frame	
	visible = true
	bricks_in_level = get_tree().get_nodes_in_group("bricks").size()	
	current_room_lbl.text = "Current Room: " + GameManager.current_room_id
	Signalbus.stars_updated.emit()
	Signalbus.score_updated.emit()
	Signalbus.player_health_updated.emit()
	Signalbus.brick_destroyed.connect(_on_brick_destroyed)
	Signalbus.star_collected.connect(update_stars_in_level)
	Signalbus.star_spawned.connect(update_stars_in_level)
	Signalbus.enemy_requested.connect(_on_enemy_requested)
	initiate_special_room()

func initiate_special_room()->void:
	if self.name =="common_room":
		bricks_cleared = true
		stars_cleared = true
		check_level_cleared() # temp mechanism until i swithc to checking room types purely
	match entry.room_type:		
		RoomEntry.ROOM_TYPES.free_item:
			if !room_state.loot_items_data:
				room_state.generate_item_box()
			if !room_state.loot_items_data.items.is_empty():
				loot_items_data = room_state.loot_items_data
				item_box = loot_items_data.instantiate_lootbox()
				item_box.global_position = item_spawn_point.global_position
				item_box.loot_items_data = loot_items_data
				add_child(item_box)
			bricks_cleared = true
			stars_cleared = true			
			check_level_cleared()
		RoomEntry.ROOM_TYPES.shop:
			if !room_state.loot_items_data:
				room_state.generate_item_box()
			if !room_state.loot_items_data.items.is_empty():
				loot_items_data = room_state.loot_items_data
				shop_grid = loot_items_data.instantiate_shop()
				shop_grid.global_position = item_spawn_point.global_position
				shop_grid.loot_items_data = loot_items_data
				add_child(shop_grid)
				shop_grid.global_position = item_spawn_point.global_position

func _on_enemy_requested(spawn_from: Area2D) -> void: # for brick break enemies
	var seal_break_enemies: Array[EnemyConfig] = GameManager.floor_data.seal_break_enemies
	var enemy: FallingEnemy = instantiate_random_enemy(seal_break_enemies)
	if enemy:
		spawn_from.get_parent().add_child(enemy)
		enemy.position = spawn_from.position

func instantiate_random_enemy(enemy_configs: Array[EnemyConfig]) -> Node2D: #for brick break enemies
	var index: int = 0
	var spawned_percentage: float = randf() * 100
	while (index < enemy_configs.size()):
		var spawn_configuration: EnemyConfig = enemy_configs[index]
		if (spawned_percentage < spawn_configuration.spawn_chance):
			return spawn_configuration.scene_ref.instantiate()
		else:
			spawned_percentage -= spawn_configuration.spawn_chance
			index += 1
	return null

func check_level_cleared() -> void: #let gamemanager know level is cleared
	var max_clear:int = GameManager.get_current_floor_entry(GameManager.current_room_id).max_clears
	if stars_cleared && bricks_cleared:
		Signalbus.level_cleared.emit()		
		room_state.clear_count +=1
		if entry.max_clears == -1: return
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
