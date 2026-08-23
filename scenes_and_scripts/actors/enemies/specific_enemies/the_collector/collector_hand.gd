extends Sprite2D

@export var idle_fps: float = 6.0
@export var mirrored: bool = false
@export var bob_wait_min: float = 2.5
@export var bob_wait_max: float = 7.0
@export var bob_pixels: float = 8.0
@export var bob_time: float = 0.8
@export var twist_wait_min: float = 4.0
@export var twist_wait_max: float = 9.0
@export var twist_degrees: float = 12.0
@export var twist_time: float = 1.0

var _idle_time: float = 0.0
var _rest_y: float = 0.0
var _rest_rotation: float = 0.0
var _bob_wait: float = 0.0
var _twist_wait: float = 0.0
var _bob_tween: Tween
var _twist_tween: Tween

func _ready() -> void:
	flip_h = mirrored
	_rest_y = position.y
	_rest_rotation = rotation
	_bob_wait = randf_range(bob_wait_min, bob_wait_max)
	_twist_wait = randf_range(twist_wait_min, twist_wait_max)

func _process(delta: float) -> void:
	_idle_time += delta * idle_fps
	var step: int = int(_idle_time) % hframes
	frame = (hframes - 1 - step) if mirrored else step
	_bob_wait -= delta
	if _bob_wait <= 0.0:
		_bob_wait = randf_range(bob_wait_min, bob_wait_max)
		_start_bob()
	_twist_wait -= delta
	if _twist_wait <= 0.0:
		_twist_wait = randf_range(twist_wait_min, twist_wait_max)
		_start_twist()

func _start_bob() -> void:
	if _bob_tween != null and _bob_tween.is_running():
		return
	_bob_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(self, "position:y", _rest_y - bob_pixels, bob_time * 0.5)
	_bob_tween.tween_property(self, "position:y", _rest_y, bob_time * 0.5)

func _start_twist() -> void:
	if _twist_tween != null and _twist_tween.is_running():
		return
	var direction: float = -1.0 if mirrored else 1.0
	var target: float = _rest_rotation + deg_to_rad(twist_degrees) * direction
	_twist_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_twist_tween.tween_property(self, "rotation", target, twist_time * 0.5)
	_twist_tween.tween_property(self, "rotation", _rest_rotation, twist_time * 0.5)
