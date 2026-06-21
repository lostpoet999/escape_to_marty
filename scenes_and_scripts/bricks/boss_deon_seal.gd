class_name  BossDeonSeal
extends BaseSeal
const DEON_BOSS_WALL: PackedScene = preload("uid://nx78k65twjxc")
const BOSS_SEAL_SCORE: int = 250
@onready var boss_deon_cage: Node = $".."

func _damage_current_stage(damage: float) -> void:
	if health_temp - damage <= 0: #override base behavior to turn denial brick into a 'deon wall'
		dying = true
		PlayerData.update_player_score(BOSS_SEAL_SCORE)
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
		brick_health_label.text = str(health_temp)
	_spawn_damage_number(damage)
