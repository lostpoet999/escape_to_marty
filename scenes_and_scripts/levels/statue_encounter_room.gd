class_name StatueEncounterRoom extends EncounterRoomBase

const DESPAWN_STAGGER_S: float = 0.12

var _statues: Array[DepressionStatue] = []
var _win_started: bool = false
var _progress_max: float = 0.0

func _ready() -> void:
	_collect_statues()
	await super()
	if encounter_cleared:
		for statue: DepressionStatue in _statues:
			if is_instance_valid(statue):
				statue.force_charged(false)
		return
	var portal: FloorPortal = find_child("FloorPortal", true, false) as FloorPortal
	if portal != null:
		portal.show_dormant(false)
	Signalbus.encounter_progress.emit.call_deferred(1, 1, _remaining_charge(), _progress_max)

func _collect_statues() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"depression_statue"):
		var statue: DepressionStatue = node as DepressionStatue
		if statue == null:
			continue
		_statues.append(statue)
		_progress_max += statue.charge_seconds
		statue.charge_changed.connect(_on_statue_charge_changed)

func _on_statue_charge_changed() -> void:
	_emit_progress()
	_check_win()

func _emit_progress() -> void:
	if encounter_cleared or _win_started or _progress_max <= 0.0:
		return
	Signalbus.encounter_progress.emit(1, 1, _remaining_charge(), _progress_max)

func _remaining_charge() -> float:
	var remaining: float = 0.0
	for statue: DepressionStatue in _statues:
		if is_instance_valid(statue):
			remaining += maxf(statue.charge_seconds - statue.charge, 0.0)
	return remaining

func _check_win() -> void:
	if _win_started or encounter_cleared or _statues.is_empty():
		return
	for statue: DepressionStatue in _statues:
		if not is_instance_valid(statue) or not statue.is_charged():
			return
	_win_started = true
	_run_win_sequence()

func _run_win_sequence() -> void:
	var imps: Array[PlacedEnemy] = []
	var spawner: StatueImpSpawner = _imp_spawner()
	if spawner != null:
		spawner.stop_spawning()
		imps = spawner.active_enemies.duplicate()
	var tween: Tween = create_tween()
	for imp: PlacedEnemy in imps:
		tween.tween_callback(_kill_imp.bind(imp))
		tween.tween_interval(DESPAWN_STAGGER_S)
	tween.tween_callback(clear_encounter)

func _kill_imp(imp_variant: Variant) -> void:
	if not is_instance_valid(imp_variant):
		return
	var node: Node = imp_variant
	var imp: PlacedEnemy = node as PlacedEnemy
	if imp != null and not imp.is_queued_for_deletion():
		imp.die()

func _imp_spawner() -> StatueImpSpawner:
	return find_child("ImpSpawner", true, false) as StatueImpSpawner
