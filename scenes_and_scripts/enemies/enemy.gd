class_name Enemy
extends CharacterBody2D

var falling = false
var gravity = 9.8
var fall_speed = 0
var can_damage = true

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
			if can_damage:
				PlayerData.accept_damage(1)
				_pause_falling()
				can_damage = false
