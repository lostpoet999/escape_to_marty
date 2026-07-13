class_name TileShake

const DIRECT_HIT_SCALE: float = 0.5
const JITTER_RANGE: float = 5.0
const JITTER_COUNT: int = 3
const JITTER_TIME: float = 0.05
const SETTLE_TIME: float = 0.06

static func shake(tile: Node2D, delay: float = 0.0, duration_scale: float = 1.0) -> void:
	var jitters: Array[Vector2] = []
	for _i: int in JITTER_COUNT:
		jitters.append(Vector2(randf_range(-JITTER_RANGE, JITTER_RANGE), randf_range(-JITTER_RANGE, JITTER_RANGE)))
	for child: Node in tile.find_children("*", "", true, false):
		if not (child is TextureRect or child is Sprite2D):
			continue
		var origin: Vector2
		var active: Tween = null
		if child.has_meta(&"wall_shock_tween"):
			active = child.get_meta(&"wall_shock_tween")
		if active != null and active.is_valid() and active.is_running():
			active.kill()
			origin = child.get_meta(&"wall_shock_origin")
		else:
			origin = child.get("position")
			child.set_meta(&"wall_shock_origin", origin)
		var shake_tween: Tween = tile.create_tween()
		if delay > 0.0:
			shake_tween.tween_interval(delay)
		for jitter: Vector2 in jitters:
			shake_tween.tween_property(child, "position", origin + jitter, JITTER_TIME * duration_scale)
		shake_tween.tween_property(child, "position", origin, SETTLE_TIME * duration_scale)
		child.set_meta(&"wall_shock_tween", shake_tween)
