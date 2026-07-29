class_name RectangleBarrier extends Area2D

const CLEAR_FX: PackedScene = preload("res://scenes_and_scripts/ball/vfx/bounce_barrier_particles.tscn")

func responding_gestures() -> Array[GameManager.PhaseType]:
	var verbs: Array[GameManager.PhaseType] = []
	if PlayerData.barrier_clear_ready():
		verbs.append(GameManager.PhaseType.DENIAL)
	return verbs

func accept_damage(_damage: float, _damage_types: Array) -> void:
	if not PlayerData.barrier_clear_ready():
		return
	PlayerData.consume_barrier_clear()
	_spawn_clear_fx()
	SFX.play_sound("bounce_barrier")
	queue_free()

func _spawn_clear_fx() -> void:
	var fx: Node2D = CLEAR_FX.instantiate()
	fx.global_position = global_position
	get_tree().current_scene.add_child(fx)
