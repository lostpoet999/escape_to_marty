extends Node3D

## seconds for one fade-in or fade-out leg
@export var fade_time: float = 2.0
## seconds the door holds fully visible between fades
@export var visible_hold_time: float = 14.0
## seconds the door stays hidden before fading back in
@export var hidden_hold_time: float = 3.0
## spin speed in degrees per second around the vertical axis; direction is picked per door
@export var spin_speed_deg: float = 25.0
## vertical bob distance in local units
@export var bob_amplitude: float = 0.25
## seconds for one full bob cycle
@export var bob_period: float = 4.0

var _base_y: float
var _elapsed: float = 0.0
var _spin_direction: float = 1.0

@onready var _sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	_base_y = position.y
	_elapsed = randf() * bob_period
	_spin_direction = 1.0 if randf() < 0.5 else -1.0
	_sprite.modulate.a = 0.0
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_sprite, "modulate:a", 1.0, fade_time)
	tween.tween_interval(visible_hold_time)
	tween.tween_property(_sprite, "modulate:a", 0.0, fade_time)
	tween.tween_callback(_relocate)
	tween.tween_interval(hidden_hold_time)
	tween.custom_step(randf() * (fade_time * 2.0 + visible_hold_time + hidden_hold_time))

func _process(delta: float) -> void:
	_elapsed += delta
	position.y = _base_y + sin(_elapsed * TAU / bob_period) * bob_amplitude
	rotation_degrees.y += spin_speed_deg * _spin_direction * delta

func _relocate() -> void:
	var spawner: Node = get_parent()
	if spawner != null and spawner.has_method(&"place_item"):
		spawner.call(&"place_item", self)
	_base_y = position.y
