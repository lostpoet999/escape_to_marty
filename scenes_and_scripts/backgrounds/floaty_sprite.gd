extends Sprite2D

@export var bob_amplitude: float = 2.4
@export var bob_period: float = 3.0

var _base_y: float
var _elapsed: float = 0.0

func _ready() -> void:
	_base_y = position.y
	_elapsed = randf() * bob_period

func _process(delta: float) -> void:
	_elapsed += delta
	position.y = _base_y + sin(_elapsed * TAU / bob_period) * bob_amplitude
