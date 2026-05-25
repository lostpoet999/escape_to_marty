class_name BossDeon
extends Deon

var stage: int = 1
var darkcage_spawnpoints: Array[Marker2D]
@onready var cage_spawn_points: Node2D = $"../Cage_Spawn_Points"
const DARK_CAGE: PackedScene = preload("uid://cm2bdw1o1sypc")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	Signalbus.deon_boss_cage_cleared.connect(_on_cage_cleared)
	Signalbus.deon_boss_spawn_cage.connect(_on_spawn_cage)
	fill_spawn_points()	

func _on_spawn_cage(world_pos: Vector2)->void:
	var cage: DarkCage = DARK_CAGE.instantiate()	
	get_parent().add_child(cage)
	cage.global_position = world_pos

func fill_spawn_points()->void:
	for spawnpoint: Node2D in cage_spawn_points.get_children():
		darkcage_spawnpoints.append(spawnpoint)

func accept_damage(_damage: int, _dmg_type: Array[GameManager.PhaseType])->void:	
	match stage:
		1: return
		2:
			if _dmg_type.has(GameManager.PhaseType.DENIAL) and denial_health > 0:
				SFX.play_sound("player_hurt")
				take_damage_fx()
				denial_health -= 1
				if denial_health == 0:
					self.modulate = Color.WHITE
					self.modulate.a = 1.0
					stage += 1
		3:
			if _dmg_type.has(GameManager.PhaseType.HEALTH):
				die()
				Signalbus.floor_cleared.emit()

func pick_action()->void:	
	if !action_pool.is_empty():
		var action:EnemyActions = action_pool.pick_random()
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
