class_name LogicTarget extends TargetingStrategy

@export var filter_phase: GameManager.PhaseType

func select(ball: Ball, _collider: Node2D, _hit_point: Vector2) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node: Node in ball.get_tree().get_nodes_in_group("bricks"):
		var seal: BaseSeal = node as BaseSeal
		if seal != null and seal.current_stage == filter_phase:
			result.append(seal)
	return result
