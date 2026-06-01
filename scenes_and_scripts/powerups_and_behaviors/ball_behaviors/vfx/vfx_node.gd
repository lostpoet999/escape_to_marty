class_name VfxNode extends Node2D

@export var lifetime: float = 0.3

var _age: float = 0.0

func _process(delta: float) -> void:
	_age += delta
	_animate(clampf(_age / lifetime, 0.0, 1.0), delta)
	if _age >= lifetime:
		queue_free()

func _animate(_progress: float, _delta: float) -> void:
	pass
