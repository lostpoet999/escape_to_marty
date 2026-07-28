class_name WallCrawl
extends EnemyActions

@export var crawl_min: float ## Lower bound along the wall axis in global coords (y for side walls, x for top).
@export var crawl_max: float ## Upper bound along the wall axis in global coords.
@export var min_step: float ## Smallest crawl distance per action.
@export var max_step: float ## Largest crawl distance per action.
@export var speed: float ## Seconds to travel to the picked target.
@export var clearance: float = 130.0 ## Minimum center-to-center distance kept from other walkers on the same wall; a blocked crawl reverses, or stands still if both ways are blocked.

var is_crawling: bool = false
var origin_position: Vector2
var origin_scale_cached: Vector2
var active_tweens: Array[Tween] = []
var squash_node: Node2D

func execute_action(actor: PlacedEnemy) -> void:
	if is_crawling:
		return
	var walker: WallWalker = actor as WallWalker
	if walker == null:
		return
	var axis_is_y: bool = walker.wall_side != WallWalker.WallSide.TOP
	var current: float = actor.global_position.y if axis_is_y else actor.global_position.x
	var step: float = randf_range(min_step, max_step)
	if randf() < 0.5:
		step = -step
	var target: float = _neighbor_limited_target(walker, axis_is_y, current, step)
	if absf(target - current) < 1.0:
		target = _neighbor_limited_target(walker, axis_is_y, current, -step)
	if absf(target - current) < 1.0:
		return

	is_crawling = true
	origin_position = actor.global_position
	active_tweens.clear()
	squash_node = actor.get_node_or_null("EnemySprite")
	var origin_scale: Vector2 = squash_node.scale if squash_node != null else Vector2.ONE
	origin_scale_cached = origin_scale

	var move_tween: Tween = actor.create_tween()
	if axis_is_y:
		move_tween.tween_property(actor, "global_position:y", target, speed)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	else:
		move_tween.tween_property(actor, "global_position:x", target, speed)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	move_tween.tween_callback(func() -> void: is_crawling = false)
	active_tweens.append(move_tween)

	if squash_node != null:
		var bob_tween: Tween = actor.create_tween()
		bob_tween.tween_property(squash_node, "scale",
			Vector2(origin_scale.x * 1.1, origin_scale.y * 0.9), speed * 0.25)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		bob_tween.tween_property(squash_node, "scale",
			origin_scale, speed * 0.75)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		active_tweens.append(bob_tween)

func _neighbor_limited_target(walker: WallWalker, axis_is_y: bool, current: float, step: float) -> float:
	var target: float = clampf(current + step, crawl_min, crawl_max)
	var dir: float = signf(target - current)
	if dir == 0.0:
		return current
	for other: Node in walker.get_tree().get_nodes_in_group(&"wall_walkers"):
		var o: WallWalker = other as WallWalker
		if o == null or o == walker or o.wall_side != walker.wall_side or o.is_queued_for_deletion():
			continue
		var o_pos: float = o.global_position.y if axis_is_y else o.global_position.x
		if dir > 0.0 and o_pos > current and o_pos - clearance < target:
			target = maxf(current, o_pos - clearance)
		elif dir < 0.0 and o_pos < current and o_pos + clearance > target:
			target = minf(current, o_pos + clearance)
	return target

func cancel_to_origin(actor: PlacedEnemy) -> void:
	if not is_crawling: return
	for t: Tween in active_tweens:
		if t != null and t.is_valid(): t.kill()
	active_tweens.clear()
	actor.global_position = origin_position
	if squash_node != null:
		squash_node.scale = origin_scale_cached
	is_crawling = false
