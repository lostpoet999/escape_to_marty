class_name LifeForceOrb extends Node2D

const BASE_BEAT_SECONDS: float = 1.125
const MAX_SPEED_RATIO: float = 2.5
const PULSE_SCALE: float = 0.2
const ALPHA_MIN: float = 0.5
const ALPHA_MAX: float = 1.0
const LUB_CENTER: float = 0.08
const DUB_CENTER: float = 0.3
const THUMP_WIDTH: float = 0.07
const DUB_STRENGTH: float = 0.6

@onready var _sprite: Sprite2D = $Sprite

var _phase: float = 0.0
var _ball: Ball

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta / _beat_period(), 1.0)
	var beat: float = _heartbeat(_phase)
	scale = Vector2.ONE * (1.0 + PULSE_SCALE * beat)
	_sprite.modulate.a = lerpf(ALPHA_MIN, ALPHA_MAX, beat)

func _beat_period() -> float:
	var ball: Ball = _get_ball()
	if ball == null or ball.initial_speed <= 0.0:
		return BASE_BEAT_SECONDS
	var ratio: float = clampf(ball.current_speed / ball.initial_speed, 1.0, MAX_SPEED_RATIO)
	return BASE_BEAT_SECONDS / ratio

func _get_ball() -> Ball:
	if _ball != null and is_instance_valid(_ball):
		return _ball
	_ball = get_tree().get_first_node_in_group(&"ball") as Ball
	return _ball

func _heartbeat(phase: float) -> float:
	var lub: float = _thump(phase, LUB_CENTER)
	var dub: float = _thump(phase, DUB_CENTER) * DUB_STRENGTH
	return clampf(lub + dub, 0.0, 1.0)

func _thump(phase: float, center: float) -> float:
	var d: float = absf(phase - center)
	if d > THUMP_WIDTH:
		return 0.0
	return 0.5 + 0.5 * cos(PI * d / THUMP_WIDTH)
