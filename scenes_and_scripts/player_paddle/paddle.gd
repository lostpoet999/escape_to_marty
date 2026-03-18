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

var accumulated_mouse_movement_x: float = 0
var mouse_sensitivity: float = 1.0

@export var active_paddle_powerup: PaddleActive #will type cast later
@onready var projectiles: Node = $"../Projectiles"


func _ready() -> void:
	#mouse mode is set by GameManager when entering PLAYING state
	_calculate_bounds()
	accumulated_mouse_movement_x = position.x
	Signalbus.game_state_click_mode.connect(_on_game_state_click_mode)
	Signalbus.game_state_playing.connect(_on_game_state_playing)
	Signalbus.paddle_active_assigned.connect(_assign_active_powerup)
	Signalbus.paddle_swap_resolved.connect(_assign_active_powerup)
	active_paddle_powerup = PlayerData.inventory.get_paddle_active()

func _calculate_bounds() -> void:
	var half_width: float = _get_scaled_half_width()
	var walls: Array = get_tree().get_nodes_in_group("walls")
	var min_x: float = INF
	var max_x: float = -INF
	for wall: Area2D in walls:
		min_x = minf(min_x, wall.global_position.x)
		max_x = maxf(max_x, wall.global_position.x)
	# Offset by wall collision half-size (32) to get inner edges
	left_bound = min_x + 32.0 + half_width
	right_bound = max_x - 32.0 - half_width

func _assign_active_powerup(item: PaddleActive)->void:
	active_paddle_powerup = item
	

func _get_scaled_half_width() -> float:
	var sprite: Sprite2D = $PaddleSprite
	var texture_width: float = sprite.texture.get_width()
	return (texture_width * sprite.scale.x * scale.x) / 2.0
	
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
	if Input.is_action_just_pressed("paddle_active_powerup") and GameManager.current_state != GameManager.GameState.BALL_ON_PADDLE and GameManager.current_state != GameManager.GameState.LEVEL_CLEARED:		
		print("at button push: ", active_paddle_powerup)
		if active_paddle_powerup:
			active_paddle_powerup.activate(self,projectiles)

func get_movement_direction() -> float:
	return current_speed

func _physics_process(delta: float) -> void:
	if !paddle_frozen:
		position.x = accumulated_mouse_movement_x
		current_speed = (global_position.x - last_position.x) / delta
		last_position = global_position
	
