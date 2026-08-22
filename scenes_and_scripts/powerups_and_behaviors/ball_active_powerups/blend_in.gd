class_name BlendIn extends BallActive

@export var phase_seconds: float = 3.5
@export var min_hits: int = 1
@export var max_hits: int = 3
@export var rehit_seconds: float = 0.06


func activate(ball: Ball) -> bool:
	return ball.begin_blend_in(phase_seconds, min_hits, max_hits, rehit_seconds)
