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

var _active_spawns: int = 0

func apply(ball: Ball, collider: Node2D) -> void:
	if targeting == null:
		return
	if not _triggered_by(collider):
		return
	var hit_point: Vector2 = ball.global_position
	var targets: Array[Node2D] = targeting.select(ball, collider, hit_point)
	if targets.is_empty():
		return
	var effective_types: Array = types if not types.is_empty() else ball.ball_dmg_type
	var amount: float = ball.ball_dmg * local_multi
	for target: Node2D in targets:
		ball.apply_damage_to(target, amount, effective_types)
	if vfx != null:
		var probe_shape: Shape2D = null
		if "probe_shape" in targeting:
			probe_shape = targeting.get("probe_shape")
		vfx.spawn_fitted(ball.get_tree().current_scene, Transform2D(0, hit_point), probe_shape)
	if hit_vfx != null:
		_spawn(ball, hit_vfx, amount, effective_types)
	if spawn_on_apply != null and (max_spawn <= 0 or _active_spawns < max_spawn):
		var spawned: Node2D = _spawn(ball, spawn_on_apply, amount, effective_types)
		_active_spawns += 1
		spawned.tree_exited.connect(_on_spawn_freed)

func _triggered_by(collider: Node2D) -> bool:
	if trigger_groups.is_empty():
		return true
	for group: StringName in trigger_groups:
		if collider.is_in_group(group):
			return true
	return false

func _spawn(ball: Ball, scene: PackedScene, amount: float, types: Array) -> Node2D:
	var node: Node2D = scene.instantiate()
	node.position = ball.global_position
	ball.get_tree().current_scene.add_child(node)
	if node.has_method("initialize"):
		node.call("initialize", amount, types)
	return node

func _on_spawn_freed() -> void:
	_active_spawns -= 1
