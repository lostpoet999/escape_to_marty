class_name ShapeTarget extends TargetingStrategy

@export var probe_shape: Shape2D
@export var filter_phases: Array[GameManager.PhaseType]

func select(ctx: HitContext, _collider: Node2D) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if probe_shape == null:
		return result
	var space: PhysicsDirectSpaceState2D = ctx.source.get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = probe_shape
	query.transform = Transform2D(0, ctx.hit_point)
	query.collision_mask = ctx.collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = ctx.exclude
	for hit: Dictionary in space.intersect_shape(query, 64):
		var node: Node2D = hit.get("collider") as Node2D
		if node == null:
			continue
		if not (node.is_in_group("bricks") or node.is_in_group("bounce_enemy")):
			continue
		if not filter_phases.is_empty():
			var seal: BaseSeal = node as BaseSeal
			if seal == null or not seal.current_stage in filter_phases:
				continue
		result.append(node)
	return result
