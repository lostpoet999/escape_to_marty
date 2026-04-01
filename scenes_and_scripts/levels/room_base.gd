extends Node2D

var stars_cleared: bool = false
var bricks_cleared: bool = false
var stars_in_level: int = 0
var bricks_in_level: int = 0
@onready var game_state_lbl: Label = $GameState_Lbl
@onready var current_room_lbl: Label = $CurrentRoom_Lbl


func _process(_delta: float) -> void:
	game_state_lbl.text = "Game State: " + GameManager.GameState.keys()[GameManager.current_state]

	

func _ready() -> void:
	bricks_in_level = get_tree().get_nodes_in_group("bricks").size()
	current_room_lbl.text = "Current Room: " + GameManager.current_room_id
	Signalbus.stars_updated.emit()
	Signalbus.score_updated.emit()
	Signalbus.player_health_updated.emit()
	Signalbus.brick_destroyed.connect(_on_brick_destroyed)
	Signalbus.star_collected.connect(update_stars_in_level)
	Signalbus.star_spawned.connect(update_stars_in_level)
	Signalbus.enemy_requested.connect(_on_enemy_requested)

	if self.name == "common_room":
		bricks_cleared = true
		stars_cleared = true		
		check_level_cleared()

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
	if stars_cleared && bricks_cleared:
		Signalbus.level_cleared.emit()

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
