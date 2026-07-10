class_name MoneyThiefSpider
extends WallWalker

@export var steal_reach: float = 280.0 ## How far the steal pocket reaches off the wall into the playfield.
@export var steal_span: float = 400.0 ## How wide the steal pocket is along the wall.
@export var eat_radius: float = 45.0 ## Distance at which a pulled gold coin is consumed.

var hoard: int = 0
var _captured: Array[BonusDrop] = []
@onready var _steal_zone: Area2D = get_node_or_null("StealZone")

func _ready() -> void:
	super()
	_configure_steal_zone()

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
	hoard += (drop.payload as CurrencyPayload).value
	Signalbus.gold_collected.emit(-1)
	add_escape_time(escape_time * 0.2)
	drop.queue_free()
	_eat_pulse()

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
