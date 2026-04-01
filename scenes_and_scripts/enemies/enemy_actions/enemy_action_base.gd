class_name EnemyActions
extends Resource

enum ActionTypes{Move, Damage, Stun}

@export var action_name: String
@export var action_type: ActionTypes
@export var clamp_paddle: bool

func execute_action(_actor: PlacedEnemy) -> void:
	pass
