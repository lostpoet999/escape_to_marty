class_name LookingForTrouble extends BallActive

## Speed multiplier for the seek. The ball drops back to its pre-seek speed on its first collision.
@export var seek_speed_multiplier: float = 2.0


func activate(ball: Ball) -> bool:
	return ball.redirect_to_nearest_seal(seek_speed_multiplier)
