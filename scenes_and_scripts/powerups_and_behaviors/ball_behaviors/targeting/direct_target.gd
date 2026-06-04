class_name DirectTarget extends TargetingStrategy

func select(_ctx: HitContext, collider: Node2D) -> Array[Node2D]:
	var result: Array[Node2D] = [collider]
	return result
