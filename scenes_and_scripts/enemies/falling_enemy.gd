class_name FallingEnemy
extends CharacterBody2D

var falling: bool = false
@export var gravity: float = 9.8
@export var fall_speed: float = 0
@export var can_damage: bool = true
@export var damage: float = 1.0
@export var fall_delay: float = 0.2
@export var stun_time: float = 1.0

func _ready() -> void:
	_pause_falling()

func _pause_falling() -> void:
	falling = false
	await get_tree().create_timer(0.5).timeout
	_start_falling()

func _start_falling() -> void:
	falling = true

func _physics_process(delta: float) -> void:
	if falling:
		fall_speed += gravity
	var velocity = Vector2(0, fall_speed)
	var collision = move_and_collide(velocity * delta)
	if (collision):
		var collider = collision.get_collider()
		if collider.is_in_group(GameManager.PADDLE):
			# stop insta-death from damaging every frame
			if collider.has_method("freeze_paddle_for_time"):
				collider.freeze_paddle_for_time(stun_time)
			if can_damage:
				PlayerData.accept_damage(damage)
				_pause_falling()
				can_damage = false
				queue_free()
