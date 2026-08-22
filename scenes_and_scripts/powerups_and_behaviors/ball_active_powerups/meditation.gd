class_name Meditation extends BallActive

@export var freeze_seconds: float = 5.0
@export var blink_seconds: float = 1.0


func activate(ball: Ball) -> bool:
	return ball.begin_meditation(freeze_seconds, blink_seconds)
