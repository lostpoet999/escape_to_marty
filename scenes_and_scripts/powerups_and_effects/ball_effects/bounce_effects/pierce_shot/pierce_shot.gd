extends BaseBounceEffect

func should_bounce(collider: Node2D) -> bool:
	if collider.is_in_group("bricks"):
		return false
	return true
