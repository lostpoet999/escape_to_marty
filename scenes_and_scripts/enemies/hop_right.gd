class_name HopRight
extends EnemyActions

@export var right_distance: float
@export var up_distance: float
@export var speed: float
@export var max_hops: int
@export var back_chance: float
var hops: int = 0

func reset()->void:
	hops = 0	
	
func execute_action(actor: Variant)->void:	
	if hops < max_hops:
		if hops > 2:
			if randf_range(1, 100) < back_chance:
				actor.position.x -= right_distance
				return
		actor.position.x += right_distance
		hops +=1
