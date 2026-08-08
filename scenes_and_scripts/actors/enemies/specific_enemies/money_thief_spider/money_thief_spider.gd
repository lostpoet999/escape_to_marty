class_name MoneyThiefSpider
extends WallWalker

const BONUS_DROP: PackedScene = preload("res://scenes_and_scripts/collectibles/bonus_drop.tscn")
const WALL_HALF_WIDTH: float = 32.0

@export var steal_reach: float = 420.0 ## How far the steal pocket reaches off the wall into the playfield.
@export var steal_span: float = 400.0 ## How wide the steal pocket is along the wall.
@export var eat_radius: float = 45.0 ## Distance at which a pulled gold coin is consumed.
@export var burst_scatter_min: float = 40.0 ## Closest a burst drop lands from the spider, into the playfield.
@export var burst_scatter_max: float = 120.0 ## Farthest a burst drop lands from the spider, into the playfield.
@export var exposed_fraction: float = 0.5 ## Fraction of the sprite hanging past the wall's inner face into the play area; the rest overlaps the wall.

var hoard: Array[BonusPayload] = []
var _captured: Array[BonusDrop] = []
@onready var _steal_zone: Area2D = get_node_or_null("StealZone")

func _ready() -> void:
	_apply_wall_pose()
	super()
	_configure_steal_zone()

func _apply_wall_pose() -> void:
	var sprite: Sprite2D = get_node_or_null("EnemySprite")
	if sprite == null:
		return
	match wall_side:
		WallSide.LEFT: sprite.rotation = -PI / 2
		WallSide.RIGHT: sprite.rotation = PI / 2
		_: sprite.rotation = 0.0
	if sprite.texture == null:
		return
	var walls: Array = get_tree().get_nodes_in_group("walls")
	if walls.is_empty():
		return
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	for wall: Area2D in walls:
		min_x = minf(min_x, wall.global_position.x)
		max_x = maxf(max_x, wall.global_position.x)
		min_y = minf(min_y, wall.global_position.y)
	var depth: float = (0.5 - exposed_fraction) * sprite.texture.get_height() * sprite.scale.y
	match wall_side:
		WallSide.LEFT:
			global_position.x = min_x + WALL_HALF_WIDTH - depth
		WallSide.RIGHT:
			global_position.x = max_x - WALL_HALF_WIDTH + depth
		_:
			global_position.y = min_y + WALL_HALF_WIDTH - depth

func _configure_steal_zone() -> void:
	if _steal_zone == null:
		return
	_steal_zone.area_entered.connect(_on_steal_zone_area_entered)
	var shape_node: CollisionShape2D = _steal_zone.get_node_or_null("StealCollision")
	if shape_node == null:
		return
	var rect: RectangleShape2D = RectangleShape2D.new()
	if wall_side == WallSide.TOP:
		rect.size = Vector2(steal_span, steal_reach)
		shape_node.position = Vector2(0.0, steal_reach * 0.5)
	else:
		rect.size = Vector2(steal_reach, steal_span)
		var dir: float = 1.0 if wall_side == WallSide.LEFT else -1.0
		shape_node.position = Vector2(dir * steal_reach * 0.5, 0.0)
	shape_node.shape = rect

func _physics_process(_delta: float) -> void:
	if _escaping or _captured.is_empty():
		return
	var still_held: Array[BonusDrop] = []
	for drop: BonusDrop in _captured:
		if not is_instance_valid(drop) or drop.collected:
			continue
		if global_position.distance_to(drop.global_position) <= eat_radius:
			_eat(drop)
		else:
			still_held.append(drop)
	_captured = still_held

func _on_steal_zone_area_entered(area: Area2D) -> void:
	if _escaping:
		return
	var drop: BonusDrop = area as BonusDrop
	if drop == null or drop.collected or drop.captor != null or not (drop.payload is CurrencyPayload):
		return
	drop.captor = self
	_captured.append(drop)

func _eat(drop: BonusDrop) -> void:
	drop.collected = true
	hoard.append(drop.payload)
	Signalbus.gold_collected.emit(-1)
	add_escape_time(escape_time * 0.2)
	drop.queue_free()
	_eat_pulse()

func _on_death(killed_by_damage: bool) -> void:
	if not killed_by_damage:
		return
	for payload: BonusPayload in hoard:
		var drop: BonusDrop = BONUS_DROP.instantiate()
		drop.payload = payload
		get_parent().add_child(drop)
		drop.global_position = global_position + _scatter_offset()
		Signalbus.gold_spawned.emit(1)
	hoard.clear()

func holds_player_gold() -> bool:
	return not hoard.is_empty()

func _scatter_offset() -> Vector2:
	var inward: Vector2
	match wall_side:
		WallSide.TOP: inward = Vector2.DOWN
		WallSide.LEFT: inward = Vector2.RIGHT
		_: inward = Vector2.LEFT
	var along: Vector2 = inward.orthogonal()
	return inward * randf_range(burst_scatter_min, burst_scatter_max) + along * randf_range(-60.0, 60.0)

func _eat_pulse() -> void:
	var sprite: Node2D = get_node_or_null("EnemySprite")
	if sprite == null:
		return
	var pulse: Tween = create_tween()
	pulse.tween_property(sprite, "modulate", Color(1.6, 1.6, 1.6, 1.0), 0.06)
	pulse.tween_property(sprite, "modulate", Color.WHITE, 0.12)

func _on_escape_started() -> void:
	if _steal_zone != null:
		_steal_zone.set_deferred("monitoring", false)
	for drop: BonusDrop in _captured:
		if is_instance_valid(drop):
			drop.captor = null
	_captured.clear()
