class_name HitBehavior extends Resource

@export var targeting: TargetingStrategy
@export var trigger_groups: Array[StringName]
@export var types: Array[GameManager.PhaseType]
@export var local_multi: float = 1.0
@export var spawn_on_apply: PackedScene
@export var max_spawn: int = 0
@export var hit_vfx: PackedScene

## VFX played at the hit point, fitted to the targeting shape (e.g. a ShapeDrawVfx).
@export var vfx: VfxSpec

## When true, anchors the whole behavior (targeting, VFX, spawned objects) on the hit
## brick's center instead of the raw contact point.
@export var center_on_brick: bool = false

var _active_spawns: int = 0

func apply(ctx: HitContext, collider: Node2D) -> void:
	if targeting == null:
		return
	if not _triggered_by(collider):
		return
	# center_on_brick: anchor the whole behavior on the hit brick's center. collider is the
	# single brick this call handles (ball processes one collider per call), and a brick is an
	# Area2D centered at its origin, so collider.global_position IS its center. restore the hit
	# point afterward so the override doesn't leak into sibling behaviors sharing this ctx.
	var prev_hit_point: Vector2 = ctx.hit_point
	if center_on_brick and collider != null:
		ctx.hit_point = collider.global_position
	var targets: Array[Node2D] = targeting.select(ctx, collider)
	if not targets.is_empty():
		var effective_types: Array = types if not types.is_empty() else ctx.dmg_types
		var amount: float = ctx.base_damage * local_multi
		for target: Node2D in targets:
			ctx.apply.call(target, amount, effective_types)
		if vfx != null:
			var probe_shape: Shape2D = null
			if "probe_shape" in targeting:
				probe_shape = targeting.get("probe_shape")
			vfx.spawn_fitted(ctx.source.get_tree().current_scene, Transform2D(0, ctx.hit_point), probe_shape)
		if hit_vfx != null:
			_spawn(ctx, hit_vfx, amount, effective_types)
		if spawn_on_apply != null and (max_spawn <= 0 or _active_spawns < max_spawn):
			var spawned: Node2D = _spawn(ctx, spawn_on_apply, amount, effective_types)
			_active_spawns += 1
			spawned.tree_exited.connect(_on_spawn_freed)
	ctx.hit_point = prev_hit_point

func _triggered_by(collider: Node2D) -> bool:
	if trigger_groups.is_empty():
		return true
	for group: StringName in trigger_groups:
		if collider.is_in_group(group):
			return true
	return false

func _spawn(ctx: HitContext, scene: PackedScene, amount: float, types: Array) -> Node2D:
	var node: Node2D = scene.instantiate()
	node.position = ctx.hit_point
	ctx.source.get_tree().current_scene.add_child(node)
	if node.has_method("initialize"):
		node.call("initialize", amount, types)
	return node

func _on_spawn_freed() -> void:
	_active_spawns -= 1
