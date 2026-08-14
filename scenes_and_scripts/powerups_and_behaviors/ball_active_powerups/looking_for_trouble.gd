class_name LookingForTrouble extends BallActive

const ACTIVATION_SOUND: String = "homing_activation"

## Speed multiplier for the seek. The ball drops back to its pre-seek speed on its first collision.
@export var seek_speed_multiplier: float = 2.0


func activate(ball: Ball) -> bool:
	if not ball.redirect_to_nearest_seal(seek_speed_multiplier):
		return false
	SFX.play_sound(ACTIVATION_SOUND)
	return true
