class_name BossDeon
extends Deon

var stage: int = 1
@export var core_health: float = 15.0
var dying: bool = false
var _denial_max: int = 0
var _core_max: float = 0.0
var darkcage_spawnpoints: Array[Marker2D]
@onready var cage_spawn_points: Node2D = $"../Cage_Spawn_Points"
const DARK_CAGE: PackedScene = preload("uid://cm2bdw1o1sypc")


func _ready() -> void:
	super()
	#stops die vfx/sfx on room persistance/revisit
	if Signalbus.level_cleared.is_connected(die):
		Signalbus.level_cleared.disconnect(die)
	Signalbus.deon_boss_cage_cleared.connect(_on_cage_cleared)
	Signalbus.deon_boss_spawn_cage.connect(_on_spawn_cage)
	fill_spawn_points()
	_denial_max = denial_health
	_core_max = core_health

func _emit_progress() -> void:
	match stage:
		2: Signalbus.encounter_progress.emit(2, 3, float(denial_health), float(_denial_max))
		3: Signalbus.encounter_progress.emit(3, 3, maxf(core_health, 0.0), _core_max)

func _on_spawn_cage(world_pos: Vector2)->void:
	var cage: DarkCage = DARK_CAGE.instantiate()	
	get_parent().add_child(cage)
	cage.global_position = world_pos

func fill_spawn_points()->void:
	for spawnpoint: Node2D in cage_spawn_points.get_children():
		darkcage_spawnpoints.append(spawnpoint)

func accept_damage(damage: float, _dmg_type: Array[GameManager.PhaseType], score_mult: float = 1.0)->void:
	match stage:
		1: return
		2:
			if _dmg_type.has(GameManager.PhaseType.DENIAL) and denial_health > 0:
				SFX.play_sound("enemy_hurt")
				show_damage_number(1)
				take_damage_fx()
				PlayerData.update_player_score(1.0, score_mult)
				denial_health -= 1
				if denial_health == 0:
					self.modulate = Color.WHITE
					self.modulate.a = 1.0
					stage += 1
				_emit_progress()
		3:
			if _dmg_type.has(GameManager.PhaseType.HEALTH) and not dying:
				SFX.play_sound("enemy_hurt")
				PlayerData.update_player_score(minf(damage, maxf(core_health, 0.0)), score_mult)
				core_health -= damage
				show_damage_number(damage)
				take_damage_fx()
				_emit_progress()
				if core_health <= 0:
					dying = true
					die()
					Signalbus.boss_defeated.emit()

func responding_gestures() -> Array[GameManager.PhaseType]:
	var verbs: Array[GameManager.PhaseType] = []
	if stage == 2 and not dying:
		verbs.append(GameManager.PhaseType.DENIAL)
	return verbs

func pick_action()->void:
	if !action_pool.is_empty():
		var action:EnemyActions = action_pool.pick_random()
		current_action = action
		action.setup_darkcage_spawns(darkcage_spawnpoints)
		action.execute_action(self)
		if is_blocker:
			if action.action_type == action.ActionTypes.Move: Signalbus.blocker_moved.emit()
		timer.wait_time = action_timer - randf_range(0.3,0.8)

func _on_cage_cleared()->void:
	left_clamp_offset = 0 # from placed_enemy
	right_clamp_offset = 0
	Signalbus.blocker_moved.emit()
	stage += 1
	_emit_progress()
