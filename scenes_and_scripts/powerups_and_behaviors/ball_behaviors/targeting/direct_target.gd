class_name DirectTarget extends TargetingStrategy

func select(_ball: Ball, collider: Node2D, _hit_point: Vector2) -> Array[Node2D]:
	var result: Array[Node2D] = [collider]
	return result
