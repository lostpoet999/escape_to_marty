class_name  BossDeonSeal
extends BaseSeal
const DEON_BOSS_WALL: PackedScene = preload("uid://nx78k65twjxc")
@onready var boss_deon_cage: Node = $".."

func _damage_current_stage(damage: float, score_mult: float = 1.0, via_click: bool = false) -> void:
	_score_stage_damage(damage, score_mult)
	if health_temp - damage <= 0: #override base behavior to turn denial brick into a 'deon wall'
		dying = true
		_grant_phase_score(score_mult, via_click)
		var deon_wall: Node2D = DEON_BOSS_WALL.instantiate()
		var fx: Node2D = brick_damage_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		deon_wall.position = global_position
		boss_deon_cage.add_child(deon_wall)
		Signalbus.deon_boss_seal_cleared.emit(self)
		queue_free()
	else:
		var fx: Node2D = brick_damage_fx.instantiate()
		if fx != null:
			fx.position = global_position
			get_tree().current_scene.add_child(fx)
		health_temp -= damage
		_update_damage_cracks()
		_update_stage_label()
	_spawn_damage_number(damage)
