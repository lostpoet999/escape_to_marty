class_name TargetingStrategy extends Resource

# base: who a hit affects. override select(); default no-op.
func select(_ball: Ball, _collider: Node2D, _hit_point: Vector2) -> Array[Node2D]:
	return []
