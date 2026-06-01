class_name DeonBossHop
extends HopToCenter

var darkcage_spawns: Array

func setup_darkcage_spawns(spawn_points: Array)->void:
	darkcage_spawns = spawn_points

func spawn_cage() -> void:
	var spawn_count := randi_range(1, 4)
	var available := darkcage_spawns.duplicate()
	available.shuffle()
	for i in spawn_count:
		var marker: Marker2D = available[i]
		Signalbus.deon_boss_spawn_cage.emit(marker.global_position)

func _after_takeoff(_actor: PlacedEnemy) -> void:
	spawn_cage()
