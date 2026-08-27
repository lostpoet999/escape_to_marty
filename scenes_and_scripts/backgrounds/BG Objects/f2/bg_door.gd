extends Node3D

const PHASE_TINTS: Array[Color] = [
	Color("a23e8c"),
	Color("a53030"),
	Color("de9e41"),
	Color("394a50"),
	Color("75a743"),
]

## seconds for the fade-in leg
@export var fade_time: float = 2.0
## seconds the door holds fully visible before freezing and dropping
@export var visible_hold_time: float = 14.0
## seconds the drop takes to leave the screen
@export var drop_time: float = 1.2
## world units the door falls before freeing; sized to clear the frustum at max depth
@export var drop_distance: float = 40.0
## spin speed in degrees per second around the vertical axis; direction is picked per door
@export var spin_speed_deg: float = 25.0
## vertical bob distance in local units
@export var bob_amplitude: float = 0.25
## seconds for one full bob cycle
@export var bob_period: float = 4.0

var _base_y: float
var _elapsed: float = 0.0
var _spin_direction: float = 1.0
var _frozen: bool = false

@onready var _sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	_base_y = position.y
	_elapsed = randf() * bob_period
	_spin_direction = 1.0 if randf() < 0.5 else -1.0
	var tint: Color = PHASE_TINTS[randi() % PHASE_TINTS.size()]
	_sprite.modulate = Color(tint.r, tint.g, tint.b, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate:a", 1.0, fade_time)
	tween.tween_interval(visible_hold_time)
	tween.tween_callback(_freeze)
	tween.tween_property(self, "position:y", _base_y - drop_distance, drop_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	if _frozen:
		return
	_elapsed += delta
	position.y = _base_y + sin(_elapsed * TAU / bob_period) * bob_amplitude
	rotation_degrees.y += spin_speed_deg * _spin_direction * delta

func _freeze() -> void:
	_frozen = true
