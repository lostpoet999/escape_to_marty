class_name EnemySpawner
extends Node2D

@export var enemies: Array[EnemyConfig]
@export var spawn_an_enemy_chance: float
@export var respawn_time: float
@export var initial_spawn_time: float
@export var suppressed_on_respawn: bool
var active_enemies: Array[PlacedEnemy]
@export var max_spawns: int
var enemy_spawn_timer: Timer

func _ready()->void:	
	if enemy_spawn_timer == null:
		enemy_spawn_timer = Timer.new()
		self.add_child(enemy_spawn_timer)
		enemy_spawn_timer.timeout.connect(timer_spawn_enemy)
		
	# Shorten wait time for the first enemy for quicker debugging
	enemy_spawn_timer.wait_time = initial_spawn_time
	enemy_spawn_timer.start()

func timer_spawn_enemy() -> void:	
	if randf_range(1,100) >= spawn_an_enemy_chance or active_enemies.size()>=max_spawns:
		enemy_spawn_timer.wait_time = respawn_time
		return #dont spawn an enemy
	var enemy_config = get_random_config()
	if enemy_config:
		var enemy = instantiate_random_enemy(enemy_config)
		enemy.position.x = enemy_config.x_offset
		enemy.position.y = enemy_config.y_offset
		add_child(enemy)
		active_enemies.push_back(enemy)
		enemy.ready_to_remove.connect(_on_tracked_enemy_died)		
	# Space out time between enemies
	enemy_spawn_timer.wait_time = respawn_time

func _on_tracked_enemy_died(enemy: PlacedEnemy)->void:
	active_enemies.erase(enemy)

func get_random_config() -> EnemyConfig:
	var total_weight: float = 0.0
	for config: EnemyConfig in enemies:
		total_weight += config.spawn_chance
	
	var roll : float = randf() * total_weight
	var cumulative : float = 0.0
	for config:EnemyConfig in enemies:
		cumulative += config.spawn_chance
		if roll < cumulative:
			return config
	
	return enemies.back()

	
func instantiate_random_enemy(enemy_config: EnemyConfig) -> Node2D:
	return enemy_config.scene_ref.instantiate()
