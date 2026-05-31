class_name PhaseTarget extends TargetingStrategy

# selects seals by their current grief-phase, independent of where the ball physically hit.
# ALL     = every matching seal on the floor
# NEAREST = the closest `count` matches to the hit point
# RADIUS  = matches within `radius` of the hit point

enum Mode { ALL, NEAREST, RADIUS }

@export var filter_phases: Array[GameManager.PhaseType]
@export var mode: Mode = Mode.ALL
@export var count: int = 1        # nearest-N; only used when mode == NEAREST
@export var radius: float = 80.0  # only used when mode == RADIUS

func select(ball: Ball, _collider: Node2D, hit_point: Vector2) -> Array[Node2D]:
	var matches: Array[Node2D] = []
	for node: Node in ball.get_tree().get_nodes_in_group("bricks"):
		var seal: BaseSeal = node as BaseSeal
		if seal != null and seal.current_stage in filter_phases:
			matches.append(seal)
	match mode:
		Mode.NEAREST:
			if matches.size() <= count:
				return matches
			matches.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				return a.global_position.distance_squared_to(hit_point) < b.global_position.distance_squared_to(hit_point))
			return matches.slice(0, count)
		Mode.RADIUS:
			var r_sq: float = radius * radius
			return matches.filter(func(n: Node2D) -> bool:
				return n.global_position.distance_squared_to(hit_point) <= r_sq)
		_:
			return matches
