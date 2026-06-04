class_name TargetingStrategy extends Resource

# base: who a hit affects. override select(); default no-op.
func select(_ctx: HitContext, _collider: Node2D) -> Array[Node2D]:
	return []
