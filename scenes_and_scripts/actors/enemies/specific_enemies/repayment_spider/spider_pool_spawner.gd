class_name SpiderPoolSpawner
extends EnemySpawner

var _reward_wave_spawned: bool = false

func timer_spawn_enemy() -> void:
	enemy_spawn_timer.wait_time = respawn_time
	var room: SpiderEncounterRoom = get_tree().current_scene as SpiderEncounterRoom
	if room == null or room.encounter_cleared:
		return
	if room.has_coins_to_allocate():
		super()
		return
	if room.zero_stolen and not _reward_wave_spawned:
		var before: int = active_enemies.size()
		super()
		_reward_wave_spawned = active_enemies.size() > before
