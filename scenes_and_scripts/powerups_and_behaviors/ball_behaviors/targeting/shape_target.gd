class_name ShapeTarget extends TargetingStrategy

@export var probe_shape: Shape2D

func select(ball: Ball, _collider: Node2D, hit_point: Vector2) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if probe_shape == null:
		return result
	var space: PhysicsDirectSpaceState2D = ball.get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = probe_shape
	query.transform = Transform2D(0, hit_point)
	query.collision_mask = ball.collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [ball.get_rid()]
	for hit: Dictionary in space.intersect_shape(query, 64):
		var node: Node2D = hit.get("collider") as Node2D
		if node != null and (node.is_in_group("bricks") or node.is_in_group("bounce_enemy")):
			result.append(node)
	return result
