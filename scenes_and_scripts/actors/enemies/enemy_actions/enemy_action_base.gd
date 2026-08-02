class_name EnemyActions
extends Resource

enum ActionTypes{
	Move = 0,
	Damage = 1,
	Stun = 2,
	}

@export var action_name: String
@export var action_type: ActionTypes
@export var clamp_paddle: bool

func execute_action(_actor: PlacedEnemy) -> void:
	pass

func cancel_to_origin(_actor: PlacedEnemy) -> void:
	pass
