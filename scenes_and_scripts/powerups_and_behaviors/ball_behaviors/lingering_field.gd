class_name LingeringField extends Node2D

# persistent escape-hatch example: ticks damage over a lifetime, then frees itself.

@export var radius: float = 80.0
@export var lifetime: float = 2.0
@export var tick_interval: float = 0.4
@export var debug_color: Color = Color(1.0, 0.45, 0.1, 0.25)

var _amount: float = 1.0
var _types: Array = [GameManager.PhaseType.HEALTH]
var _age: float = 0.0
var _tick_accum: float = 0.0

func initialize(amount: float, types: Array) -> void:
	_amount = amount
	_types = types

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, debug_color)

func _process(delta: float) -> void:
	_age += delta
	_tick_accum += delta
	if _tick_accum >= tick_interval:
		_tick_accum = 0.0
		_tick()
	if _age >= lifetime:
		queue_free()

func _tick() -> void:
	for node: Node in get_tree().get_nodes_in_group("bricks"):
		var brick: Node2D = node as Node2D
		if brick != null and brick.global_position.distance_to(global_position) <= radius:
			if brick.has_method("accept_damage"):
				brick.accept_damage(_amount, _types)
