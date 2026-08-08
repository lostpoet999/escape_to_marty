class_name SpiderPoolSpawner
extends EnemySpawner

func timer_spawn_enemy() -> void:
	enemy_spawn_timer.wait_time = respawn_time
	var room: SpiderEncounterRoom = get_tree().current_scene as SpiderEncounterRoom
	if room == null or room.encounter_cleared:
		return
	if room.has_coins_to_allocate():
		super()
