class_name DarknessDriver
extends Node

@export var dark_color: Color = Color(0.2, 0.2, 0.27)
@export var fade_time: float = 1.2

var _tween: Tween

func fade_dark() -> void:
	_fade_to(dark_color)

func fade_light() -> void:
	_fade_to(Color.WHITE)

func _fade_to(target: Color) -> void:
	var canvas: CanvasModulate = _canvas_modulate()
	if canvas == null:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(canvas, "color", target, fade_time)

func _canvas_modulate() -> CanvasModulate:
	return get_node_or_null(^"../../CanvasModulate") as CanvasModulate

func _exit_tree() -> void:
	if _tween != null:
		_tween.kill()
	var canvas: CanvasModulate = _canvas_modulate()
	if canvas != null:
		canvas.color = Color.WHITE
