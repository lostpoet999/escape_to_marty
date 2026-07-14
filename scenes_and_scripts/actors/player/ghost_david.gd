extends Node2D

## Seconds per full idle-breath cycle on the ghost sprite.
@export var breathe_period: float = 3.2
## Fraction the sprite swells at the peak of a breath (0.03 = 3%).
@export var breathe_amount: float = 0.03

var _breathe_time: float = 0.0
var _base_scale: Vector2

@onready var _sprite: Sprite2D = $GhostSprite

func _ready() -> void:
	_base_scale = _sprite.scale

func _process(delta: float) -> void:
	_breathe_time += delta
	var breath: float = sin(_breathe_time * TAU / breathe_period) * breathe_amount
	_sprite.scale = _base_scale * Vector2(1.0 - breath * 0.5, 1.0 + breath)
