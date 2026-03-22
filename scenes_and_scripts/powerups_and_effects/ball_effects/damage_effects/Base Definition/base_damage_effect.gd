class_name BaseDamageEffect extends Node2D

var ball_ref: Ball
var collider_ref: Node2D
var target: Node2D

func process_targets(damage_types: Array[GameManager.PhaseType]) -> void:
	target = collider_ref #just the thing hit
	apply_damage(target,damage_types)

func process_damage(ball: Ball, collider: Node2D, damage_types: Array[GameManager.PhaseType]) -> void: # entry point--should not be overriden
	ball_ref = ball
	collider_ref = collider
	process_targets(damage_types)

func apply_damage(damage_target: Node2D, damage_types: Array[GameManager.PhaseType]) -> void: #note i am passing damage types a few times because i want to deal with brick and enemy reactions on those scenes
	if damage_target.is_in_group("bricks"):
		damage_target.call("accept_damage", ball_ref.ball_dmg, damage_types) #TODO: biforcate click damage from ball bounce damage
	elif damage_target.is_in_group("DeathWalls"):
		ball_ref.position_ball_on_paddle()
		PlayerData.accept_damage(int(ball_ref.ball_dmg))
