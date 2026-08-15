class_name EnemySpawner
extends Node2D

@export var enemies: Array[EnemyConfig]
@export var spawn_an_enemy_chance: float
## Seconds between spawn checks. Every tick the spawner rolls spawn_an_enemy_chance and tests max_spawns; it is the polling cadence, not a delay tied to any one enemy.
@export var spawn_check_interval: float
## Seconds before the very first spawn check. Applies once, at _ready.
@export var first_spawn_delay: float
## Shortest gap, in seconds, before a killed enemy may be replaced. Zero or negative disables the whole post-kill delay and leaves the polling cadence alone.
@export var respawn_delay_after_kill_min: float = -1.0
## Longest gap, in seconds, before a killed enemy may be replaced; each kill rolls uniformly between the two. Leave at or below the min for a fixed delay.
@export var respawn_delay_after_kill_max: float = -1.0
var active_enemies: Array[PlacedEnemy]
@export var max_spawns: int
## Seconds after spawn within which killing a Deon counts as a quick kill.
@export var quick_kill_window_s: float = 5.0
## Seconds this spawner stays quiet (win sting reward) after a quick Deon kill.
@export var quick_kill_lockout_s: float = 30.0
const LOCKOUT_INDICATOR_COLOR: Color = Color(1, 1, 1, 0.25)
const LOCKOUT_INDICATOR_SIZE: Vector2 = Vector2(64, 128)

var enemy_spawn_timer: Timer
var _lockout_until_ms: int = -1
var _first_launch_seen: bool = false
var _lockout_indicator: ColorRect

func _ready()->void:	
	if enemy_spawn_timer == null:
		enemy_spawn_timer = Timer.new()
		self.add_child(enemy_spawn_timer)
		enemy_spawn_timer.timeout.connect(timer_spawn_enemy)
		
	# Shorten wait time for the first enemy for quicker debugging
	enemy_spawn_timer.wait_time = first_spawn_delay
	enemy_spawn_timer.start()

func timer_spawn_enemy() -> void:
	if GameManager.current_state == GameManager.GameState.LEVEL_CLEARED:
		return
	if _spawns_blocked():
		enemy_spawn_timer.wait_time = 1.0
		return
	_clear_lockout_indicator()
	var mult: float = SettingsManager.difficulty_mult()
	if randf_range(0,100) >= spawn_an_enemy_chance * mult or active_enemies.size() >= roundi(max_spawns * mult):
		enemy_spawn_timer.wait_time = spawn_check_interval
		return
	var enemy_config:EnemyConfig = get_random_config()
	if enemy_config:
		var enemy: PlacedEnemy = instantiate_random_enemy(enemy_config)
		enemy.position.x = enemy_config.x_offset
		enemy.position.y = enemy_config.y_offset
		add_child(enemy)
		enemy.set_meta(&"spawned_at_ms", Time.get_ticks_msec())
		active_enemies.push_back(enemy)
		enemy.ready_to_remove.connect(_on_tracked_enemy_died)
	# Space out time between enemies
	enemy_spawn_timer.wait_time = spawn_check_interval

func _on_tracked_enemy_died(enemy: PlacedEnemy)->void:
	active_enemies.erase(enemy)
	_check_quick_kill(enemy)
	_delay_next_spawn_after_kill()

func _delay_next_spawn_after_kill() -> void:
	if respawn_delay_after_kill_min <= 0.0:
		return
	if enemy_spawn_timer == null or enemy_spawn_timer.is_stopped():
		return
	var high: float = maxf(respawn_delay_after_kill_max, respawn_delay_after_kill_min)
	enemy_spawn_timer.wait_time = randf_range(respawn_delay_after_kill_min, high)
	enemy_spawn_timer.start()

func _in_encounter_room() -> bool:
	return get_tree().current_scene is EncounterRoomBase

func _check_quick_kill(enemy: PlacedEnemy) -> void:
	if not (enemy is Deon):
		return
	if _in_encounter_room():
		return
	if GameManager.current_state == GameManager.GameState.LEVEL_CLEARED:
		return
	if not enemy.has_meta(&"spawned_at_ms"):
		return
	var alive_ms: int = Time.get_ticks_msec() - int(enemy.get_meta(&"spawned_at_ms"))
	if alive_ms > int(quick_kill_window_s * 1000.0):
		return
	SFX.play_sound("win_sting")
	_lockout_until_ms = Time.get_ticks_msec() + int(quick_kill_lockout_s * 1000.0)
	_show_lockout_indicator()

func _show_lockout_indicator() -> void:
	_clear_lockout_indicator()
	var indicator: ColorRect = ColorRect.new()
	indicator.color = LOCKOUT_INDICATOR_COLOR
	indicator.size = LOCKOUT_INDICATOR_SIZE
	indicator.position = -LOCKOUT_INDICATOR_SIZE * 0.5
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(indicator)
	_lockout_indicator = indicator
	get_tree().create_timer(quick_kill_lockout_s, true, false, true).timeout.connect(_clear_lockout_indicator)

func _clear_lockout_indicator() -> void:
	if _lockout_indicator != null and is_instance_valid(_lockout_indicator):
		_lockout_indicator.queue_free()
	_lockout_indicator = null

func _spawns_blocked() -> bool:
	if _in_encounter_room():
		return false
	if Time.get_ticks_msec() < _lockout_until_ms:
		return true
	if _first_launch_seen:
		return false
	var ball: Node = get_tree().get_first_node_in_group("ball")
	if ball == null or not bool(ball.get("on_paddle")):
		_first_launch_seen = true
		return false
	return true

func get_random_config() -> EnemyConfig:
	var eligible: Array[EnemyConfig] = enemies.filter(_config_can_spawn)
	if eligible.is_empty():
		return null
	var total_weight: float = 0.0
	for config: EnemyConfig in eligible:
		total_weight += config.spawn_chance

	var roll : float = randf() * total_weight
	var cumulative : float = 0.0
	for config:EnemyConfig in eligible:
		cumulative += config.spawn_chance
		if roll < cumulative:
			return config

	return eligible.back()

func _config_can_spawn(config: EnemyConfig) -> bool:
	if not config.requires_live_seals:
		return true
	return not get_tree().get_nodes_in_group("bricks").is_empty()

	
func instantiate_random_enemy(enemy_config: EnemyConfig) -> Node2D:
	return enemy_config.scene_ref.instantiate()
