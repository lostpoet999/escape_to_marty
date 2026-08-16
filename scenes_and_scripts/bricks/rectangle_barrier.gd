class_name RectangleBarrier extends Area2D

const CLEAR_FX: PackedScene = preload("res://scenes_and_scripts/ball/vfx/bounce_barrier_particles.tscn")

## Percent chance this barrier exists at all, rolled on the room's first visit and remembered for the rest of the run so re-entry keeps the same layout. Set under 100 for randomized layouts. Credit to Christer for this idea!
@export var chance_it_exists: int = 100

func _ready() -> void:
	if chance_it_exists >= 100:
		return
	if !GameManager.room_data_for_floor.has(GameManager.current_room_id):
		return
	var entry: RoomEntry = GameManager.get_current_floor_entry(GameManager.current_room_id)
	var state: RoomState = PlayerData.get_room_state(entry)
	if !state.should_exist(str(get_path()), chance_it_exists):
		queue_free()

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
