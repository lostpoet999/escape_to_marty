extends Node2D

@export var rise_target_y: float = -160.0   
@export var rise_duration: float = 1.6      
@export var sway_amplitude: float = 26.0    
@export var sway_frequency: float = 3.2     
@export var fade_delay: float = 0.35        
@export var stretch_scale_y: float = 2.4    # vertical elongation as it whisps up
@export var stretch_scale_x: float = 0.55   # horizontal squeeze for a thin wisp

var _base_x: float = NAN
var _elapsed: float = 0.0


func _ready() -> void:
	z_index = 100  # above bricks/background (max is 4096)

	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position:y", rise_target_y, rise_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2(stretch_scale_x, stretch_scale_y), rise_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, rise_duration - fade_delay) \
		.set_delay(fade_delay)
	tween.connect("finished", Callable(self, "queue_free"))


func _process(delta: float) -> void:
	if is_nan(_base_x):
		_base_x = global_position.x  
	_elapsed += delta
	global_position.x = _base_x + sin(_elapsed * sway_frequency) * sway_amplitude
