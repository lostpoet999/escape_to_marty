class_name BaseDamageEffect extends Node2D

var ball_ref: Ball
var collider_ref: Node2D
var target: Node2D

func process_targets() -> void:
	target = collider_ref #just the thing hit
	apply_damage(target)

func process_damage(ball: Ball, collider: Node2D) -> void: # entry point--should not be overriden
	ball_ref = ball
	collider_ref = collider
	process_targets()

func apply_damage(damage_target: Node2D) -> void:
	if damage_target.is_in_group("bricks"):
		damage_target.call("accept_damage", ball_ref.ball_dmg)
	elif damage_target.is_in_group("DeathWalls"):
		ball_ref.position_ball_on_paddle()
		PlayerData.accept_damage(int(ball_ref.ball_dmg))
