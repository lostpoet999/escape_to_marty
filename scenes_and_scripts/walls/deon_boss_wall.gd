extends Area2D
var _pulse_tween: Tween

func _ready() -> void:
	modulate = Color.BLACK
	start_black_pulse(.5)

func start_black_pulse(duration: float = 1.0) -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(self, "modulate", Color(0.25, 0.25, 0.25, 1.0), duration)
	_pulse_tween.tween_property(self, "modulate", Color.BLACK, duration)


func stop_black_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	modulate = Color.WHITE
