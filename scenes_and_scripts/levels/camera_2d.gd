extends Camera2D

var shake: float = 0.0
var decay_rate: float = 1.5
var max_offset: float = 8.0

func _process(delta: float) -> void:
	shake = max(0.0, shake - decay_rate * delta)
	var intensity: float = shake * shake
	offset = Vector2(
		randf_range(-max_offset, max_offset) * intensity,
		randf_range(-max_offset, max_offset) * intensity
	)

func add_trauma(amount: float) -> void:
	shake = min(1.0, shake + amount)
