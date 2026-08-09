class_name LookingForTrouble extends BallActive


func activate(ball: Ball) -> bool:
	return ball.redirect_to_nearest_seal()
