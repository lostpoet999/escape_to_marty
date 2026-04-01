class_name HopToCenter
extends EnemyActions

const CENTER:float = 1088.00
const LEFT:float = 384.00
const LEFT_CENTER:float  = 960.00
const RIGHT_CENTER: float = 1216.00
const RIGHT: float = 1782.00


@export var hop_distance: float
@export var up_distance: float
@export var speed: float
@export var max_hops: int
@export var back_chance: float
var hops: int = 0

func reset()->void:
	hops = 0
	
func execute_action(actor: PlacedEnemy)->void:
	if actor.global_position.x <= LEFT_CENTER:
		if randf_range(1,100) <= back_chance and actor.global_position.x > 384:
			actor.global_position.x -= hop_distance
		elif actor.global_position.x != LEFT_CENTER:
			actor.global_position.x += hop_distance
	elif actor.global_position.x >= RIGHT_CENTER:
		if randf_range(1,100) <= back_chance and actor.global_position.x < 1782:
			actor.global_position.x += hop_distance
		elif actor.global_position.x != RIGHT_CENTER:
			actor.global_position.x -= hop_distance
