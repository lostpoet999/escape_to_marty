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

## FIXME: this is totally not where to reference the enemy scenes, or in fact any of the configuration data. I need to reference the floor_data instead.
const DARK_CAGE: PackedScene = preload("uid://cm2bdw1o1sypc")

func _on_enemy_requested(spawn_from: Area2D) -> void:
	var enemy_spawn_rate = 50
	if (randf() * 100 < enemy_spawn_rate):
		_spawn_enemy(spawn_from)

func _spawn_enemy(spawn_from: Area2D) -> void:
	var enemy = DARK_CAGE.instantiate()
	spawn_from.get_parent().add_child(enemy)
	enemy.position = spawn_from.position
