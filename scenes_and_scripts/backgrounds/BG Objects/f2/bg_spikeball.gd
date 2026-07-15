extends Node3D

## min/max seconds to wait invisible before zooming in, so balls never move in sync
@export var start_delay_range: Vector2 = Vector2(0.0, 3.0)
## seconds to zoom from spawn size to full size
@export var zoom_time: float = 1.2
## min/max seconds the ball sits still after zooming in, before the shake starts
@export var idle_time_range: Vector2 = Vector2(1.5, 4.0)
## min/max seconds of shaking before the explosion; amplitude ramps over the whole window
@export var shake_time_range: Vector2 = Vector2(3.0, 6.0)
## strongest shake offset in local units, reached at the end of the ramp
@export var shake_amplitude: float = 0.18
## seconds the explosion frame is shown before the burst spawns
@export var explode_frame_time: float = 0.15
## one-shot particle burst spawned when the ball explodes
@export var destroy_fx: PackedScene = preload("res://scenes_and_scripts/backgrounds/BG Objects/f2/bg_destroy_fx.tscn")
## body color passed to the destroy fx sparks and shards
@export var fx_body_color: Color = Color(0.92156863, 0.92941177, 0.9137255)

var _full_scale: Vector3
var _base_position: Vector3
var _shake_time: float
var _shake_elapsed: float = 0.0
var _shaking: bool = false

@onready var _sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	_full_scale = scale
	scale = _full_scale * 0.05
	_sprite.visible = false
	var tween: Tween = create_tween()
	tween.tween_interval(randf_range(start_delay_range.x, start_delay_range.y))
	tween.tween_callback(_begin_zoom)
	tween.tween_property(self, "scale", _full_scale, zoom_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(randf_range(idle_time_range.x, idle_time_range.y))
	tween.tween_callback(_start_shaking)

func _process(delta: float) -> void:
	if not _shaking:
		return
	_shake_elapsed += delta
	var ramp: float = _shake_elapsed / _shake_time
	if ramp >= 1.0:
		_shaking = false
		position = _base_position
		_explode()
		return
	var amplitude: float = shake_amplitude * ramp * ramp
	position = _base_position + Vector3(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude), 0.0)

func _begin_zoom() -> void:
	_sprite.visible = true

func _start_shaking() -> void:
	_base_position = position
	_shake_time = randf_range(shake_time_range.x, shake_time_range.y)
	_shaking = true

func _explode() -> void:
	_sprite.frame = 1
	var tween: Tween = create_tween()
	tween.tween_interval(explode_frame_time)
	tween.tween_callback(_spawn_destroy_fx)
	tween.tween_callback(queue_free)

func _spawn_destroy_fx() -> void:
	if destroy_fx == null:
		return
	var fx: Node3D = destroy_fx.instantiate() as Node3D
	if fx == null:
		return
	fx.position = position
	fx.scale = scale * 0.8
	fx.set(&"body_color", fx_body_color)
	get_parent().add_child(fx)
