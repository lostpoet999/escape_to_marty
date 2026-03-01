class_name Paddle
extends CharacterBody2D

@export var paddle_influence: float = 5.0

var paddle_frozen: bool = false
var paddle_click_dmg: float = 1.0

# Screen bounds
var left_bound: float = 0.0
var right_bound: float = 0.0
var last_position: Vector2 = Vector2()
var current_speed: float = 0.0
const END_OF_UI: int = 280
const HALF_OF_PADDLE: int = 135 #half of sprite size

var accumulated_mouse_movement_x: float = 0
var mouse_sensitivity: float = 1.0

func _ready() -> void:
	#mouse mode is set by GameManager when entering PLAYING state
	var screen_size: Vector2 = get_viewport_rect().size # screen clamping
	left_bound = END_OF_UI + HALF_OF_PADDLE
	right_bound = screen_size.x - HALF_OF_PADDLE
	accumulated_mouse_movement_x = position.x
	Signalbus.game_state_click_mode.connect(_on_game_state_click_mode)
	Signalbus.game_state_playing.connect(_on_game_state_playing)
	
func _on_game_state_playing() -> void:
	paddle_frozen = false

func _on_game_state_click_mode() -> void:
	paddle_frozen = true

func _input(event: InputEvent) -> void:
	if !paddle_frozen:
		var mouse_event: InputEventMouseMotion = event as InputEventMouseMotion
		if mouse_event:
			accumulated_mouse_movement_x += mouse_event.relative.x * mouse_sensitivity
			accumulated_mouse_movement_x = clamp(accumulated_mouse_movement_x, left_bound, right_bound)

func get_movement_direction() -> float:
	return current_speed

func _physics_process(delta: float) -> void:
	if !paddle_frozen:
		position.x = accumulated_mouse_movement_x
		current_speed = (global_position.x - last_position.x) / delta
		last_position = global_position
	
