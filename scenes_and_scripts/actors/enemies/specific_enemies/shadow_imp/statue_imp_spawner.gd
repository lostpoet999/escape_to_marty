class_name StatueImpSpawner
extends EnemySpawner

## Live imps the encounter maintains at Normal; one spawns per spawn_check_interval tick until the room holds this many. Scaled by the difficulty setting, so Easy fights fewer and Hard fights more.
@export var live_imp_target: int = 4

var _spawning_stopped: bool = false

func timer_spawn_enemy() -> void:
	enemy_spawn_timer.wait_time = spawn_check_interval
	if _spawning_stopped:
		return
	var room: StatueEncounterRoom = get_tree().current_scene as StatueEncounterRoom
	if room == null or room.encounter_cleared:
		return
	if active_enemies.size() >= target_imp_count():
		return
	super()

func target_imp_count() -> int:
	return maxi(1, roundi(float(live_imp_target) * SettingsManager.difficulty_mult()))

func stop_spawning() -> void:
	_spawning_stopped = true
	if enemy_spawn_timer != null:
		enemy_spawn_timer.stop()
