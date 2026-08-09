class_name BallActive extends BaseItem

@export_category("Activation:")
## Seconds before the ability can be used again. The cooldown starts only when an activation succeeds.
@export var cool_down_seconds: float = 5.0


func activate(_ball: Ball) -> bool:
	return false
