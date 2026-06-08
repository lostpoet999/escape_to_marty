class_name BossDeon
extends Deon

var stage: int = 1
@export var core_health: float = 15.0
var dying: bool = false
var darkcage_spawnpoints: Array[Marker2D]
var health_label: Label
@onready var cage_spawn_points: Node2D = $"../Cage_Spawn_Points"
const DARK_CAGE: PackedScene = preload("uid://cm2bdw1o1sypc")


func _ready() -> void:
	super()
	Signalbus.deon_boss_cage_cleared.connect(_on_cage_cleared)
	Signalbus.deon_boss_spawn_cage.connect(_on_spawn_cage)
	fill_spawn_points()
	_setup_health_label()

func _setup_health_label() -> void:
	health_label = Label.new()
	health_label.scale = Vector2.ONE / scale
	health_label.position = Vector2(-20, -50)
	health_label.z_index = 2000
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_label.add_theme_color_override("font_outline_color", Color.BLACK)
	health_label.add_theme_constant_override("outline_size", 8)
	add_child(health_label)
	_update_health_label()

func _update_health_label() -> void:
	if health_label == null: return
	match stage:
		1: health_label.text = "CAGED"
		2: health_label.text = "Shell: " + str(denial_health)
		3: health_label.text = "HP: " + str(snappedf(core_health, 0.1))

func _on_spawn_cage(world_pos: Vector2)->void:
	var cage: DarkCage = DARK_CAGE.instantiate()	
	get_parent().add_child(cage)
	cage.global_position = world_pos

func fill_spawn_points()->void:
	for spawnpoint: Node2D in cage_spawn_points.get_children():
		darkcage_spawnpoints.append(spawnpoint)

func accept_damage(damage: float, _dmg_type: Array[GameManager.PhaseType])->void:
	match stage:
		1: return
		2:
			if _dmg_type.has(GameManager.PhaseType.DENIAL) and denial_health > 0:
				SFX.play_sound("enemy_hurt")
				show_damage_number(1)
				take_damage_fx()
				denial_health -= 1
				if denial_health == 0:
					self.modulate = Color.WHITE
					self.modulate.a = 1.0
					stage += 1
				_update_health_label()
		3:
			if _dmg_type.has(GameManager.PhaseType.HEALTH) and not dying:
				SFX.play_sound("enemy_hurt")
				core_health -= damage
				show_damage_number(int(round(damage)))
				take_damage_fx()
				_update_health_label()
				if core_health <= 0:
					dying = true
					die()
					Signalbus.level_cleared.emit()

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
	_update_health_label()
